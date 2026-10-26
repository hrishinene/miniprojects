import 'package:flutter_test/flutter_test.dart';

import 'package:weight_slide/logic/crossing_detector.dart';
import 'package:weight_slide/logic/rules.dart';
import 'package:weight_slide/models/local_date.dart';
import 'package:weight_slide/models/records.dart';

void main() {
  const date = LocalDate(2026, 1, 1);
  const lines = [0.0, 0.0, 0.0, 0.0, 0.0];

  TrendSnapshot snapshot(List<double> distances, {int level = 3}) {
    return TrendSnapshot(
      date: date,
      officialKg: 0,
      movingAverageKg: 0,
      signedDistances: distances,
      activeLevel: level,
      lastNonZeroSides: CrossingDetector.sidesFromDistances(distances),
    );
  }

  CrossingStep move(
    TrendSnapshot from,
    List<double> distances, {
    double average = 0,
  }) {
    return CrossingDetector.stepBetween(
      from: from,
      date: date.addDays(1),
      officialKg: average,
      movingAverageKg: average,
      nextDistances: distances,
      lineValues: lines,
    );
  }

  test('crossing a line from either direction selects that line', () {
    for (var line = 1; line <= 5; line++) {
      final below = List<double>.filled(5, 2);
      final above = List<double>.filled(5, 2);
      below[line - 1] = -1;
      above[line - 1] = 1;

      final upward = move(snapshot(below), above);
      expect(upward.crossings.single.lineNumber, line);
      expect(upward.crossings.single.direction, CrossingDirection.up);
      expect(upward.snapshot.activeLevel, line);

      final downward = move(snapshot(above, level: line), below);
      expect(downward.crossings.single.lineNumber, line);
      expect(downward.crossings.single.direction, CrossingDirection.down);
      expect(downward.snapshot.activeLevel, line);
    }
  });

  test('crossing the same line again keeps that level', () {
    final below = snapshot([2, 2, -1, -2, -2], level: 4);
    final above = move(below, [2, 2, 1, -2, -2]);
    final back = move(above.snapshot, [2, 2, -1, -2, -2]);

    expect(above.snapshot.activeLevel, 3);
    expect(back.snapshot.activeLevel, 3);
    expect(back.crossings.single.lineNumber, 3);
  });

  test('movement inside a band does not change the level', () {
    final from = snapshot([2, 0.4, -0.2, -1, -2], level: 2);
    final result = move(from, [1.5, 0.1, -0.8, -1.4, -3]);
    expect(result.crossings, isEmpty);
    expect(result.snapshot.activeLevel, 2);
  });

  test('touching a line does not emit a crossing', () {
    final from = snapshot([2, 2, -0.4, -2, -2], level: 2);
    final touched = move(from, [2, 2, 0, -2, -2]);
    final still = move(touched.snapshot, [2, 2, 1e-12, -2, -2]);
    final sameSide = move(still.snapshot, [2, 2, -0.2, -2, -2]);

    expect(touched.crossings, isEmpty);
    expect(still.crossings, isEmpty);
    expect(sameSide.crossings, isEmpty);
    expect(sameSide.snapshot.activeLevel, 2);
    expect(touched.snapshot.lastNonZeroSides[2], LineSide.below);
  });

  test(
    'several crossings are applied from the first line reached to the last',
    () {
      final fromDistances = [2.2, 1.7, 1.2, 0.7, 0.2];
      final toDistances = [-0.2, -0.7, -1.2, -1.7, -2.2];
      final result = CrossingDetector.stepBetween(
        from: snapshot(fromDistances, level: 5),
        date: date.addDays(1),
        officialKg: 90.8,
        movingAverageKg: 90.8,
        nextDistances: toDistances,
        lineValues: const [91, 91.5, 92, 92.5, 93],
      );

      expect(result.crossings.map((event) => event.lineNumber), [
        5,
        4,
        3,
        2,
        1,
      ]);
      expect(result.snapshot.activeLevel, 1);
    },
  );

  test('equal crossing times break toward the direction of travel', () {
    final result = move(snapshot([3, 1, 3, 1, 3], level: 5), [3, -1, 3, -1, 3]);
    expect(result.crossings.map((event) => event.lineNumber), [4, 2]);
    expect(result.snapshot.activeLevel, 2);
  });

  test('values inside the tolerance do not create a crossing', () {
    final from = snapshot([1, 1, 1e-12, -1, -1]);
    final again = move(from, [1, 1, -1e-12, -1, -1]);
    final repeat = move(again.snapshot, [1, 1, 0, -1, -1]);
    expect(again.crossings, isEmpty);
    expect(repeat.crossings, isEmpty);

    final tinyCross = move(snapshot([1, 1, -2e-9, -1, -1]), [
      1,
      1,
      2e-9,
      -1,
      -1,
    ]);
    expect(tinyCross.crossings.single.lineNumber, 3);
    final duplicate = move(tinyCross.snapshot, [1, 1, 2e-9, -1, -1]);
    expect(duplicate.crossings, isEmpty);
  });

  test(
    'starting on line 3 does not create a crossing when the trend leaves it',
    () {
      final initial = CrossingDetector.initialSnapshot(
        date: date,
        startingWeightKg: 92,
        weeklyTargetKg: 0.5,
      );
      expect(initial.activeLevel, 3);
      expect(
        initial.signedDistances[2].abs(),
        lessThanOrEqualTo(CrossingDetector.tolerance),
      );

      final next = List<double>.of(initial.signedDistances);
      next[2] = -0.2;
      final result = CrossingDetector.stepBetween(
        from: initial,
        date: date,
        officialKg: 91.8,
        movingAverageKg: 91.8,
        nextDistances: next,
        lineValues: lines,
      );
      expect(result.crossings, isEmpty);
      expect(result.snapshot.activeLevel, 3);
    },
  );

  test('cumulative rules follow the active level and ignore text edits', () {
    const rules = defaultRuleTexts;
    expect(rulesForLevel(1, rules), [rules[0]]);
    expect(rulesForLevel(3, rules), rules.sublist(0, 3));
    expect(rulesForLevel(5, rules), rules);
    final edited = [...rules]..[4] = 'Edited habit';
    expect(rulesForLevel(2, edited), [edited[0], edited[1]]);
    expect(rulesForLevel(2, edited).length, 2);
  });
}
