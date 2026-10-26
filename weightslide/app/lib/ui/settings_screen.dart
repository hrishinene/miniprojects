import 'package:flutter/material.dart';

import '../logic/rules.dart';
import '../logic/validation.dart';
import '../state/app_controller.dart';
import 'format.dart';
import 'graph_screen.dart';
import 'history_screen.dart';
import 'setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _target;
  late final List<TextEditingController> _rules;
  String? _error;

  @override
  void initState() {
    super.initState();
    final journey = widget.controller.activeJourney;
    _target = TextEditingController(
      text: journey == null ? '0.5' : _plain(journey.weeklyTargetKg),
    );
    _rules = [
      for (final rule in widget.controller.ruleTexts)
        TextEditingController(text: rule),
    ];
  }

  @override
  void dispose() {
    _target.dispose();
    for (final controller in _rules) {
      controller.dispose();
    }
    super.dispose();
  }

  String _plain(double value) {
    var text = value.toStringAsFixed(2);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return text;
  }

  Future<void> _saveTarget() async {
    final target = parseKilograms(_target.text);
    final validation = validateWeeklyTarget(target);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change weekly target?'),
        content: const Text(
          'The reference lines will be recalculated from this journey\'s original starting weight and start date. Today\'s crossing baseline resets to the new lines. The current rule level stays the same, and this change does not record a new crossing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recalculate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final error = await widget.controller.changeWeeklyTarget(target!);
    if (!mounted) {
      return;
    }
    setState(() => _error = error);
  }

  Future<void> _saveRules() async {
    final error = await widget.controller.saveRules([
      for (final controller in _rules) controller.text,
    ]);
    if (!mounted) {
      return;
    }
    setState(() => _error = error);
  }

  Future<void> _newJourney() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new journey?'),
        content: const Text(
          'A new journey will begin. This journey stays available as read-only history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) =>
            SetupScreen(controller: widget.controller, popOnSuccess: true),
      ),
    );
    final journey = widget.controller.activeJourney;
    if (journey != null && mounted) {
      _target.text = _plain(journey.weeklyTargetKg);
      setState(() => _error = null);
    }
  }

  Future<void> _openPast(String journeyId) async {
    final details = await widget.controller.detailsFor(journeyId);
    if (!mounted) {
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => HistoryScreen(details: details)),
    );
  }

  Future<void> _openPastGraph(String journeyId) async {
    final details = await widget.controller.detailsFor(journeyId);
    if (!mounted) {
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => GraphScreen(details: details)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final past = widget.controller.journeys.where(
          (journey) => !journey.isActive,
        );
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Text(
                'Weekly target',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'This sets both the slope of the central line and the spacing between the five reference lines.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _target,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Target loss per week (kg)',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: widget.controller.busy ? null : _saveTarget,
                child: const Text('Update target'),
              ),
              const SizedBox(height: 32),
              Text('Rules', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'These are habits you can edit. Changing the wording does not change the active level.',
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < _rules.length; index++) ...[
                TextField(
                  controller: _rules[index],
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Level ${index + 1} — ${ruleTitles[index]}',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: widget.controller.busy ? null : _saveRules,
                child: const Text('Save rules'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 32),
              Text(
                'Previous journeys',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (past.isEmpty)
                const Text('No previous journeys.')
              else
                for (final journey in past)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Started ${formatDate(journey.startDate)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${formatKg(journey.startingWeightKg)} start  ·  Level ${journey.activeLevel}',
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => _openPast(journey.id),
                              child: const Text('History'),
                            ),
                            TextButton(
                              onPressed: () => _openPastGraph(journey.id),
                              child: const Text('Graph'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: widget.controller.busy ? null : _newJourney,
                child: const Text('Start new journey'),
              ),
            ],
          ),
        );
      },
    );
  }
}
