import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/signal.dart';
import '../../models/chart_data.dart';
import '../../config/theme.dart';
import '../../providers/signals_provider.dart';
import '../../services/api_service.dart' show friendlyError;
import '../shared/loading_widget.dart';
import '../shared/error_widget.dart';
import 'widgets/prediction_gauge.dart';
import 'widgets/zone_breakdown.dart';
import 'widgets/indicator_grid.dart';
import 'widgets/version_signal_cards.dart';
import 'widgets/drawdown_comparison_chart.dart';
import 'widgets/activity_log.dart';
import 'widgets/prediction_reasoning.dart';

/// Formats a number using Indian numbering system (e.g., 25,00,000).
String formatIndianCurrency(double value) {
  if (value < 0) {
    return '-${formatIndianCurrency(-value)}';
  }

  final parts = value.toStringAsFixed(2).split('.');
  final intPart = parts[0];
  final decPart = parts[1];

  if (intPart.length <= 3) {
    return '\u20B9$intPart.$decPart';
  }

  // Last 3 digits
  final last3 = intPart.substring(intPart.length - 3);
  var remaining = intPart.substring(0, intPart.length - 3);

  // Group remaining digits in pairs from right
  final buffer = StringBuffer();
  while (remaining.length > 2) {
    buffer.write('${remaining.substring(0, remaining.length - 2)},');
    remaining = remaining.substring(remaining.length - 2);
  }

  // Rebuild: if buffer is empty, remaining is the leading group
  final String grouped;
  if (buffer.isEmpty) {
    grouped = '$remaining,$last3';
  } else {
    // buffer has groups like "25," for 25,00,000
    // remaining has the last 2-digit group
    final raw = buffer.toString(); // e.g. "25," or "1,25,"
    grouped = '$raw$remaining,$last3';
  }

  return '\u20B9$grouped.$decPart';
}

class MarketSignalsPage extends ConsumerWidget {
  const MarketSignalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signalsAsync = ref.watch(signalsAutoRefreshProvider);

    return signalsAsync.when(
      loading: () => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            4,
            (_) => const ShimmerCard(height: 140),
          ),
        ),
      ),
      error: (error, _) => AppErrorWidget(
        message: friendlyError(error),
        onRetry: () => ref.invalidate(signalsAutoRefreshProvider),
      ),
      data: (signal) => _SignalsContent(signal: signal),
    );
  }
}

class _SignalsContent extends ConsumerWidget {
  final SignalResponse signal;
  const _SignalsContent({required this.signal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: const Color(0xFF58A6FF),
      backgroundColor: const Color(0xFF161B22),
      onRefresh: () async {
        ref.invalidate(signalsAutoRefreshProvider);
        ref.invalidate(todayActivityProvider);
        ref.invalidate(niftyChartProvider);
        ref.invalidate(drawdownComparisonProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------ 1. Nifty Price Header ------
            _NiftyPriceHeader(
              signal: signal,
              onRefresh: () {
                ref.invalidate(signalsAutoRefreshProvider);
                ref.invalidate(todayActivityProvider);
                ref.invalidate(niftyChartProvider);
                ref.invalidate(drawdownComparisonProvider);
              },
            ),
          const SizedBox(height: 12),

          // ------ 1b. Nifty Sparkline Chart with Period Selector ------
          const _NiftyChartSection(),
          const SizedBox(height: 20),

          // ------ 1c. Predicted vs Actual Drawdown ------
          _SectionTitle(title: 'Model Accuracy'),
          const SizedBox(height: 8),
          const DrawdownComparisonSection(),
          const SizedBox(height: 20),

          // ------ 2. Model Prediction ------
          _SectionTitle(title: 'Model Prediction'),
          const SizedBox(height: 8),
          if (signal.classification != null)
            PredictionGauge(
              predictedDrawdownPct: signal.classification!.predictedDrawdown,
              currentZone: signal.classification!.currentZone,
              zones: signal.classification!.zones,
            )
          else
            const _EmptyCard(message: 'No prediction available'),
          const SizedBox(height: 24),

          // ------ 2b. Prediction Reasoning ------
          if (signal.predictionReasons.isNotEmpty) ...[
            _SectionTitle(title: 'Prediction Reasoning'),
            const SizedBox(height: 8),
            PredictionReasoning(
              reasons: signal.predictionReasons,
              summary: signal.predictionSummary,
            ),
            const SizedBox(height: 24),
          ],

          // ------ 3. Zone Breakdown ------
          _SectionTitle(title: 'Zone Breakdown'),
          const SizedBox(height: 8),
          if (signal.classification != null)
            ZoneBreakdown(
              predictedDrawdownPct: signal.classification!.predictedDrawdown,
              zones: signal.classification!.zones,
              currentZone: signal.classification!.currentZone,
            )
          else
            const _EmptyCard(message: 'No zone data'),
          const SizedBox(height: 24),

          // ------ 4. Version Signals ------
          _SectionTitle(title: 'Version Signals'),
          const SizedBox(height: 8),
          VersionSignalCards(
            versionSignals: signal.versionSignals,
          ),
          const SizedBox(height: 24),

          // ------ 4b. Today's Activity ------
          _SectionTitle(title: "Today's Activity"),
          const SizedBox(height: 8),
          const _TodayActivitySection(),
          const SizedBox(height: 24),

          // ------ 5. Key Indicators ------
          _SectionTitle(title: 'Key Indicators'),
          const SizedBox(height: 8),
          IndicatorGrid(indicators: signal.indicators),
          const SizedBox(height: 24),
        ],
      ),
      ),
    );
  }
}

// ---- Today's Activity Section ----

class _TodayActivitySection extends ConsumerWidget {
  const _TodayActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(todayActivityProvider);

    return activityAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (err, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Unable to load activity',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
      ),
      data: (activity) => TodayActivityLog(activity: activity),
    );
  }
}

// ---- Nifty Price Header ----

class _NiftyPriceHeader extends StatelessWidget {
  final SignalResponse signal;
  final VoidCallback? onRefresh;
  const _NiftyPriceHeader({required this.signal, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final spot = signal.niftySpot;
    final drawdownPct = signal.predictedDrawdownPct;
    final vix = signal.vix;
    final timestamp = signal.timestamp;

    String formattedTime = '';
    if (timestamp != null) {
      try {
        final dt = DateTime.parse(timestamp).toLocal();
        formattedTime = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (_) {
        formattedTime = timestamp;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Spot price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NIFTY 50',
                      style: TextStyle(
                        color: const Color(0xFF8B949E),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spot != null
                          ? formatIndianCurrency(spot)
                          : '--',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                // Predicted drawdown badge with label
                if (drawdownPct != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Predicted Drawdown',
                        style: TextStyle(
                          color: const Color(0xFF8B949E),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.pnlColor(drawdownPct).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              drawdownPct >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                              color: AppTheme.pnlColor(drawdownPct),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${drawdownPct >= 0 ? '+' : ''}${drawdownPct.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: AppTheme.pnlColor(drawdownPct),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // VIX and timestamp row
            Row(
              children: [
                if (vix != null) ...[
                  _InfoChip(
                    label: 'VIX',
                    value: vix.toStringAsFixed(2),
                    color: vix > 20
                        ? AppTheme.loss
                        : vix > 15
                            ? const Color(0xFFFFD54F)
                            : AppTheme.profit,
                  ),
                  const SizedBox(width: 12),
                ],
                if (formattedTime.isNotEmpty)
                  Expanded(
                    child: Text(
                      'Prediction made at $formattedTime',
                      style: TextStyle(
                        color: const Color(0xFF8B949E),
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (onRefresh != null)
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh, size: 18),
                      color: const Color(0xFF8B949E),
                      tooltip: 'Refresh data',
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: const Color(0xFF8B949E),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Section Title ----

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFFC9D1D9),
      ),
    );
  }
}

// ---- Empty Card Placeholder ----

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              color: const Color(0xFF8B949E),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Nifty Chart Section with Period Selector ----

class _NiftyChartSection extends ConsumerStatefulWidget {
  const _NiftyChartSection();

  @override
  ConsumerState<_NiftyChartSection> createState() => _NiftyChartSectionState();
}

class _NiftyChartSectionState extends ConsumerState<_NiftyChartSection> {
  static const _periods = ['1d', '5d', '1m', '3m', '6m', '1y', '2y', '3y', '5y'];
  static const _defaultPeriod = '3m';
  String _selectedPeriod = _defaultPeriod;

  String _periodLabel(String period) {
    switch (period) {
      case '1d': return '1D';
      case '5d': return '5D';
      case '1m': return '1M';
      case '3m': return '3M';
      case '6m': return '6M';
      case '1y': return '1Y';
      case '2y': return '2Y';
      case '3y': return '3Y';
      case '5y': return '5Y';
      default: return period.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartAsync = ref.watch(niftyChartProvider(_selectedPeriod));

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector row
            SizedBox(
              height: 30,
              child: Row(
                children: _periods.map((p) {
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF8B949E),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Chart content
            chartAsync.when(
              loading: () => const SizedBox(
                height: 108,
                child: Center(
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (err, _) => SizedBox(
                height: 108,
                child: Center(
                  child: Text(
                    'Unable to load chart',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
              ),
              data: (candles) => candles.length >= 2
                  ? _NiftySparkline(candles: candles, periodLabel: _periodLabel(_selectedPeriod))
                  : SizedBox(
                      height: 108,
                      child: Center(
                        child: Text(
                          'No data for $_selectedPeriod period',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Nifty Sparkline Chart ----

class _NiftySparkline extends StatelessWidget {
  final List<OhlcCandle> candles;
  final String periodLabel;
  const _NiftySparkline({required this.candles, required this.periodLabel});

  double _calcPriceInterval(double min, double max) {
    final range = max - min;
    if (range <= 0) return 100;
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

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) return const SizedBox.shrink();

    final firstClose = candles.first.close;
    final lastClose = candles.last.close;
    final changePct = firstClose > 0
        ? ((lastClose - firstClose) / firstClose) * 100
        : 0.0;
    final isPositive = changePct >= 0;
    final lineColor = isPositive ? AppTheme.profit : AppTheme.loss;

    final spots = candles.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.close);
    }).toList();

    final minY = spots.map((s) => s.y).reduce(math.min);
    final maxY = spots.map((s) => s.y).reduce(math.max);
    final yPad = (maxY - minY) * 0.05;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nifty 50 — $periodLabel  (${candles.length} pts)',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF8B949E),
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: lineColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${isPositive ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: lineColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 130,
          child: LineChart(
            LineChartData(
              minY: minY - yPad,
              maxY: maxY + yPad,
              clipData: const FlClipData.all(),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final idx = spot.x.toInt();
                      final candle = idx < candles.length
                          ? candles[idx]
                          : null;
                      String label = '';
                      if (candle != null) {
                        try {
                          final dt =
                              DateTime.parse(candle.timestamp);
                          label =
                              '${DateFormat('d MMM').format(dt)}\n';
                        } catch (_) {}
                      }
                      return LineTooltipItem(
                        '$label${NumberFormat('#,##0', 'en_IN').format(spot.y)}',
                        TextStyle(
                          color: lineColor,
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
                horizontalInterval:
                    _calcPriceInterval(minY - yPad, maxY + yPad),
                getDrawingHorizontalLine: (value) {
                  return const FlLine(
                    color: Color(0xFF21262D),
                    strokeWidth: 0.5,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat('#,##0', 'en_IN').format(value),
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
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= candles.length) {
                        return const SizedBox.shrink();
                      }
                      // Show ~4-5 labels evenly spaced
                      final step =
                          (candles.length / 5).ceil().clamp(1, candles.length);
                      if (idx % step != 0 && idx != candles.length - 1) {
                        return const SizedBox.shrink();
                      }
                      try {
                        final dt = DateTime.parse(candles[idx].timestamp);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('d MMM').format(dt),
                            style: const TextStyle(
                              color: Color(0xFF484F58),
                              fontSize: 9,
                            ),
                          ),
                        );
                      } catch (_) {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  color: lineColor,
                  barWidth: 1.8,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: lineColor.withOpacity(0.06),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
