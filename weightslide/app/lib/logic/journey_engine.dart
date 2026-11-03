import '../logic/crossing_detector.dart';
import '../logic/reference_lines.dart';
import '../logic/validation.dart';
import '../logic/weight_series.dart';
import '../models/local_date.dart';
import '../models/records.dart';
import '../persistence/journey_repository.dart';

class JourneyEngine {
  JourneyEngine({required this.repository, required this.clock, IdSource? ids})
    : _ids = ids ?? IdSource();

  final JourneyRepository repository;
  final DateTime Function() clock;
  final IdSource _ids;

  LocalDate get today => LocalDate.fromDateTime(clock());

  Future<Journey> createJourney({
    required double startingWeightKg,
    required LocalDate startDate,
    required double weeklyTargetKg,
  }) async {
    final weightError = validateWeight(startingWeightKg);
    if (weightError != null) {
      throw WeightSlideException(weightError);
    }
    final targetError = validateWeeklyTarget(weeklyTargetKg);
    if (targetError != null) {
      throw WeightSlideException(targetError);
    }
    if (startDate > today) {
      throw WeightSlideException('Start date cannot be after today.');
    }

    final current = await repository.activeJourney();
    if (current != null) {
      final caughtUp = await _evaluate(current.id);
      await repository.saveJourney(caughtUp.copyWith(isActive: false));
    }

    final journey = Journey(
      id: _ids.next('journey'),
      startDate: startDate,
      startingWeightKg: startingWeightKg,
      weeklyTargetKg: weeklyTargetKg,
      activeLevel: 3,
      isActive: true,
      createdAt: clock(),
      baseline: CrossingDetector.initialSnapshot(
        date: startDate,
        startingWeightKg: startingWeightKg,
        weeklyTargetKg: weeklyTargetKg,
      ),
    );
    await repository.insertJourney(journey);
    return _evaluate(journey.id);
  }

  /// Records [kilograms] for the clock's local today.
  Future<Journey> addReading(double kilograms) {
    return addReadingOnDate(today, kilograms);
  }

  /// Rejects any date other than the clock's local today.
  Future<Journey> addReadingOnDate(LocalDate date, double kilograms) async {
    if (date != today) {
      throw WeightSlideException('Weight can only be entered for today.');
    }
    final weightError = validateWeight(kilograms);
    if (weightError != null) {
      throw WeightSlideException(weightError);
    }
    final journey = await _requireActive();
    if (date < journey.startDate) {
      throw WeightSlideException('Weight can only be entered for today.');
    }
    await repository.insertReading(
      WeightReading(
        id: _ids.next('reading'),
        journeyId: journey.id,
        date: date,
        kg: kilograms,
        recordedAt: clock(),
      ),
    );
    return _evaluate(journey.id);
  }

  /// Removes one of today's readings and rebuilds the journey from the rest.
  Future<Journey> removeReading(String readingId) async {
    final journey = await _requireActive();
    final readings = await repository.readingsFor(journey.id);
    WeightReading? match;
    for (final reading in readings) {
      if (reading.id == readingId) {
        match = reading;
        break;
      }
    }
    if (match == null) {
      throw WeightSlideException('That reading was not found.');
    }
    if (match.date != today) {
      throw WeightSlideException("Only today's readings can be removed.");
    }
    await repository.deleteReading(readingId);
    final remaining = await repository.readingsFor(journey.id);
    final series = WeightSeries.build(
      start: journey.startDate,
      through: today,
      startingWeightKg: journey.startingWeightKg,
      readings: remaining,
    );
    return _replaceWithReplay(journey, remaining, series);
  }

  Future<void> catchUp() async {
    final active = await repository.activeJourney();
    if (active == null) {
      return;
    }
    await _evaluate(active.id);
  }

  Future<Journey> updateWeeklyTarget(double weeklyTargetKg) async {
    final targetError = validateWeeklyTarget(weeklyTargetKg);
    if (targetError != null) {
      throw WeightSlideException(targetError);
    }
    final active = await _requireActive();
    final caughtUp = await _evaluate(active.id);
    final readings = await repository.readingsFor(caughtUp.id);
    final series = WeightSeries.build(
      start: caughtUp.startDate,
      through: today,
      startingWeightKg: caughtUp.startingWeightKg,
      readings: readings,
    );
    final point = _lastCommittedPoint(series);
    final lines = referenceLines(
      startingWeightKg: caughtUp.startingWeightKg,
      weeklyTargetKg: weeklyTargetKg,
      dayIndex: point.dayIndex,
    );
    final distances = [for (final line in lines) point.movingAverageKg - line];
    final reset = caughtUp.copyWith(
      weeklyTargetKg: weeklyTargetKg,
      baseline: TrendSnapshot(
        date: point.date,
        officialKg: point.officialKg,
        movingAverageKg: point.movingAverageKg,
        signedDistances: distances,
        activeLevel: caughtUp.activeLevel,
        lastNonZeroSides: CrossingDetector.sidesFromDistances(distances),
      ),
    );
    await repository.saveJourney(reset);
    return reset;
  }

  Future<void> updateRules(List<String> rules) async {
    if (rules.length != defaultRuleCount) {
      throw WeightSlideException('Five rules are required.');
    }
    final trimmed = <String>[];
    for (final rule in rules) {
      final text = rule.trim();
      if (text.isEmpty) {
        throw WeightSlideException('Rule text cannot be empty.');
      }
      trimmed.add(text);
    }
    await repository.saveRules(trimmed);
  }

  Future<Journey> _requireActive() async {
    final journey = await repository.activeJourney();
    if (journey == null) {
      throw WeightSlideException('Set up a journey first.');
    }
    return journey;
  }

  /// Point today's saved trend at the current average window and keep the
  /// active level. The window change itself is not a crossing.
  Future<Journey> _rebaseAverageWindow(
    Journey journey,
    List<WeightReading> readings,
  ) async {
    final series = WeightSeries.build(
      start: journey.startDate,
      through: today,
      startingWeightKg: journey.startingWeightKg,
      readings: readings,
    );
    final point = _lastCommittedPoint(series);
    final lines = referenceLines(
      startingWeightKg: journey.startingWeightKg,
      weeklyTargetKg: journey.weeklyTargetKg,
      dayIndex: point.dayIndex,
    );
    final distances = [for (final line in lines) point.movingAverageKg - line];
    final reset = journey.copyWith(
      baseline: TrendSnapshot(
        date: point.date,
        officialKg: point.officialKg,
        movingAverageKg: point.movingAverageKg,
        signedDistances: distances,
        activeLevel: journey.activeLevel,
        lastNonZeroSides: CrossingDetector.sidesFromDistances(distances),
        averageWindowDays: WeightSeries.windowDays,
      ),
    );
    await repository.saveJourney(reset);
    return reset;
  }

  Future<Journey> _evaluate(String journeyId) async {
    var journey = await repository.getJourney(journeyId);
    if (today < journey.startDate) {
      return journey;
    }
    final readings = await repository.readingsFor(journeyId);
    if (journey.baseline.averageWindowDays != WeightSeries.windowDays) {
      journey = await _rebaseAverageWindow(journey, readings);
    }
    final existing = await repository.crossingsFor(journeyId);
    final series = WeightSeries.build(
      start: journey.startDate,
      through: today,
      startingWeightKg: journey.startingWeightKg,
      readings: readings,
    );
    if (_placeholderWasCommitted(
      journey: journey,
      series: series,
      readings: readings,
      crossings: existing,
    )) {
      return _replaceWithReplay(journey, readings, series);
    }

    var sequence = existing.isEmpty ? 1 : existing.last.sequence + 1;
    var snapshot = journey.baseline;
    final newEvents = <CrossingEvent>[];
    for (final point in series) {
      if (point.date < snapshot.date) {
        continue;
      }
      if (_isOpenToday(point)) {
        continue;
      }
      if (point.date == snapshot.date &&
          (point.officialKg - snapshot.officialKg).abs() <=
              CrossingDetector.tolerance) {
        continue;
      }
      final taken = _takeStep(
        journey: journey,
        snapshot: snapshot,
        date: point.date,
        officialKg: point.officialKg,
        movingAverageKg: point.movingAverageKg,
        dayIndex: point.dayIndex,
        events: newEvents,
        sequence: sequence,
      );
      snapshot = taken.snapshot;
      sequence = taken.sequence;
    }

    final updated = journey.copyWith(
      activeLevel: snapshot.activeLevel,
      baseline: snapshot,
    );
    await repository.saveJourney(updated, newCrossings: newEvents);
    return updated;
  }

  /// The last day whose official weight is final. Today stays open until it
  /// has a reading or the calendar day has ended.
  DailyPoint _lastCommittedPoint(List<DailyPoint> series) {
    final last = series.last;
    if (_isOpenToday(last) && series.length > 1) {
      return series[series.length - 2];
    }
    return last;
  }

  bool _isOpenToday(DailyPoint point) {
    return point.date == today && !point.measured;
  }

  bool _placeholderWasCommitted({
    required Journey journey,
    required List<DailyPoint> series,
    required List<WeightReading> readings,
    required List<CrossingEvent> crossings,
  }) {
    final todayPoint = series.last;
    if (_isOpenToday(todayPoint) &&
        today > journey.startDate &&
        journey.baseline.date == today) {
      return true;
    }
    final byDate = {for (final point in series) point.date: point};
    for (final event in crossings) {
      final point = byDate[event.evaluationDate];
      if (point == null || !point.measured || point.dayIndex == 0) {
        continue;
      }
      final carried = series[point.dayIndex - 1].officialKg;
      final carryAverage = _averageEnding(
        series: series,
        dayIndex: point.dayIndex,
        officialKg: carried,
        startingWeightKg: journey.startingWeightKg,
      );
      if ((event.movingAverageKg - carryAverage).abs() >
          CrossingDetector.tolerance) {
        continue;
      }
      if ((carryAverage - point.movingAverageKg).abs() <=
          CrossingDetector.tolerance) {
        continue;
      }
      if (_readingProducesAverage(
        readings: readings,
        series: series,
        point: point,
        averageKg: carryAverage,
        startingWeightKg: journey.startingWeightKg,
      )) {
        continue;
      }
      return true;
    }
    return false;
  }

  bool _readingProducesAverage({
    required List<WeightReading> readings,
    required List<DailyPoint> series,
    required DailyPoint point,
    required double averageKg,
    required double startingWeightKg,
  }) {
    double? lowest;
    for (final reading in readings) {
      if (reading.date != point.date) {
        continue;
      }
      if (lowest != null && reading.kg >= lowest - CrossingDetector.tolerance) {
        continue;
      }
      lowest = reading.kg;
      final average = _averageEnding(
        series: series,
        dayIndex: point.dayIndex,
        officialKg: lowest,
        startingWeightKg: startingWeightKg,
      );
      if ((average - averageKg).abs() <= CrossingDetector.tolerance) {
        return true;
      }
    }
    return false;
  }

  Future<Journey> _replaceWithReplay(
    Journey journey,
    List<WeightReading> readings,
    List<DailyPoint> series,
  ) async {
    final replay = _replay(
      journey: journey,
      readings: readings,
      series: series,
    );
    final updated = journey.copyWith(
      activeLevel: replay.snapshot.activeLevel,
      baseline: replay.snapshot,
    );
    await repository.saveJourney(
      updated,
      newCrossings: replay.events,
      replaceCrossings: true,
    );
    return updated;
  }

  /// Rebuilds crossings from each finished day's official weight. A day with
  /// readings steps through each new minimum and skips the carried weight.
  _Replay _replay({
    required Journey journey,
    required List<WeightReading> readings,
    required List<DailyPoint> series,
  }) {
    var snapshot = CrossingDetector.initialSnapshot(
      date: journey.startDate,
      startingWeightKg: journey.startingWeightKg,
      weeklyTargetKg: journey.weeklyTargetKg,
    );
    final events = <CrossingEvent>[];
    var sequence = 1;
    for (final point in series) {
      if (_isOpenToday(point)) {
        break;
      }
      final dayReadings = [
        for (final reading in readings)
          if (reading.date == point.date) reading,
      ];
      if (dayReadings.isEmpty) {
        final taken = _takeStep(
          journey: journey,
          snapshot: snapshot,
          date: point.date,
          officialKg: point.officialKg,
          movingAverageKg: point.movingAverageKg,
          dayIndex: point.dayIndex,
          events: events,
          sequence: sequence,
        );
        snapshot = taken.snapshot;
        sequence = taken.sequence;
        continue;
      }
      double? lowest;
      for (final reading in dayReadings) {
        if (lowest != null &&
            reading.kg >= lowest - CrossingDetector.tolerance) {
          continue;
        }
        lowest = reading.kg;
        final taken = _takeStep(
          journey: journey,
          snapshot: snapshot,
          date: point.date,
          officialKg: lowest,
          movingAverageKg: _averageEnding(
            series: series,
            dayIndex: point.dayIndex,
            officialKg: lowest,
            startingWeightKg: journey.startingWeightKg,
          ),
          dayIndex: point.dayIndex,
          events: events,
          sequence: sequence,
        );
        snapshot = taken.snapshot;
        sequence = taken.sequence;
      }
    }
    return _Replay(snapshot: snapshot, events: events);
  }

  ({TrendSnapshot snapshot, int sequence}) _takeStep({
    required Journey journey,
    required TrendSnapshot snapshot,
    required LocalDate date,
    required double officialKg,
    required double movingAverageKg,
    required int dayIndex,
    required List<CrossingEvent> events,
    required int sequence,
  }) {
    if (date == snapshot.date &&
        (officialKg - snapshot.officialKg).abs() <=
            CrossingDetector.tolerance) {
      return (snapshot: snapshot, sequence: sequence);
    }
    final step = CrossingDetector.step(
      from: snapshot,
      date: date,
      officialKg: officialKg,
      movingAverageKg: movingAverageKg,
      startingWeightKg: journey.startingWeightKg,
      weeklyTargetKg: journey.weeklyTargetKg,
      dayIndex: dayIndex,
    );
    final evaluatedAt = clock();
    var nextSequence = sequence;
    for (final draft in step.crossings) {
      events.add(
        CrossingEvent(
          id: _ids.next('crossing'),
          journeyId: journey.id,
          lineNumber: draft.lineNumber,
          direction: draft.direction,
          evaluatedAt: evaluatedAt,
          evaluationDate: date,
          movingAverageKg: draft.movingAverageKg,
          lineValueKg: draft.lineValueKg,
          resultingLevel: draft.resultingLevel,
          sequence: nextSequence,
        ),
      );
      nextSequence += 1;
    }
    return (snapshot: step.snapshot, sequence: nextSequence);
  }
}

class _Replay {
  const _Replay({required this.snapshot, required this.events});

  final TrendSnapshot snapshot;
  final List<CrossingEvent> events;
}

double _averageEnding({
  required List<DailyPoint> series,
  required int dayIndex,
  required double officialKg,
  required double startingWeightKg,
}) {
  var sum = 0.0;
  for (var age = 0; age < WeightSeries.windowDays; age++) {
    final sampleIndex = dayIndex - age;
    if (sampleIndex == dayIndex) {
      sum += officialKg;
    } else if (sampleIndex >= 0) {
      sum += series[sampleIndex].officialKg;
    } else {
      sum += startingWeightKg;
    }
  }
  return sum / WeightSeries.windowDays;
}

const int defaultRuleCount = 5;
