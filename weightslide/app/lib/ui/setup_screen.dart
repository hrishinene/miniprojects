import 'package:flutter/material.dart';

import '../logic/validation.dart';
import '../models/local_date.dart';
import '../state/app_controller.dart';
import 'app_mark.dart';
import 'format.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({
    required this.controller,
    this.popOnSuccess = false,
    super.key,
  });

  final AppController controller;
  final bool popOnSuccess;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _weight = TextEditingController();
  final _target = TextEditingController(text: '0.5');
  late LocalDate _startDate;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDate = widget.controller.today;
  }

  @override
  void dispose() {
    _weight.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = widget.controller.today;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_startDate.year, _startDate.month, _startDate.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked == null) {
      return;
    }
    setState(() => _startDate = LocalDate.fromDateTime(picked));
  }

  Future<void> _submit() async {
    final weight = parseKilograms(_weight.text);
    final target = parseKilograms(_target.text);
    final weightError = validateWeight(weight);
    final targetError = validateWeeklyTarget(target);
    if (weightError != null || targetError != null) {
      setState(() => _error = weightError ?? targetError);
      return;
    }
    final error = await widget.controller.startJourney(
      startingWeightKg: weight!,
      startDate: _startDate,
      weeklyTargetKg: target!,
    );
    if (!mounted) {
      return;
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (widget.popOnSuccess) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startingFresh = widget.controller.activeJourney == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(startingFresh ? 'Weight Slide' : 'New journey'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          const AppMark(size: 72),
          const SizedBox(height: 20),
          Text(
            startingFresh ? 'Start a journey' : 'Start another journey',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter a starting weight, the day the journey begins, and how much weight you aim to lose each week.',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Starting weight (kg)',
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _pickDate,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Start date  ${formatDate(_startDate)}'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Target loss per week (kg)',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.controller.busy ? null : _submit,
            child: const Text('Create journey'),
          ),
        ],
      ),
    );
  }
}
