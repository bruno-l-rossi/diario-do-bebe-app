import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// Linhas-guia dos gráficos, na cor da paleta ativa (clara ou escura).
Color get _grid => kP.grid;

TextStyle get _axis => TextStyle(color: AppColors.muted, fontSize: 10);

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
                FlLine(color: _grid, strokeWidth: 1),
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
                FlLine(color: _grid, strokeWidth: 1),
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
                              style: TextStyle(
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

/// Um trecho colorido numa linha de 24h (frações 0..1 do dia).
class TimelineSeg {
  final double start, end;
  final Color color;
  const TimelineSeg(this.start, this.end, this.color);
}

/// O padrão dos últimos dias num olhar: uma faixa de 24h por dia, com os
/// sonos como blocos e mamadas/refeições como tracinhos (estilo Huckleberry).
class DayTimeline extends StatelessWidget {
  final List<String> dayLabels; // de cima (mais antigo) pra baixo (hoje)
  final List<List<TimelineSeg>> rows;
  const DayTimeline({super.key, required this.dayLabels, required this.rows});

  static const _rowH = 18.0;
  static const _gap = 7.0;
  static const _labelW = 38.0;
  static const _axisH = 18.0;

  @override
  Widget build(BuildContext context) {
    if (rows.every((r) => r.isEmpty)) return const _NoData();
    final h = rows.length * (_rowH + _gap) + _axisH;
    return SizedBox(
      height: h,
      width: double.infinity,
      child: CustomPaint(
        painter: _TimelinePainter(dayLabels: dayLabels, rows: rows),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<String> dayLabels;
  final List<List<TimelineSeg>> rows;
  _TimelinePainter({required this.dayLabels, required this.rows});

  @override
  void paint(Canvas canvas, Size size) {
    const rowH = DayTimeline._rowH;
    const gap = DayTimeline._gap;
    const labelW = DayTimeline._labelW;
    final plotW = size.width - labelW;
    final plotH = rows.length * (rowH + gap);

    // linhas-guia e rótulos das horas (0h, 6h, 12h, 18h, 24h)
    final guide = Paint()
      ..color = _grid
      ..strokeWidth = 1;
    for (final h in [0, 6, 12, 18, 24]) {
      final x = labelW + plotW * (h / 24);
      canvas.drawLine(Offset(x, 0), Offset(x, plotH), guide);
      _text(canvas, h == 24 ? '24h' : '${h}h', Offset(x - 8, plotH + 3));
    }

    for (var i = 0; i < rows.length; i++) {
      final top = i * (rowH + gap);
      // trilho de fundo
      final track = Paint()..color = _grid;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(labelW, top, plotW, rowH), const Radius.circular(5)),
        track,
      );
      _text(canvas, dayLabels[i], Offset(0, top + 3));
      for (final s in rows[i]) {
        final w = ((s.end - s.start) * plotW).clamp(2.5, plotW).toDouble();
        final p = Paint()..color = s.color;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(labelW + s.start * plotW, top + 1.5, w, rowH - 3),
            const Radius.circular(4),
          ),
          p,
        );
      }
    }
  }

  void _text(Canvas canvas, String t, Offset o) {
    final tp = TextPainter(
      text: TextSpan(
          text: t,
          style: TextStyle(color: AppColors.muted, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter old) =>
      old.rows != rows || old.dayLabels != dayLabels;
}

class _NoData extends StatelessWidget {
  const _NoData();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 60,
        child: Center(
          child: Text('sem dados no período',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ),
      );
}
