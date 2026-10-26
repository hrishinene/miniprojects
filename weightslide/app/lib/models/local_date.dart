/// A calendar date with no time and no timezone.
///
/// Arithmetic uses UTC date components so daylight-saving transitions cannot
/// skip or repeat a day. Build values from a local [DateTime]'s year, month,
/// and day. Do not convert a local midnight with [DateTime.toUtc].
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.fromDateTime(DateTime dateTime) {
    return LocalDate(dateTime.year, dateTime.month, dateTime.day);
  }

  factory LocalDate.parse(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) {
      throw FormatException('Expected a YYYY-MM-DD date', iso);
    }
    return LocalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  LocalDate addDays(int days) {
    final shifted = DateTime.utc(year, month, day + days);
    return LocalDate(shifted.year, shifted.month, shifted.day);
  }

  /// Calendar days from [earlier] until this date.
  int daysSince(LocalDate earlier) => _utc.difference(earlier._utc).inDays;

  String toIso() {
    final monthText = month.toString().padLeft(2, '0');
    final dayText = day.toString().padLeft(2, '0');
    return '$year-$monthText-$dayText';
  }

  @override
  int compareTo(LocalDate other) => daysSince(other);

  bool operator <(LocalDate other) => compareTo(other) < 0;

  bool operator >(LocalDate other) => compareTo(other) > 0;

  bool operator <=(LocalDate other) => compareTo(other) <= 0;

  bool operator >=(LocalDate other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) {
    return other is LocalDate &&
        year == other.year &&
        month == other.month &&
        day == other.day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
