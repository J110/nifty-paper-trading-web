import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../models/chart_data.dart';

class EquityCurveChart extends StatelessWidget {
  final List<EquityPoint> points;
  final Color lineColor;
  final List<EquityPoint>? benchmarkPoints;

  const EquityCurveChart({
    super.key,
    required this.points,
    required this.lineColor,
    this.benchmarkPoints,
  });

  static final _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          'No equity data',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      );
    }

    final spots = _toSpots(points);
    final minY = spots.map((s) => s.y).reduce(math.min);
    final maxY = spots.map((s) => s.y).reduce(math.max);
    final yPadding = (maxY - minY) * 0.1;
    final effectiveMinY = minY - yPadding;
    final effectiveMaxY = maxY + yPadding;

    final List<LineChartBarData> lineBars = [
      // Main equity line
      LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.2,
        color: lineColor,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: lineColor.withOpacity(0.08),
        ),
      ),
    ];

    // Optional benchmark overlay
    if (benchmarkPoints != null && benchmarkPoints!.isNotEmpty) {
      final benchSpots = _toSpots(benchmarkPoints!);
      lineBars.add(
        LineChartBarData(
          spots: benchSpots,
          isCurved: true,
          curveSmoothness: 0.2,
          color: const Color(0xFF484F58),
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [6, 4],
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: effectiveMinY,
        maxY: effectiveMaxY,
        clipData: const FlClipData.all(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final point =
                    idx < points.length ? points[idx] : null;
                final dateLabel = point?.date ?? '';
                return LineTooltipItem(
                  '$dateLabel\n${_inrFormat.format(spot.y)}',
                  TextStyle(
                    color: spot.barIndex == 0
                        ? lineColor
                        : const Color(0xFF8B949E),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calcInterval(effectiveMinY, effectiveMaxY),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: const Color(0xFF21262D),
              strokeWidth: 0.5,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                // Abbreviate large numbers
                final display = _abbreviate(value);
                return Text(
                  display,
                  style: const TextStyle(
                    color: Color(0xFF484F58),
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) {
                  return const SizedBox.shrink();
                }
                // Show ~4 labels
                final step =
                    (points.length / 4).ceil().clamp(1, points.length);
                if (idx % step != 0 && idx != points.length - 1) {
                  return const SizedBox.shrink();
                }
                final date = points[idx].date;
                // Try to parse and format date
                final shortDate = _formatDateLabel(date);
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    shortDate,
                    style: const TextStyle(
                      color: Color(0xFF484F58),
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: lineBars,
      ),
    );
  }

  List<FlSpot> _toSpots(List<EquityPoint> pts) {
    return pts.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.capital);
    }).toList();
  }

  double _calcInterval(double min, double max) {
    final range = max - min;
    if (range <= 0) return 1;
    // Aim for 3-4 grid lines
    final raw = range / 4;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor());
    final normalized = raw / magnitude;
    double nice;
    if (normalized <= 1.5) {
      nice = 1;
    } else if (normalized <= 3.5) {
      nice = 2;
    } else if (normalized <= 7.5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * magnitude;
  }

  String _abbreviate(double value) {
    final abs = value.abs();
    if (abs >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (abs >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _formatDateLabel(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('d MMM').format(parsed);
    } catch (_) {
      // If parsing fails, just return last 5 chars
      return date.length > 5 ? date.substring(date.length - 5) : date;
    }
  }
}
