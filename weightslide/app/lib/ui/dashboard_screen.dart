import 'package:flutter/material.dart';

import '../logic/rules.dart';
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

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = await widget.controller.enterWeight(_weight.text);
    if (!mounted) {
      return;
    }
    setState(() => _error = error);
    if (error == null) {
      _weight.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.controller.activeDetails;
    if (details == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final point = details.latest;
    final todayReadings = details.readingsOn(widget.controller.today);
    final level = details.journey.activeLevel;
    final applicable = rulesForLevel(level, widget.controller.ruleTexts);
    final seeded = !point.measured && point.date == details.journey.startDate;
    final source = point.measured
        ? 'Lowest reading today'
        : seeded
        ? 'Starting weight'
        : 'Carried forward';

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
                  builder: (_) => HistoryScreen(details: details),
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
          FilledButton(
            onPressed: widget.controller.busy ? null : _submit,
            child: const Text('Save weight'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (todayReadings.length > 1) ...[
            const SizedBox(height: 16),
            Text(
              'Readings today',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final reading in todayReadings)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${formatTime(reading.recordedAt)}   ${formatKg(reading.kg)}'
                  '${reading.kg == point.officialKg ? '   lowest' : ''}',
                ),
              ),
          ],
          const SizedBox(height: 24),
          Text(
            'Seven-day average',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(formatKg(point.movingAverageKg)),
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
        ],
      ),
    );
  }
}
