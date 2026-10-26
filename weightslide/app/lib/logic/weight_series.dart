import '../models/local_date.dart';
import '../models/records.dart';

class DailyPoint {
  const DailyPoint({
    required this.date,
    required this.dayIndex,
    required this.officialKg,
    required this.measured,
    required this.movingAverageKg,
  });

  final LocalDate date;
  final int dayIndex;
  final double officialKg;

  /// False when [officialKg] was carried forward or seeded by the start weight.
  final bool measured;
  final double movingAverageKg;
}

class WeightSeries {
  const WeightSeries._();

  static Map<LocalDate, double> dailyMinimums(
    Iterable<WeightReading> readings,
  ) {
    final minimums = <LocalDate, double>{};
    for (final reading in readings) {
      final current = minimums[reading.date];
      if (current == null || reading.kg < current) {
        minimums[reading.date] = reading.kg;
      }
    }
    return minimums;
  }

  /// Official weights from [start] through [through], plus a seven-day mean.
  ///
  /// Days before [start] contribute the starting weight to the window only.
  /// Those days are not returned and are not stored as readings. A day with
  /// no reading keeps the previous official weight.
  static List<DailyPoint> build({
    required LocalDate start,
    required LocalDate through,
    required double startingWeightKg,
    required List<WeightReading> readings,
  }) {
    if (through < start) {
      throw ArgumentError('through must be on or after start');
    }
    final minimums = dailyMinimums(readings);
    final officials = <double>[];
    final points = <DailyPoint>[];
    var previous = startingWeightKg;
    var date = start;
    while (true) {
      final measured = minimums[date];
      final official = measured ?? previous;
      officials.add(official);
      final index = officials.length - 1;
      var sum = 0.0;
      for (var age = 0; age < 7; age++) {
        final sampleIndex = index - age;
        sum += sampleIndex >= 0 ? officials[sampleIndex] : startingWeightKg;
      }
      points.add(
        DailyPoint(
          date: date,
          dayIndex: date.daysSince(start),
          officialKg: official,
          measured: measured != null,
          movingAverageKg: sum / 7,
        ),
      );
      previous = official;
      if (date == through) {
        return points;
      }
      date = date.addDays(1);
    }
  }
}
