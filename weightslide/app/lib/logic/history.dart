import '../models/local_date.dart';
import '../models/records.dart';
import 'weight_series.dart';

class HistoryRow {
  const HistoryRow({
    required this.date,
    required this.dayIndex,
    required this.officialKg,
    required this.measured,
    required this.movingAverageKg,
    required this.activeLevel,
  });

  final LocalDate date;
  final int dayIndex;
  final double officialKg;
  final bool measured;
  final double movingAverageKg;
  final int activeLevel;
}

class HistoryBuilder {
  const HistoryBuilder._();

  /// End-of-day level, replaying stored crossings onto the initial level 3.
  static List<HistoryRow> build({
    required Journey journey,
    required List<WeightReading> readings,
    required List<CrossingEvent> crossings,
    required LocalDate through,
  }) {
    final series = WeightSeries.build(
      start: journey.startDate,
      through: through,
      startingWeightKg: journey.startingWeightKg,
      readings: readings,
    );
    final ordered = [...crossings]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    var level = 3;
    var cursor = 0;
    final rows = <HistoryRow>[];
    for (final point in series) {
      while (cursor < ordered.length &&
          ordered[cursor].evaluationDate <= point.date) {
        level = ordered[cursor].resultingLevel;
        cursor += 1;
      }
      rows.add(
        HistoryRow(
          date: point.date,
          dayIndex: point.dayIndex,
          officialKg: point.officialKg,
          measured: point.measured,
          movingAverageKg: point.movingAverageKg,
          activeLevel: level,
        ),
      );
    }
    return rows;
  }
}
