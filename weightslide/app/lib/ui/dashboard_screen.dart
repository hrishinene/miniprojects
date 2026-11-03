import 'package:flutter/material.dart';

import '../logic/progress_notes.dart';
import '../logic/reference_lines.dart';
import '../logic/rules.dart';
import '../logic/validation.dart';
import '../logic/weight_change.dart';
import '../models/records.dart';
import '../state/app_controller.dart';
import 'app_mark.dart';
import 'format.dart';
import 'graph_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _weight = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    final parsed = parseKilograms(_weight.text);
    final validation = validateWeight(parsed);
    if (validation != null || parsed == null) {
      setState(() => _error = validation);
      return;
    }
    final kilograms = parsed;
    FocusManager.instance.primaryFocus?.unfocus();
    _submitting = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save this weight?'),
          content: Text('Save ${formatKg(kilograms)} for today?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
      final error = await widget.controller.saveWeight(kilograms);
      if (!mounted) {
        return;
      }
      setState(() => _error = error);
      if (error == null) {
        _weight.clear();
      }
    } finally {
      _submitting = false;
    }
  }

  Future<void> _removeLast(WeightReading reading) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this weight?'),
        content: Text(
          'Remove ${formatKg(reading.kg)} entered at ${formatTime(reading.recordedAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final error = await widget.controller.removeReading(reading.id);
    if (!mounted) {
      return;
    }
    setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.controller.activeDetails;
    if (details == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final point = details.latest;
    final level = details.journey.activeLevel;
    final applicable = rulesForLevel(level, widget.controller.ruleTexts);
    final seeded = !point.measured && point.date == details.journey.startDate;
    final source = point.measured
        ? 'Lowest reading today'
        : seeded
        ? 'Starting weight'
        : 'Carried forward';
    final change = scaleChange(
      startingWeightKg: details.journey.startingWeightKg,
      officialKg: point.officialKg,
      dayIndex: point.dayIndex,
    );
    final targetLine = referenceLine(
      startingWeightKg: details.journey.startingWeightKg,
      weeklyTargetKg: details.journey.weeklyTargetKg,
      dayIndex: point.dayIndex,
      lineNumber: 3,
    );
    final tone = progressTone(
      movingAverageKg: point.movingAverageKg,
      targetLineKg: targetLine,
    );
    final noteColor = switch (tone) {
      ProgressTone.ahead => const Color(0xFF0C8F55),
      ProgressTone.steady => const Color(0xFF147A78),
      ProgressTone.behind => const Color(0xFFD06A12),
    };
    final changeColor = change.lossKg >= 0
        ? const Color(0xFF0C8F55)
        : const Color(0xFFD06A12);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppMark(size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Weight Slide',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Graph',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => GraphScreen(details: details),
                ),
              );
            },
            icon: const Icon(Icons.show_chart),
          ),
          IconButton(
            tooltip: 'History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => HistoryScreen(
                    details: details,
                    controller: widget.controller,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => SettingsScreen(controller: widget.controller),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Text(formatDate(point.date)),
          const SizedBox(height: 8),
          Text(
            formatKg(point.officialKg),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(source),
          const SizedBox(height: 24),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(labelText: "Today's weight (kg)"),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.controller.busy ? null : _submit,
              child: const Text('Save weight'),
            ),
          ),
          if (details.readingsOn(widget.controller.today).isNotEmpty)
            TextButton(
              onPressed: widget.controller.busy
                  ? null
                  : () => _removeLast(
                      details.readingsOn(widget.controller.today).last,
                    ),
              child: const Text('Remove last entry'),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            formatLossSoFar(change.lossKg),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: changeColor),
          ),
          if (change.weeklyLossKg != null)
            Text(
              formatWeeklyPace(change.weeklyLossKg!),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: changeColor),
            ),
          const SizedBox(height: 16),
          Text(
            'Three-day average',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(formatKg(point.movingAverageKg)),
          const SizedBox(height: 8),
          Text(
            progressNote(
              movingAverageKg: point.movingAverageKg,
              targetLineKg: targetLine,
              date: point.date,
            ),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: noteColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Level $level of 5',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(levelExplanation(level, details.crossings)),
          const SizedBox(height: 24),
          Text("Today's rules", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (var index = 0; index < applicable.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${index + 1}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ruleTitles[index],
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(applicable[index]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
