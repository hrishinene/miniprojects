import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../logic/reference_lines.dart';
import '../logic/weight_series.dart';
import '../state/app_controller.dart';
import 'format.dart';

const List<Color> _lineColors = [
  Color(0xFF1F4E79),
  Color(0xFF5B7C99),
  Color(0xFF1C1C1C),
  Color(0xFF8C5A3C),
  Color(0xFF6B3A3A),
];

const Color _averageColor = Color(0xFF1F6B4A);
const Color _officialColor = Color(0xFF8A8A8A);

enum _Span { week, month }

class GraphScreen extends StatefulWidget {
  const GraphScreen({required this.details, super.key});

  final JourneyDetails details;

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  _Span _span = _Span.week;

  @override
  Widget build(BuildContext context) {
    final journey = widget.details.journey;
    final count = _span == _Span.week ? 7 : 30;
    final series = widget.details.series;
    final visible = series.length <= count
        ? series
        : series.sublist(series.length - count);
    final level = journey.activeLevel;

    return Scaffold(
      appBar: AppBar(title: const Text('Graph')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SegmentedButton<_Span>(
            segments: const [
              ButtonSegment(value: _Span.week, label: Text('Week')),
              ButtonSegment(value: _Span.month, label: Text('Month')),
            ],
            selected: {_span},
            onSelectionChanged: (selection) {
              setState(() => _span = selection.first);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Active level $level',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 340,
            child: _TrendChart(
              journeyDetails: widget.details,
              visible: visible,
            ),
          ),
          const SizedBox(height: 16),
          _Legend(activeLevel: level),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.journeyDetails, required this.visible});

  final JourneyDetails journeyDetails;
  final List<DailyPoint> visible;

  @override
  Widget build(BuildContext context) {
    final journey = journeyDetails.journey;
    final measuredDays = {
      for (final point in visible)
        if (point.measured) point.dayIndex,
    };
    final byDay = {for (final point in visible) point.dayIndex: point};

    final officialSpots = [
      for (final point in visible)
        FlSpot(point.dayIndex.toDouble(), point.officialKg),
    ];
    final averageSpots = [
      for (final point in visible)
        FlSpot(point.dayIndex.toDouble(), point.movingAverageKg),
    ];
    final lineSpots = [
      for (var line = 1; line <= 5; line++)
        [
          for (final point in visible)
            FlSpot(
              point.dayIndex.toDouble(),
              referenceLine(
                startingWeightKg: journey.startingWeightKg,
                weeklyTargetKg: journey.weeklyTargetKg,
                dayIndex: point.dayIndex,
                lineNumber: line,
              ),
            ),
        ],
    ];

    final ys = <double>[
      for (final spot in officialSpots) spot.y,
      for (final spot in averageSpots) spot.y,
      for (final line in lineSpots)
        for (final spot in line) spot.y,
    ];
    var minY = ys.reduce((a, b) => a < b ? a : b);
    var maxY = ys.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.15).clamp(0.5, 8.0).toDouble();
    minY -= pad;
    maxY += pad;

    final minX = visible.first.dayIndex.toDouble();
    final maxX = visible.last.dayIndex.toDouble();
    final xMax = minX == maxX ? minX + 1 : maxX;
    final labelInterval = visible.length <= 8 ? 1.0 : 5.0;

    final bars = <LineChartBarData>[
      LineChartBarData(
        spots: officialSpots,
        color: _officialColor,
        barWidth: 1.5,
        dashArray: const [4, 3],
        dotData: FlDotData(
          checkToShowDot: (spot, bar) => measuredDays.contains(spot.x.round()),
        ),
      ),
      LineChartBarData(
        spots: averageSpots,
        color: _averageColor,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
      ),
      for (var index = 0; index < 5; index++)
        LineChartBarData(
          spots: lineSpots[index],
          color: _lineColors[index],
          barWidth: index + 1 == journey.activeLevel ? 3 : 1.25,
          dotData: const FlDotData(show: false),
        ),
    ];

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: xMax,
        minY: minY,
        maxY: maxY,
        lineBarsData: bars,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 11),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: labelInterval,
              getTitlesWidget: (value, meta) {
                final day = value.round();
                if ((value - day).abs() > 0.01) {
                  return const SizedBox.shrink();
                }
                final date = journey.startDate.addDays(day);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${date.day}/${date.month}',
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            maxContentWidth: 220,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) {
              if (spots.isEmpty) {
                return [];
              }
              final point = byDay[spots.first.x.round()];
              final text = point == null
                  ? ''
                  : '${formatDate(point.date)}\n'
                        'Official ${formatKg(point.officialKg)}\n'
                        '${point.measured ? 'Entered' : 'Carried forward'}\n'
                        'Average ${formatKg(point.movingAverageKg)}';
              return [
                for (var index = 0; index < spots.length; index++)
                  index == 0
                      ? LineTooltipItem(
                          text,
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        )
                      : null,
              ];
            },
          ),
        ),
      ),
      duration: Duration.zero,
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.activeLevel});

  final int activeLevel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (var line = 1; line <= 5; line++)
          _Swatch(
            color: _lineColors[line - 1],
            label: 'Line $line${line == activeLevel ? ' (active)' : ''}',
          ),
        const _Swatch(color: _averageColor, label: 'Seven-day average'),
        const _Swatch(color: _officialColor, label: 'Official weight'),
        const Text(
          'Dots are entered days. The dashed line carries the official weight forward when a day has no entry.',
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 18, height: 3, color: color),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
