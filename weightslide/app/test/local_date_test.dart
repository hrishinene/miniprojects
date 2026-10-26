import 'package:flutter_test/flutter_test.dart';

import 'package:weight_slide/models/local_date.dart';

void main() {
  test('calendar arithmetic crosses month and year boundaries', () {
    expect(LocalDate(2026, 1, 31).addDays(1), LocalDate(2026, 2, 1));
    expect(LocalDate(2026, 2, 1).daysSince(LocalDate(2026, 1, 31)), 1);
    expect(LocalDate(2025, 12, 31).addDays(1), LocalDate(2026, 1, 1));
    expect(LocalDate(2026, 1, 1).daysSince(LocalDate(2025, 12, 31)), 1);
    expect(LocalDate(2026, 3, 29).addDays(1), LocalDate(2026, 3, 30));
    expect(LocalDate(2026, 3, 30).daysSince(LocalDate(2026, 3, 29)), 1);
  });
}
