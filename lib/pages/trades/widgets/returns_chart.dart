import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../models/returns.dart';
import '../../../providers/trades_provider.dart';
import '../../../services/api_service.dart' show friendlyError;
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';

class ReturnsChart extends ConsumerStatefulWidget {
  final String version;
  final String dataMode; // received from parent
  final String? periodFromDate; // received from parent period selector

  const ReturnsChart({
    super.key,
    required this.version,
    this.dataMode = 'combined',
    this.periodFromDate,
  });

  @override
  ConsumerState<ReturnsChart> createState() => _ReturnsChartState();
}

class _ReturnsChartState extends ConsumerState<ReturnsChart> {
  String _period = 'weekly';

  static final _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  ReturnsParams get _params => (
        version: widget.version,
        period: _period,
        dataMode: widget.dataMode,
        fromDate: widget.periodFromDate,
        toDate: null,
      );

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(returnsProvider(_params));

    return asyncData.when(
      loading: () => const LoadingWidget(message: 'Loading returns...'),
      error: (err, _) => AppErrorWidget(
        message: friendlyError(err),
        onRetry: () => ref.invalidate(returnsProvider(_params)),
      ),
      data: (response) => _buildContent(response),
    );
  }

  Widget _buildContent(ReturnsResponse response) {
    final returns = response.returns;
    final summary = response.summary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary stats card (fresh ₹25L base for each mode)
          if (summary != null) _buildSummaryStats(summary),
          if (summary != null) const SizedBox(height: 12),

          // Period toggle row
          Row(
            children: [
              const Text(
                'Returns',
                style: TextStyle(
                  color: Color(0xFFC9D1D9),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _buildPeriodToggle(),
            ],
          ),
          const SizedBox(height: 16),

          // Bar chart
          if (returns.isNotEmpty) ...[
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              child: _buildBarChart(returns),
            ),
            const SizedBox(height: 16),

            // Period breakdown table
            _buildSummaryTable(returns),
          ],

          if (returns.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  'No returns data for this selection',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Summary Stats Card ──

  Widget _buildSummaryStats(ReturnsSummary s) {
    final pnlColor = AppTheme.pnlColor(s.totalPnl);
    final sign = s.totalPnl >= 0 ? '+' : '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // P&L headline
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${_inrFormat.format(s.totalPnl)}',
                style: TextStyle(
                  color: pnlColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: pnlColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$sign${s.totalReturnPct.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: pnlColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'on ${_inrFormat.format(s.startingCapital)}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _statItem(
                  'Win Rate',
                  '${s.winRate.toStringAsFixed(1)}%',
                  s.winRate >= 50 ? AppTheme.profit : AppTheme.loss,
                ),
                _statDivider(),
                _statItem('Trades', '${s.totalTrades}', null),
                _statDivider(),
                _statItem(
                  'PF',
                  s.profitFactor >= 999
                      ? '\u221E'
                      : s.profitFactor.toStringAsFixed(2),
                  s.profitFactor >= 1.0 ? AppTheme.profit : AppTheme.loss,
                ),
                _statDivider(),
                _statItem(
                  'Avg P&L',
                  _inrFormat.format(s.avgPnl),
                  AppTheme.pnlColor(s.avgPnl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color? valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFFC9D1D9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 24, color: const Color(0xFF30363D));
  }

  // ── Period Toggle (Weekly / Monthly) ──

  Widget _buildPeriodToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _periodButton('Weekly', 'weekly'),
          _periodButton('Monthly', 'monthly'),
        ],
      ),
    );
  }

  Widget _periodButton(String label, String value) {
    final selected = _period == value;
    return GestureDetector(
      onTap: () => setState(() => _period = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF21262D) : Colors.transparent,
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

  // ── Bar Chart ──

  Widget _buildBarChart(List<PeriodReturn> returns) {
    final maxVal = returns
        .map((r) => r.pnl.abs())
        .fold<double>(0, (a, b) => a > b ? a : b);
    final double ceiling = maxVal > 0 ? maxVal * 1.2 : 1000.0;

    // Limit visible bars to prevent overcrowding
    final visibleReturns =
        returns.length > 20 ? returns.sublist(returns.length - 20) : returns;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: ceiling,
        minY: -ceiling,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final r = visibleReturns[group.x.toInt()];
              final sign = r.pnl >= 0 ? '+' : '';
              return BarTooltipItem(
                '${r.period}\n$sign${_inrFormat.format(r.pnl)} (${r.returnPct.toStringAsFixed(2)}%)',
                const TextStyle(
                  color: Color(0xFFC9D1D9),
                  fontSize: 11,
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
                if (idx < 0 || idx >= visibleReturns.length) {
                  return const SizedBox.shrink();
                }
                // Show every Nth label to avoid overcrowding
                final step =
                    (visibleReturns.length / 6).ceil().clamp(1, 10);
                if (idx % step != 0 &&
                    idx != visibleReturns.length - 1) {
                  return const SizedBox.shrink();
                }
                final period = visibleReturns[idx].period;
                // Shorten the label
                final shortLabel = period.length > 6
                    ? period.substring(period.length - 5)
                    : period;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      shortLabel,
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 9,
                      ),
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
        barGroups: visibleReturns.asMap().entries.map((entry) {
          final idx = entry.key;
          final r = entry.value;
          final color = r.pnl >= 0 ? AppTheme.profit : AppTheme.loss;

          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: r.pnl,
                color: color,
                width: visibleReturns.length > 12 ? 12 : 20,
                borderRadius: r.pnl >= 0
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        topRight: Radius.circular(3),
                      )
                    : const BorderRadius.only(
                        bottomLeft: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Summary Table ──

  Widget _buildSummaryTable(List<PeriodReturn> returns) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF30363D)),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Period',
                    style: TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'P&L',
                    style: TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Return',
                    style: TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Trades',
                    style: TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // Table rows (show last 10)
          ...returns
              .reversed
              .take(10)
              .toList()
              .reversed
              .map((r) => _tableRow(r)),
        ],
      ),
    );
  }

  Widget _tableRow(PeriodReturn r) {
    final pnlColor = AppTheme.pnlColor(r.pnl);
    final sign = r.pnl >= 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF21262D), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              r.period,
              style: const TextStyle(
                color: Color(0xFFC9D1D9),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '$sign${_inrFormat.format(r.pnl)}',
              style: TextStyle(
                color: pnlColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$sign${r.returnPct.toStringAsFixed(2)}%',
              style: TextStyle(
                color: pnlColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${r.trades}',
              style: const TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
