import 'package:flutter_test/flutter_test.dart';

import 'package:weight_slide/logic/weight_change.dart';
import 'package:weight_slide/ui/format.dart';

void main() {
  test('loss and weekly pace use the official weight', () {
    final loss = scaleChange(
      startingWeightKg: 92,
      officialKg: 90.4,
      dayIndex: 14,
    );
    expect(loss.lossKg, closeTo(1.6, 1e-9));
    expect(loss.weeklyLossKg, closeTo(1.6 * 7 / 14, 1e-9));
    expect(formatLossSoFar(loss.lossKg), 'Loss so far 1.6 kg');
    expect(formatWeeklyPace(loss.weeklyLossKg!), 'Average weekly loss 0.8 kg');

    final gain = scaleChange(
      startingWeightKg: 92,
      officialKg: 92.4,
      dayIndex: 7,
    );
    expect(formatLossSoFar(gain.lossKg), 'Gain so far 0.4 kg');
    expect(formatWeeklyPace(gain.weeklyLossKg!), 'Average weekly gain 0.4 kg');

    final start = scaleChange(
      startingWeightKg: 92,
      officialKg: 92,
      dayIndex: 0,
    );
    expect(start.weeklyLossKg, isNull);
    expect(formatLossSoFar(start.lossKg), 'No change so far');
    expect(formatWeeklyPace(0.04), 'Average weekly change 0.0 kg');
  });
}
