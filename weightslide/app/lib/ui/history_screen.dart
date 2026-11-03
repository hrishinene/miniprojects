import 'package:flutter/material.dart';

import '../models/local_date.dart';
import '../models/records.dart';
import '../state/app_controller.dart';
import 'format.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.details, this.controller, super.key});

  final JourneyDetails details;
  final AppController? controller;

  @override
  Widget build(BuildContext context) {
    final live = controller;
    if (live == null) {
      return _HistoryBody(details: details);
    }
    return ListenableBuilder(
      listenable: live,
      builder: (context, _) {
        return _HistoryBody(
          details: live.activeDetails ?? details,
          controller: live,
        );
      },
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.details, this.controller});

  final JourneyDetails details;
  final AppController? controller;

  bool _canRemove(LocalDate date) {
    final live = controller;
    return live != null && details.journey.isActive && date == live.today;
  }

  Future<void> _remove(BuildContext context, WeightReading reading) async {
    final live = controller;
    if (live == null) {
      return;
    }
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
    if (confirmed != true) {
      return;
    }
    await live.removeReading(reading.id);
  }

  @override
  Widget build(BuildContext context) {
    final rows = details.history.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        itemCount: rows.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final row = rows[index];
          final dayReadings = details.readingsOn(row.date);
          final canRemove = _canRemove(row.date);
          final showReadings = dayReadings.length > 1 || canRemove;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDate(row.date),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatKg(row.officialKg)}  ·  ${row.measured ? 'Entered' : 'Carried forward'}',
                ),
                Text('Three-day average  ${formatKg(row.movingAverageKg)}'),
                Text('Level ${row.activeLevel}'),
                if (showReadings && dayReadings.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  for (final reading in dayReadings)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${formatTime(reading.recordedAt)}   ${formatKg(reading.kg)}'
                            '${reading.kg == row.officialKg ? '   lowest' : ''}',
                          ),
                        ),
                        if (canRemove)
                          TextButton(
                            onPressed: controller?.busy == true
                                ? null
                                : () => _remove(context, reading),
                            child: const Text('Remove'),
                          ),
                      ],
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
