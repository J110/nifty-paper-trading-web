import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../models/delay_analysis.dart';
import '../../../providers/trades_provider.dart';
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';

class DelayAnalysisView extends ConsumerStatefulWidget {
  final String version;

  const DelayAnalysisView({super.key, required this.version});

  @override
  ConsumerState<DelayAnalysisView> createState() => _DelayAnalysisViewState();
}

class _DelayAnalysisViewState extends ConsumerState<DelayAnalysisView> {
  bool _showPerTrade = false;

  static final _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(delayAnalysisProvider(widget.version));
    final accentColor = AppTheme.versionColor(widget.version);

    return asyncData.when(
      loading: () => const LoadingWidget(message: 'Loading delay analysis...'),
      error: (err, _) => AppErrorWidget(
        message: 'Failed to load delay analysis: $err',
        onRetry: () =>
            ref.invalidate(delayAnalysisProvider(widget.version)),
      ),
      data: (response) =>
          _buildContent(response.analysis, accentColor),
    );
  }

  Widget _buildContent(DelayAnalysis analysis, Color accentColor) {
    final buckets = analysis.buckets;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle and best delay header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Best: ${analysis.bestDelay}',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              _buildToggle(),
            ],
          ),
          const SizedBox(height: 16),

          // Aggregate bar chart
          if (!_showPerTrade) ...[
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
              child: _buildBarChart(buckets, accentColor),
            ),
            const SizedBox(height: 12),

            // Delta labels between buckets
            _buildDeltaRow(buckets),
          ],

          // Per-trade view
          if (_showPerTrade) ...[
            ...analysis.perTrade.map((tradeData) {
              final tradeId = tradeData['trade_id'] ?? '?';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trade: $tradeId',
                      style: const TextStyle(
                        color: Color(0xFFC9D1D9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _perTradeChip(
                          'Immediate',
                          tradeData['immediate_pnl'],
                        ),
                        _perTradeChip('10min', tradeData['10min_pnl']),
                        _perTradeChip('1hr', tradeData['1hr_pnl']),
                        _perTradeChip('3hr', tradeData['3hr_pnl']),
                        _perTradeChip('6hr', tradeData['6hr_pnl']),
                        _perTradeChip('12hr', tradeData['12hr_pnl']),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton('Aggregate', !_showPerTrade, () {
            setState(() => _showPerTrade = false);
          }),
          _toggleButton('Per Trade', _showPerTrade, () {
            setState(() => _showPerTrade = true);
          }),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF21262D)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(0xFFC9D1D9)
                : const Color(0xFF8B949E),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<DelayBucketEntry> buckets, Color accentColor) {
    final maxPnl = buckets
        .map((b) => b.bucket.totalPnl.abs())
        .fold<double>(0, (a, b) => a > b ? a : b);
    final ceiling = maxPnl > 0 ? maxPnl * 1.2 : 1000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: ceiling,
        minY: -ceiling,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final bucket = buckets[group.x.toInt()];
              return BarTooltipItem(
                '${bucket.label}\n${_inrFormat.format(bucket.bucket.totalPnl)}',
                const TextStyle(
                  color: Color(0xFFC9D1D9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
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
              reservedSize: 52,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const Text(
                    '0',
                    style: TextStyle(
                      color: Color(0xFF484F58),
                      fontSize: 10,
                    ),
                  );
                }
                return Text(
                  _inrFormat.format(value),
                  style: const TextStyle(
                    color: Color(0xFF484F58),
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= buckets.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    buckets[idx].label,
                    style: const TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ceiling / 3,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: const Color(0xFF21262D),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: buckets.asMap().entries.map((entry) {
          final idx = entry.key;
          final bucket = entry.value;
          final pnl = bucket.bucket.totalPnl;
          final barColor = pnl >= 0 ? AppTheme.profit : AppTheme.loss;

          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: pnl,
                color: barColor,
                width: 28,
                borderRadius: pnl >= 0
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      )
                    : const BorderRadius.only(
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeltaRow(List<DelayBucketEntry> buckets) {
    if (buckets.length < 2) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'P&L Delta vs Immediate',
            style: TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: buckets.skip(1).map((b) {
              final delta = b.bucket.pnlDelta;
              final sign = delta >= 0 ? '+' : '';
              final color = AppTheme.pnlColor(delta);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${b.label}: $sign${_inrFormat.format(delta)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _perTradeChip(String label, dynamic pnlValue) {
    final pnl = (pnlValue as num?)?.toDouble() ?? 0;
    final color = AppTheme.pnlColor(pnl);
    final sign = pnl >= 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $sign${_inrFormat.format(pnl)}',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
