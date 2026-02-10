import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/signal.dart';
import '../../models/chart_data.dart';
import '../../config/theme.dart';
import '../../providers/signals_provider.dart';
import '../shared/loading_widget.dart';
import '../shared/error_widget.dart';
import 'widgets/prediction_gauge.dart';
import 'widgets/zone_breakdown.dart';
import 'widgets/indicator_grid.dart';
import 'widgets/version_signal_cards.dart';

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
        message: 'Failed to load signals: $error',
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
    final niftyChartAsync = ref.watch(niftyChartProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------ 1. Nifty Price Header ------
          _NiftyPriceHeader(signal: signal),
          const SizedBox(height: 12),

          // ------ 1b. Nifty Sparkline Chart ------
          niftyChartAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (candles) => candles.length >= 2
                ? _NiftySparkline(candles: candles)
                : const SizedBox.shrink(),
          ),
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

          // ------ 5. Key Indicators ------
          _SectionTitle(title: 'Key Indicators'),
          const SizedBox(height: 8),
          IndicatorGrid(indicators: signal.indicators),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---- Nifty Price Header ----

class _NiftyPriceHeader extends StatelessWidget {
  final SignalResponse signal;
  const _NiftyPriceHeader({required this.signal});

  @override
  Widget build(BuildContext context) {
    final spot = signal.niftySpot;
    final drawdownPct = signal.predictedDrawdownPct;
    final vix = signal.vix;
    final timestamp = signal.timestamp;

    String formattedTime = '';
    if (timestamp != null) {
      try {
        final dt = DateTime.parse(timestamp);
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

                // Daily change (predicted drawdown %)
                if (drawdownPct != null)
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
                  Text(
                    formattedTime,
                    style: TextStyle(
                      color: const Color(0xFF8B949E),
                      fontSize: 12,
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

// ---- Nifty Sparkline Chart ----

class _NiftySparkline extends StatelessWidget {
  final List<OhlcCandle> candles;
  const _NiftySparkline({required this.candles});

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nifty 50 — Last ${candles.length} days',
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
              height: 100,
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
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
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
        ),
      ),
    );
  }
}
