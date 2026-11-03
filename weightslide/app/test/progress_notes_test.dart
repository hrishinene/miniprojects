import 'package:flutter_test/flutter_test.dart';

import 'package:weight_slide/logic/progress_notes.dart';
import 'package:weight_slide/models/local_date.dart';

void main() {
  const target = 92.0;

  test('an average below the target line uses an encouraging note', () {
    final note = progressNote(
      movingAverageKg: 91.4,
      targetLineKg: target,
      date: LocalDate(2026, 6, 2),
    );
    expect(
      progressTone(movingAverageKg: 91.4, targetLineKg: target),
      ProgressTone.ahead,
    );
    expect(aheadNotes, contains(note));
    expect(behindNotes, isNot(contains(note)));
  });

  test('an average above the target line uses a note about getting back', () {
    final note = progressNote(
      movingAverageKg: 92.8,
      targetLineKg: target,
      date: LocalDate(2026, 6, 2),
    );
    expect(
      progressTone(movingAverageKg: 92.8, targetLineKg: target),
      ProgressTone.behind,
    );
    expect(behindNotes, contains(note));
    expect(aheadNotes, isNot(contains(note)));
  });

  test('sitting on the target line stays neutral', () {
    final note = progressNote(
      movingAverageKg: target,
      targetLineKg: target,
      date: LocalDate(2026, 6, 2),
    );
    expect(
      progressTone(movingAverageKg: target + 1e-12, targetLineKg: target),
      ProgressTone.steady,
    );
    expect(steadyNotes, contains(note));
  });

  test('the same day keeps the same sentence', () {
    const date = LocalDate(2026, 6, 2);
    final first = progressNote(
      movingAverageKg: 91,
      targetLineKg: target,
      date: date,
    );
    final second = progressNote(
      movingAverageKg: 91,
      targetLineKg: target,
      date: date,
    );
    expect(second, first);

    final otherDay = progressNote(
      movingAverageKg: 91,
      targetLineKg: target,
      date: LocalDate(2026, 6, 9),
    );
    expect(aheadNotes, contains(otherDay));
  });
}
