import 'package:flutter_test/flutter_test.dart';

import 'package:weight_slide/logic/journey_engine.dart';
import 'package:weight_slide/logic/reference_lines.dart';
import 'package:weight_slide/logic/rules.dart';
import 'package:weight_slide/logic/validation.dart';
import 'package:weight_slide/logic/weight_series.dart';
import 'package:weight_slide/models/local_date.dart';
import 'package:weight_slide/models/records.dart';
import 'package:weight_slide/persistence/memory_repository.dart';

void main() {
  test('rejects empty, negative, and unreasonable weights', () {
    expect(validateWeight(null), isNotNull);
    expect(validateWeight(double.nan), isNotNull);
    expect(validateWeight(0), isNotNull);
    expect(validateWeight(-4), isNotNull);
    expect(validateWeight(parseKilograms('nope')), isNotNull);
    expect(validateWeight(19), isNotNull);
    expect(validateWeight(92.4), isNull);
    expect(validateWeeklyTarget(0), isNotNull);
    expect(validateWeeklyTarget(5), isNull);
    expect(validateWeeklyTarget(5.1), isNotNull);
  });

  test(
    'daily minimum, carry-forward, and crossings follow the journey clock',
    () async {
      final clock = _Clock(DateTime(2026, 3, 1, 9));
      final repository = MemoryRepository();
      final engine = _engine(repository, clock);

      final created = await engine.createJourney(
        startingWeightKg: 92,
        startDate: LocalDate(2026, 3, 1),
        weeklyTargetKg: 0.5,
      );
      expect(created.activeLevel, 3);
      expect(await repository.crossingsFor(created.id), isEmpty);
      expect(
        rulesForLevel(created.activeLevel, await repository.rules()),
        hasLength(3),
      );

      await engine.addReading(100);
      var journey = (await repository.activeJourney())!;
      var events = await repository.crossingsFor(journey.id);
      expect(events.map((event) => event.lineNumber), [4, 5]);
      expect(journey.activeLevel, 5);
      expect(
        events.every(
          (event) => event.resultingLevel == 4 || event.lineNumber == 5,
        ),
        isTrue,
      );
      expect(events.last.resultingLevel, 5);

      final afterHigh = events.length;
      await engine.addReading(101);
      journey = (await repository.activeJourney())!;
      events = await repository.crossingsFor(journey.id);
      expect(events, hasLength(afterHigh));
      expect((await _series(engine, repository)).last.officialKg, 100);

      await engine.addReading(89);
      journey = (await repository.activeJourney())!;
      events = await repository.crossingsFor(journey.id);
      expect(events.map((event) => event.lineNumber), [4, 5, 5, 4, 3, 2]);
      expect(journey.activeLevel, 2);
      expect((await _series(engine, repository)).last.officialKg, 89);
      expect(
        rulesForLevel(journey.activeLevel, await repository.rules()),
        hasLength(2),
      );

      final beforeRepeat = events.length;
      await engine.catchUp();
      await engine.addReading(95);
      expect(
        await repository.crossingsFor(journey.id),
        hasLength(beforeRepeat),
      );

      await engine.addReading(86);
      journey = (await repository.activeJourney())!;
      events = await repository.crossingsFor(journey.id);
      expect(events.last.lineNumber, 1);
      expect(journey.activeLevel, 1);
      expect(rulesForLevel(1, await repository.rules()), hasLength(1));

      final eventIds = events.map((event) => event.id).toList();
      final restored = MemoryRepository.decode(repository.encode());
      final restarted = _engine(restored, clock);
      await restarted.catchUp();
      final restoredEvents = await restored.crossingsFor(journey.id);
      expect(restoredEvents.map((event) => event.id), eventIds);
      expect((await restored.activeJourney())!.activeLevel, 1);
    },
  );

  test('a past date cannot be written', () async {
    final clock = _Clock(DateTime(2026, 2, 1, 8));
    final repository = MemoryRepository();
    final engine = _engine(repository, clock);
    await engine.createJourney(
      startingWeightKg: 80,
      startDate: LocalDate(2026, 2, 1),
      weeklyTargetKg: 0.5,
    );
    await engine.addReading(80);
    expect(
      () => engine.addReadingOnDate(LocalDate(2026, 1, 31), 79),
      throwsA(isA<WeightSlideException>()),
    );
    expect(() => engine.addReading(0), throwsA(isA<WeightSlideException>()));
    final journey = (await repository.activeJourney())!;
    final readings = await repository.readingsFor(journey.id);
    expect(readings, hasLength(1));
    expect(readings.single.date, LocalDate(2026, 2, 1));
  });

  test(
    'missed days carry the weight and can cross as the lines descend',
    () async {
      final clock = _Clock(DateTime(2026, 1, 11, 8));
      final repository = MemoryRepository();
      final engine = _engine(repository, clock);
      final journey = await engine.createJourney(
        startingWeightKg: 92,
        startDate: LocalDate(2026, 1, 1),
        weeklyTargetKg: 0.5,
      );

      expect(await repository.readingsFor(journey.id), isEmpty);
      final series = await _series(engine, repository);
      expect(series, hasLength(11));
      expect(
        series.every((point) => point.officialKg == 92 && !point.measured),
        isTrue,
      );

      final events = await repository.crossingsFor(journey.id);
      expect(events.map((event) => event.lineNumber), [4, 5]);
      expect(events.map((event) => event.evaluationDate), [
        LocalDate(2026, 1, 5),
        LocalDate(2026, 1, 9),
      ]);
      expect(events.map((event) => event.direction), [
        CrossingDirection.up,
        CrossingDirection.up,
      ]);
      expect((await repository.activeJourney())!.activeLevel, 5);
      expect(events.any((event) => event.lineNumber == 3), isFalse);
    },
  );

  test(
    'editing rules and changing the weekly target keep the crossing history',
    () async {
      final clock = _Clock(DateTime(2026, 4, 1, 7));
      final repository = MemoryRepository();
      final engine = _engine(repository, clock);
      await engine.createJourney(
        startingWeightKg: 92,
        startDate: LocalDate(2026, 4, 1),
        weeklyTargetKg: 0.5,
      );
      await engine.addReading(100);
      final before = await repository.crossingsFor(
        (await repository.activeJourney())!.id,
      );
      final level = (await repository.activeJourney())!.activeLevel;

      await engine.updateRules([
        'Edited foundation habit',
        ...defaultRuleTexts.skip(1),
      ]);
      expect((await repository.rules()).first, 'Edited foundation habit');
      expect((await repository.activeJourney())!.activeLevel, level);
      expect(
        await repository.crossingsFor(before.first.journeyId),
        hasLength(before.length),
      );

      final updated = await engine.updateWeeklyTarget(1);
      final events = await repository.crossingsFor(updated.id);
      expect(events.map((event) => event.id), before.map((event) => event.id));
      expect(updated.activeLevel, level);
      final series = WeightSeries.build(
        start: updated.startDate,
        through: engine.today,
        startingWeightKg: updated.startingWeightKg,
        readings: await repository.readingsFor(updated.id),
      );
      final lines = referenceLines(
        startingWeightKg: updated.startingWeightKg,
        weeklyTargetKg: 1,
        dayIndex: series.last.dayIndex,
      );
      for (var index = 0; index < 5; index++) {
        expect(
          updated.baseline.signedDistances[index],
          closeTo(series.last.movingAverageKg - lines[index], 1e-9),
        );
      }

      clock.now = DateTime(2026, 4, 2, 7);
      await engine.catchUp();
      final later = await repository.crossingsFor(updated.id);
      expect(
        later.take(before.length).map((event) => event.id),
        before.map((event) => event.id),
      );
    },
  );

  test('a new journey keeps the previous one and starts at level 3', () async {
    final clock = _Clock(DateTime(2026, 5, 2, 10));
    final repository = MemoryRepository();
    final engine = _engine(repository, clock);
    final first = await engine.createJourney(
      startingWeightKg: 88,
      startDate: LocalDate(2026, 5, 1),
      weeklyTargetKg: 0.4,
    );
    await engine.addReading(88);
    final firstReadings = await repository.readingsFor(first.id);
    final firstEvents = await repository.crossingsFor(first.id);

    final second = await engine.createJourney(
      startingWeightKg: 84,
      startDate: LocalDate(2026, 5, 2),
      weeklyTargetKg: 0.5,
    );

    expect(second.id, isNot(first.id));
    expect(second.activeLevel, 3);
    expect(await repository.crossingsFor(second.id), isEmpty);
    expect((await repository.getJourney(first.id)).isActive, isFalse);
    expect(await repository.readingsFor(first.id), firstReadings);
    expect(await repository.crossingsFor(first.id), firstEvents);
    expect((await repository.activeJourney())!.id, second.id);

    final archived = await repository.readingsFor(first.id);
    expect(archived.single.kg, 88);
    expect(await repository.readingsFor(second.id), isEmpty);
  });
}

class _Clock {
  _Clock(this.now);

  DateTime now;
}

JourneyEngine _engine(MemoryRepository repository, _Clock clock) {
  return JourneyEngine(
    repository: repository,
    clock: () => clock.now,
    ids: IdSource(),
  );
}

Future<List<DailyPoint>> _series(
  JourneyEngine engine,
  MemoryRepository repository,
) async {
  final journey = (await repository.activeJourney())!;
  return WeightSeries.build(
    start: journey.startDate,
    through: engine.today,
    startingWeightKg: journey.startingWeightKg,
    readings: await repository.readingsFor(journey.id),
  );
}
