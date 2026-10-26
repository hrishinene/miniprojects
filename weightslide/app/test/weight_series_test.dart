import 'package:flutter_test/flutter_test.dart';

import 'package:weight_slide/logic/reference_lines.dart';
import 'package:weight_slide/logic/weight_series.dart';
import 'package:weight_slide/models/local_date.dart';
import 'package:weight_slide/models/records.dart';

void main() {
  test('the lowest reading is the official weight', () {
    final points = WeightSeries.build(
      start: LocalDate(2026, 1, 30),
      through: LocalDate(2026, 2, 1),
      startingWeightKg: 80,
      readings: [
        _reading(LocalDate(2026, 1, 30), 81),
        _reading(LocalDate(2026, 1, 30), 80.4),
        _reading(LocalDate(2026, 2, 1), 79.2),
        _reading(LocalDate(2026, 2, 1), 79.8),
      ],
    );

    expect(points, hasLength(3));
    expect(points[0].date, LocalDate(2026, 1, 30));
    expect(points[0].officialKg, 80.4);
    expect(points[0].measured, isTrue);
    expect(points[1].date, LocalDate(2026, 1, 31));
    expect(points[1].officialKg, 80.4);
    expect(points[1].measured, isFalse);
    expect(points[2].date, LocalDate(2026, 2, 1));
    expect(points[2].officialKg, 79.2);
    expect(points[2].measured, isTrue);
    expect(points[2].dayIndex, 2);
  });

  test('the starting weight seeds the first day and missing days', () {
    final points = WeightSeries.build(
      start: LocalDate(2025, 12, 31),
      through: LocalDate(2026, 1, 2),
      startingWeightKg: 70,
      readings: [_reading(LocalDate(2026, 1, 2), 69)],
    );

    expect(points[0].officialKg, 70);
    expect(points[0].measured, isFalse);
    expect(points[1].date, LocalDate(2026, 1, 1));
    expect(points[1].officialKg, 70);
    expect(points[1].measured, isFalse);
    expect(points[2].officialKg, 69);
  });

  test(
    'seven-day mean uses seeds and carried-forward weights at full precision',
    () {
      final points = WeightSeries.build(
        start: LocalDate(2026, 1, 1),
        through: LocalDate(2026, 1, 7),
        startingWeightKg: 70,
        readings: [
          _reading(LocalDate(2026, 1, 2), 71),
          _reading(LocalDate(2026, 1, 3), 72),
          _reading(LocalDate(2026, 1, 4), 73),
          _reading(LocalDate(2026, 1, 5), 74),
          _reading(LocalDate(2026, 1, 6), 75),
          _reading(LocalDate(2026, 1, 7), 76),
        ],
      );

      expect(points.first.movingAverageKg, 70);
      expect(points[1].movingAverageKg, (70 * 6 + 71) / 7);
      expect(
        points[1].movingAverageKg,
        isNot(double.parse(points[1].movingAverageKg.toStringAsFixed(1))),
      );
      expect(
        points.last.movingAverageKg,
        (70 + 71 + 72 + 73 + 74 + 75 + 76) / 7,
      );

      final carried = WeightSeries.build(
        start: LocalDate(2026, 1, 1),
        through: LocalDate(2026, 1, 3),
        startingWeightKg: 80,
        readings: [
          _reading(LocalDate(2026, 1, 1), 80),
          _reading(LocalDate(2026, 1, 3), 78),
        ],
      );
      expect(carried[2].movingAverageKg, (80 * 6 + 78) / 7);
      expect(carried[1].measured, isFalse);
    },
  );

  test('reference lines follow the saved weekly target', () {
    double line(int number, int day, double weekly) {
      return referenceLine(
        startingWeightKg: 92,
        weeklyTargetKg: weekly,
        dayIndex: day,
        lineNumber: number,
      );
    }

    expect(line(1, 0, 0.5), closeTo(91.5, 1e-9));
    expect(line(2, 0, 0.5), closeTo(91.75, 1e-9));
    expect(line(3, 0, 0.5), closeTo(92, 1e-9));
    expect(line(4, 0, 0.5), closeTo(92.25, 1e-9));
    expect(line(5, 0, 0.5), closeTo(92.5, 1e-9));

    expect(line(1, 28, 0.5), closeTo(89.5, 1e-9));
    expect(line(3, 28, 0.5), closeTo(90, 1e-9));
    expect(line(5, 28, 0.5), closeTo(90.5, 1e-9));

    expect(line(1, 0, 1), closeTo(91, 1e-9));
    expect(line(2, 0, 1), closeTo(91.5, 1e-9));
    expect(line(5, 0, 1), closeTo(93, 1e-9));
    expect(line(3, 28, 1), closeTo(88, 1e-9));
    expect(line(1, 28, 1) - line(1, 0, 1), closeTo(-4, 1e-9));
  });
}

WeightReading _reading(LocalDate date, double kg) {
  return WeightReading(
    id: '$date-$kg',
    journeyId: 'journey',
    date: date,
    kg: kg,
    recordedAt: DateTime(date.year, date.month, date.day, 8),
  );
}
