import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

const _grid = Color(0x12FFFFFF);

TextStyle get _axis => const TextStyle(color: AppColors.muted, fontSize: 10);

/// Linha de tendência. `values` pode ter null (dia sem registro); a linha
/// pula o buraco (igual spanGaps no site). `unit`: 'h' | 'm' | '×' | ''.
class TrendLine extends StatelessWidget {
  final List<String> labels;
  final List<double?> values;
  final Color color;
  final String unit;
  const TrendLine({
    super.key,
    required this.labels,
    required this.values,
    required this.color,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v != null) spots.add(FlSpot(i.toDouble(), v));
    }
    if (spots.isEmpty) return const _NoData();
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final step = (labels.length / 6).ceil().clamp(1, 999);

    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY <= 0 ? 1 : maxY * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 2,
              dotData: FlDotData(show: spots.length <= 18),
              belowBarData: BarAreaData(
                  show: true, color: color.withValues(alpha: 0.13)),
            ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: _grid, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (v, meta) {
                  if (v == meta.max) return const SizedBox.shrink();
                  return Text('${_short(v)}$unit', style: _axis);
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  if (i % step != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(labels[i], style: _axis),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(enabled: false),
        ),
      ),
    );
  }

  String _short(double v) =>
      v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
}

/// Barras verticais (por horário). `barColors` opcional por barra.
class Bars extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final Color color;
  final List<Color>? barColors;
  final String unit;
  const Bars({
    super.key,
    required this.labels,
    required this.values,
    required this.color,
    this.barColors,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const _NoData();
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final step = (labels.length / 7).ceil().clamp(1, 999);

    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          minY: 0,
          maxY: maxY <= 0 ? 1 : maxY * 1.2,
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: barColors != null ? barColors![i] : color,
                  width: 14,
                  borderRadius: BorderRadius.circular(5),
                ),
              ]),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: _grid, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (v, meta) {
                  if (v == meta.max) return const SizedBox.shrink();
                  return Text('${v.toStringAsFixed(0)}$unit', style: _axis);
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  if (i % step != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(labels[i], style: _axis),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(enabled: false),
        ),
      ),
    );
  }
}

/// Rosca (doughnut) com legenda ao lado.
class Donut extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final List<Color> colors;
  const Donut({
    super.key,
    required this.labels,
    required this.values,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return const _NoData();
    return SizedBox(
      height: 130,
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 32,
                sections: [
                  for (var i = 0; i < values.length; i++)
                    if (values[i] > 0)
                      PieChartSectionData(
                        value: values[i],
                        color: colors[i],
                        title: '',
                        radius: 22,
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < labels.length; i++)
                  if (values[i] > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                                color: colors[i],
                                borderRadius: BorderRadius.circular(3)),
                          ),
                          const SizedBox(width: 7),
                          Text('${labels[i]}  ${values[i].toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
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

class _NoData extends StatelessWidget {
  const _NoData();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 60,
        child: Center(
          child: Text('sem dados no período',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ),
      );
}
