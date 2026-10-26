const double minWeightKg = 20;
const double maxWeightKg = 400;
const double maxWeeklyTargetKg = 5;

String? validateWeight(double? kilograms) {
  if (kilograms == null || kilograms.isNaN || kilograms.isInfinite) {
    return 'Enter a weight in kilograms.';
  }
  if (kilograms <= 0) {
    return 'Weight must be greater than zero.';
  }
  if (kilograms < minWeightKg || kilograms > maxWeightKg) {
    return 'Enter a weight between 20 and 400 kg.';
  }
  return null;
}

String? validateWeeklyTarget(double? kilograms) {
  if (kilograms == null || kilograms.isNaN || kilograms.isInfinite) {
    return 'Enter a weekly target in kilograms.';
  }
  if (kilograms <= 0) {
    return 'Weekly target must be greater than zero.';
  }
  if (kilograms > maxWeeklyTargetKg) {
    return 'Enter a weekly target of 5 kg or less.';
  }
  return null;
}

double? parseKilograms(String raw) => double.tryParse(raw.trim());
