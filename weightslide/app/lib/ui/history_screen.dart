import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import 'format.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.details, super.key});

  final JourneyDetails details;

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
                Text('Seven-day average  ${formatKg(row.movingAverageKg)}'),
                Text('Level ${row.activeLevel}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
