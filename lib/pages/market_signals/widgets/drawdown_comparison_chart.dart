import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../models/chart_data.dart';
import '../../../providers/signals_provider.dart';
import '../../../config/theme.dart';
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';
import '../../../services/api_service.dart' show friendlyError;

/// Colors for the two lines
const _predictedColor = Color(0xFF58A6FF); // blue
const _actualColor = Color(0xFFE8833A); // orange

/// Section with period selector + chart
class DrawdownComparisonSection extends ConsumerStatefulWidget {
  const DrawdownComparisonSection({super.key});

  @override
  ConsumerState<DrawdownComparisonSection> createState() =>
      _DrawdownComparisonSectionState();
}

class _DrawdownComparisonSectionState
    extends ConsumerState<DrawdownComparisonSection> {
  static const _periods = ['3m', '6m', '1y', 'all'];
  static const _defaultPeriod = '6m';
  String _selectedPeriod = _defaultPeriod;

  String _periodLabel(String period) {
    switch (period) {
      case '3m':
        return '3M';
      case '6m':
        return '6M';
      case '1y':
        return '1Y';
      case 'all':
        return 'ALL';
      default:
        return period.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(drawdownComparisonProvider(_selectedPeriod));

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector + legend row
            Row(
              children: [
                // Period buttons
                ..._periods.map((p) {
                  final isSelected = p == _selectedPeriod;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () {
                        if (!isSelected) {
                          setState(() => _selectedPeriod = p);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1F6FEB)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1F6FEB)
                                : const Color(0xFF30363D),
                          ),
                        ),
                        child: Text(
                          _periodLabel(p),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF8B949E),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                // Legend
                _legendDot(_predictedColor, 'Predicted'),
                const SizedBox(width: 8),
                _legendDot(_actualColor, 'Actual'),
              ],
            ),
            const SizedBox(height: 10),

            // Chart
            dataAsync.when(
              loading: () => const SizedBox(
                height: 170,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (err, _) => SizedBox(
                height: 170,
                child: Center(
                  child: Text(
                    friendlyError(err),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
              ),
              data: (points) => points.length >= 2
                  ? SizedBox(
                      height: 170,
                      child: _DrawdownChart(points: points),
                    )
                  : SizedBox(
                      height: 170,
                      child: Center(
                        child: Text(
                          'Not enough prediction history yet',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8B949E), fontSize: 10),
        ),
      ],
    );
  }
}

/// The actual fl_chart LineChart with two lines
class _DrawdownChart extends StatelessWidget {
  final List<DrawdownPoint> points;

  const _DrawdownChart({required this.points});

  @override
  Widget build(BuildContext context) {
    // Build spots for predicted (always present) and actual (may be null)
    final predictedSpots = <FlSpot>[];
    final actualSolidSpots = <FlSpot>[];
    final actualDashedSpots = <FlSpot>[];

    // Find the first partial index to split actual into solid vs dashed
    int firstPartialIdx = points.length;
    for (int i = 0; i < points.length; i++) {
      if (points[i].isPartial) {
        firstPartialIdx = i;
        break;
      }
    }

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final x = i.toDouble();

      predictedSpots.add(FlSpot(x, p.predictedDrawdownPct));

      if (p.actualDrawdownPct != null) {
        if (i < firstPartialIdx) {
          actualSolidSpots.add(FlSpot(x, p.actualDrawdownPct!));
        } else {
          // Add the last solid point as the first dashed point for continuity
          if (actualDashedSpots.isEmpty && actualSolidSpots.isNotEmpty) {
            actualDashedSpots.add(actualSolidSpots.last);
          }
          actualDashedSpots.add(FlSpot(x, p.actualDrawdownPct!));
        }
      }
    }

    // Calculate Y range from all data
    final allY = <double>[
      ...predictedSpots.map((s) => s.y),
      ...actualSolidSpots.map((s) => s.y),
      ...actualDashedSpots.map((s) => s.y),
    ];
    if (allY.isEmpty) return const SizedBox.shrink();

    final minY = allY.reduce(math.min);
    final maxY = allY.reduce(math.max);
    final yPad = (maxY - minY) * 0.12;
    final effectiveMinY = minY - yPad;
    final effectiveMaxY = math.min(maxY + yPad, 1.0); // cap at +1%

    final lineBars = <LineChartBarData>[
      // Predicted drawdown (blue)
      LineChartBarData(
        spots: predictedSpots,
        isCurved: true,
        curveSmoothness: 0.2,
        color: _predictedColor,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: _predictedColor.withOpacity(0.06),
        ),
      ),
      // Actual drawdown — solid portion (orange)
      if (actualSolidSpots.isNotEmpty)
        LineChartBarData(
          spots: actualSolidSpots,
          isCurved: true,
          curveSmoothness: 0.2,
          color: _actualColor,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
      // Actual drawdown — dashed portion (partial, orange dashed)
      if (actualDashedSpots.isNotEmpty)
        LineChartBarData(
          spots: actualDashedSpots,
          isCurved: true,
          curveSmoothness: 0.2,
          color: _actualColor.withOpacity(0.5),
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [6, 4],
        ),
    ];

    // Zone threshold lines
    final thresholdLines = <HorizontalLine>[
      HorizontalLine(
        y: 0,
        color: const Color(0xFF30363D),
        strokeWidth: 0.8,
      ),
      _thresholdLine(-1.5, const Color(0xFFA5D6A7)), // Bull Full
      _thresholdLine(-2.5, const Color(0xFFFFD54F)), // Bull Half
      _thresholdLine(-3.5, const Color(0xFFFF9800)), // Iron Condor
    ];

    return LineChart(
      LineChartData(
        minY: effectiveMinY,
        maxY: effectiveMaxY,
        clipData: const FlClipData.all(),
        extraLinesData: ExtraLinesData(horizontalLines: thresholdLines),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            maxContentWidth: 160,
            getTooltipItems: (touchedSpots) {
              if (touchedSpots.isEmpty) return [];

              final idx = touchedSpots.first.x.toInt();
              if (idx < 0 || idx >= points.length) return [];

              final point = points[idx];
              final dateStr = _formatDate(point.date);
              final predStr = '${point.predictedDrawdownPct.toStringAsFixed(2)}%';
              final actStr = point.actualDrawdownPct != null
                  ? '${point.actualDrawdownPct!.toStringAsFixed(2)}%'
                  : 'n/a';
              final partialNote = point.isPartial ? ' (partial)' : '';

              // Show combined tooltip on the first (predicted) line only
              final items = <LineTooltipItem?>[];
              for (int i = 0; i < touchedSpots.length; i++) {
                if (i == 0) {
                  items.add(LineTooltipItem(
                    '$dateStr\nPred: $predStr\nActual: $actStr$partialNote',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ));
                } else {
                  items.add(null); // hide duplicate tooltips for other lines
                }
              }
              return items;
            },
          ),
          handleBuiltInTouches: true,
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calcInterval(effectiveMinY, effectiveMaxY),
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: Color(0xFF21262D),
              strokeWidth: 0.5,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)}%',
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
                // Show ~4-5 labels
                final step =
                    (points.length / 5).ceil().clamp(1, points.length);
                if (idx % step != 0 && idx != points.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatDate(points[idx].date),
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

  HorizontalLine _thresholdLine(double y, Color color) {
    return HorizontalLine(
      y: y,
      color: color.withOpacity(0.2),
      strokeWidth: 0.8,
      dashArray: [4, 4],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topRight,
        padding: const EdgeInsets.only(right: 4, bottom: 2),
        style: TextStyle(
          color: color.withOpacity(0.5),
          fontSize: 8,
        ),
        labelResolver: (_) => '${y.toStringAsFixed(1)}%',
      ),
    );
  }

  double _calcInterval(double min, double max) {
    final range = max - min;
    if (range <= 0) return 1;
    final raw = range / 4;
    final magnitude =
        math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
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

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('d MMM').format(parsed);
    } catch (_) {
      return date.length > 5 ? date.substring(date.length - 5) : date;
    }
  }
}
