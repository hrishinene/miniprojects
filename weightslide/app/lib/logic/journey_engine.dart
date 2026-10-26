import '../logic/crossing_detector.dart';
import '../logic/reference_lines.dart';
import '../logic/validation.dart';
import '../logic/weight_series.dart';
import '../models/local_date.dart';
import '../models/records.dart';
import '../persistence/journey_repository.dart';

class JourneyEngine {
  JourneyEngine({
    required this.repository,
    required this.clock,
    IdSource? ids,
  }) : _ids = ids ?? IdSource();

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
    final point = series.last;
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

  Future<Journey> _evaluate(String journeyId) async {
    final journey = await repository.getJourney(journeyId);
    if (today < journey.startDate) {
      return journey;
    }
    final readings = await repository.readingsFor(journeyId);
    final existing = await repository.crossingsFor(journeyId);
    var sequence = existing.isEmpty ? 1 : existing.last.sequence + 1;
    final series = WeightSeries.build(
      start: journey.startDate,
      through: today,
      startingWeightKg: journey.startingWeightKg,
      readings: readings,
    );

    var snapshot = journey.baseline;
    final newEvents = <CrossingEvent>[];
    for (final point in series) {
      if (point.date < snapshot.date) {
        continue;
      }
      if (point.date == snapshot.date &&
          (point.officialKg - snapshot.officialKg).abs() <=
              CrossingDetector.tolerance) {
        continue;
      }
      final step = CrossingDetector.step(
        from: snapshot,
        date: point.date,
        officialKg: point.officialKg,
        movingAverageKg: point.movingAverageKg,
        startingWeightKg: journey.startingWeightKg,
        weeklyTargetKg: journey.weeklyTargetKg,
        dayIndex: point.dayIndex,
      );
      final evaluatedAt = clock();
      for (final draft in step.crossings) {
        newEvents.add(
          CrossingEvent(
            id: _ids.next('crossing'),
            journeyId: journey.id,
            lineNumber: draft.lineNumber,
            direction: draft.direction,
            evaluatedAt: evaluatedAt,
            evaluationDate: point.date,
            movingAverageKg: draft.movingAverageKg,
            lineValueKg: draft.lineValueKg,
            resultingLevel: draft.resultingLevel,
            sequence: sequence,
          ),
        );
        sequence += 1;
      }
      snapshot = step.snapshot;
    }

    final updated = journey.copyWith(
      activeLevel: snapshot.activeLevel,
      baseline: snapshot,
    );
    await repository.saveJourney(updated, newCrossings: newEvents);
    return updated;
  }
}

const int defaultRuleCount = 5;
