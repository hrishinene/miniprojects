import '../models/local_date.dart';
import 'crossing_detector.dart';

/// The three-day average compared with the central target line.
enum ProgressTone { ahead, steady, behind }

const List<String> aheadNotes = [
  'The trend is below the target line. Keep the same habits.',
  'This stretch is lighter than the plan. Stay with what is working.',
  'The average is ahead of the line. The current rules are enough.',
  'The loss is showing in the three-day average. Continue as you are.',
  'You are on the light side of the target. No new restriction is needed.',
];

const List<String> steadyNotes = [
  'The average is on the target line. Keep today\'s rules as they are.',
  'You are tracking the plan. Nothing extra is required today.',
  'The trend is sitting on the central line. Hold the same routine.',
  'Weight is following the line you set. Stay with the rules that apply.',
];

const List<String> behindNotes = [
  'The average is above the target line. Today\'s rules are the way back.',
  'The trend has drifted high. Return to the rules that apply now.',
  'A few steady days will pull the average back toward the line.',
  'The plan has not changed. Follow the rules below and the gap can close.',
  'This is a heavier stretch. The rules for this level are there to close it.',
];

ProgressTone progressTone({
  required double movingAverageKg,
  required double targetLineKg,
}) {
  final gap = movingAverageKg - targetLineKg;
  if (gap.abs() <= CrossingDetector.tolerance) {
    return ProgressTone.steady;
  }
  if (gap < 0) {
    return ProgressTone.ahead;
  }
  return ProgressTone.behind;
}

/// One sentence for [date]. The same date keeps the same sentence until the
/// tone changes, so a redraw does not pick a new line.
String progressNote({
  required double movingAverageKg,
  required double targetLineKg,
  required LocalDate date,
}) {
  final notes = switch (progressTone(
    movingAverageKg: movingAverageKg,
    targetLineKg: targetLineKg,
  )) {
    ProgressTone.ahead => aheadNotes,
    ProgressTone.steady => steadyNotes,
    ProgressTone.behind => behindNotes,
  };
  final index =
      Object.hash(date.year, date.month, date.day).abs() % notes.length;
  return notes[index];
}
