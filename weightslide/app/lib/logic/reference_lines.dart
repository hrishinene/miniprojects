/// L(n, d) = W0 - r * d / 7 + (n - 3) * r / 2
double referenceLine({
  required double startingWeightKg,
  required double weeklyTargetKg,
  required int dayIndex,
  required int lineNumber,
}) {
  return startingWeightKg -
      weeklyTargetKg * dayIndex / 7 +
      (lineNumber - 3) * weeklyTargetKg / 2;
}

List<double> referenceLines({
  required double startingWeightKg,
  required double weeklyTargetKg,
  required int dayIndex,
}) {
  return [
    for (var line = 1; line <= 5; line++)
      referenceLine(
        startingWeightKg: startingWeightKg,
        weeklyTargetKg: weeklyTargetKg,
        dayIndex: dayIndex,
        lineNumber: line,
      ),
  ];
}
