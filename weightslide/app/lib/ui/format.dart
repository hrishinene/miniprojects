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
