class ScaleChange {
  const ScaleChange({required this.lossKg, required this.weeklyLossKg});

  /// Starting weight minus the official weight. Positive means weight lost.
  final double lossKg;

  /// [lossKg] spread across the days since the start. Null on day 0.
  final double? weeklyLossKg;
}

ScaleChange scaleChange({
  required double startingWeightKg,
  required double officialKg,
  required int dayIndex,
}) {
  final lossKg = startingWeightKg - officialKg;
  return ScaleChange(
    lossKg: lossKg,
    weeklyLossKg: dayIndex <= 0 ? null : lossKg * 7 / dayIndex,
  );
}
