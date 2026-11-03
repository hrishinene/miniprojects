import '../models/local_date.dart';
import '../models/records.dart';

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatDate(LocalDate date) {
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

String formatKg(double kilograms) => '${kilograms.toStringAsFixed(1)} kg';

String formatLossSoFar(double lossKg) {
  return _formatChange(lossKg, soFar: true);
}

String formatWeeklyPace(double weeklyLossKg) {
  return _formatChange(weeklyLossKg, soFar: false);
}

String _formatChange(double lossKg, {required bool soFar}) {
  final shown = lossKg.abs().toStringAsFixed(1);
  if (shown == '0.0') {
    return soFar ? 'No change so far' : 'Average weekly change 0.0 kg';
  }
  final direction = lossKg > 0 ? 'loss' : 'gain';
  if (soFar) {
    final word = lossKg > 0 ? 'Loss' : 'Gain';
    return '$word so far $shown kg';
  }
  return 'Average weekly $direction $shown kg';
}

String formatTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String levelExplanation(int activeLevel, List<CrossingEvent> crossings) {
  if (crossings.isEmpty) {
    return 'Level $activeLevel since the start of this journey. No reference line has been crossed.';
  }
  final latest = crossings.last;
  final direction = latest.direction == CrossingDirection.up
      ? 'upward'
      : 'downward';
  return 'Level $activeLevel because the trend crossed line ${latest.lineNumber} $direction on ${formatDate(latest.evaluationDate)}.';
}
