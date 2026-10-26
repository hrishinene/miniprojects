import '../models/local_date.dart';
import '../models/records.dart';
import 'reference_lines.dart';

/// A crossing found between two evaluated trend states, before it is stored.
class CrossingDraft {
  const CrossingDraft({
    required this.lineNumber,
    required this.direction,
    required this.movingAverageKg,
    required this.lineValueKg,
    required this.resultingLevel,
  });

  final int lineNumber;
  final CrossingDirection direction;
  final double movingAverageKg;
  final double lineValueKg;
  final int resultingLevel;
}

class CrossingStep {
  const CrossingStep({required this.crossings, required this.snapshot});

  final List<CrossingDraft> crossings;
  final TrendSnapshot snapshot;
}

class _Candidate {
  const _Candidate({
    required this.lineNumber,
    required this.t,
    required this.direction,
    required this.lineValueKg,
  });

  final int lineNumber;
  final double t;
  final CrossingDirection direction;
  final double lineValueKg;
}

class CrossingDetector {
  const CrossingDetector._();

  /// Distances within this many kilograms of zero are on the line.
  ///
  /// Landing on a line, staying there, or leaving it toward the same side
  /// does not emit a crossing. A crossing is recorded only when the newest
  /// non-zero side is opposite the remembered non-zero side. Equality
  /// therefore cannot create an event on every recalculation.
  static const double tolerance = 1e-9;

  static LineSide? nonZeroSide(double distance) {
    if (distance > tolerance) {
      return LineSide.above;
    }
    if (distance < -tolerance) {
      return LineSide.below;
    }
    return null;
  }

  static List<LineSide?> sidesFromDistances(List<double> distances) {
    return [for (final distance in distances) nonZeroSide(distance)];
  }

  static TrendSnapshot initialSnapshot({
    required LocalDate date,
    required double startingWeightKg,
    required double weeklyTargetKg,
  }) {
    final lines = referenceLines(
      startingWeightKg: startingWeightKg,
      weeklyTargetKg: weeklyTargetKg,
      dayIndex: 0,
    );
    final distances = [for (final line in lines) startingWeightKg - line];
    return TrendSnapshot(
      date: date,
      officialKg: startingWeightKg,
      movingAverageKg: startingWeightKg,
      signedDistances: distances,
      activeLevel: 3,
      lastNonZeroSides: sidesFromDistances(distances),
    );
  }

  static CrossingStep step({
    required TrendSnapshot from,
    required LocalDate date,
    required double officialKg,
    required double movingAverageKg,
    required double startingWeightKg,
    required double weeklyTargetKg,
    required int dayIndex,
  }) {
    final lines = referenceLines(
      startingWeightKg: startingWeightKg,
      weeklyTargetKg: weeklyTargetKg,
      dayIndex: dayIndex,
    );
    return stepBetween(
      from: from,
      date: date,
      officialKg: officialKg,
      movingAverageKg: movingAverageKg,
      nextDistances: [for (final line in lines) movingAverageKg - line],
      lineValues: lines,
    );
  }

  /// [nextDistances] are the signed distances at the destination state.
  ///
  /// When several lines change side, they are ordered by the zero of
  /// `D(t) = D0 + t * (D1 - D0)`. Equal times break toward the direction of
  /// travel: a higher line number first when both crossings are downward,
  /// otherwise a lower line number first.
  static CrossingStep stepBetween({
    required TrendSnapshot from,
    required LocalDate date,
    required double officialKg,
    required double movingAverageKg,
    required List<double> nextDistances,
    required List<double> lineValues,
  }) {
    if (from.signedDistances.length != 5 ||
        nextDistances.length != 5 ||
        lineValues.length != 5 ||
        from.lastNonZeroSides.length != 5) {
      throw ArgumentError('Expected five reference lines');
    }

    final memory = List<LineSide?>.of(from.lastNonZeroSides);
    final candidates = <_Candidate>[];
    for (var index = 0; index < 5; index++) {
      final newSide = nonZeroSide(nextDistances[index]);
      if (newSide == null) {
        continue;
      }
      final previousSide = from.lastNonZeroSides[index];
      memory[index] = newSide;
      if (previousSide == null || previousSide == newSide) {
        continue;
      }
      final startDistance = from.signedDistances[index];
      final endDistance = nextDistances[index];
      final span = endDistance - startDistance;
      var t = 0.0;
      if (span.abs() > tolerance) {
        t = -startDistance / span;
        if (t < 0) {
          t = 0;
        } else if (t > 1) {
          t = 1;
        }
      }
      candidates.add(
        _Candidate(
          lineNumber: index + 1,
          t: t,
          direction: newSide == LineSide.above
              ? CrossingDirection.up
              : CrossingDirection.down,
          lineValueKg: lineValues[index],
        ),
      );
    }

    candidates.sort((a, b) {
      final byTime = a.t.compareTo(b.t);
      if (byTime != 0) {
        return byTime;
      }
      final bothDown =
          a.direction == CrossingDirection.down &&
          b.direction == CrossingDirection.down;
      if (bothDown) {
        return b.lineNumber.compareTo(a.lineNumber);
      }
      return a.lineNumber.compareTo(b.lineNumber);
    });

    var level = from.activeLevel;
    final drafts = <CrossingDraft>[];
    for (final candidate in candidates) {
      level = candidate.lineNumber;
      drafts.add(
        CrossingDraft(
          lineNumber: candidate.lineNumber,
          direction: candidate.direction,
          movingAverageKg: movingAverageKg,
          lineValueKg: candidate.lineValueKg,
          resultingLevel: level,
        ),
      );
    }

    return CrossingStep(
      crossings: drafts,
      snapshot: TrendSnapshot(
        date: date,
        officialKg: officialKg,
        movingAverageKg: movingAverageKg,
        signedDistances: List<double>.of(nextDistances),
        activeLevel: level,
        lastNonZeroSides: memory,
      ),
    );
  }
}
