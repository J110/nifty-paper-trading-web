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

  const ReturnsChart({super.key, required this.version});

  @override
  ConsumerState<ReturnsChart> createState() => _ReturnsChartState();
}

class _ReturnsChartState extends ConsumerState<ReturnsChart> {
  String _period = 'weekly';
  String _dataMode = 'combined';
  String _dateRange = 'all'; // all, 3m, 6m, 1y, 2y

  static final _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  /// Compute from_date based on selected date range
  String? get _fromDate {
    if (_dateRange == 'all') return null;
    final now = DateTime.now();
    final Duration offset;
    switch (_dateRange) {
      case '3m':
        offset = const Duration(days: 90);
        break;
      case '6m':
        offset = const Duration(days: 180);
        break;
      case '1y':
        offset = const Duration(days: 365);
        break;
      case '2y':
        offset = const Duration(days: 730);
        break;
      default:
        return null;
    }
    final d = now.subtract(offset);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  ReturnsParams get _params => (
        version: widget.version,
        period: _period,
        dataMode: _dataMode,
        fromDate: _fromDate,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data mode toggle (Backtest / Forward / Combined)
          _buildDataModeToggle(),
          const SizedBox(height: 12),

          // Period + Date range row
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
          const SizedBox(height: 10),

          // Date range chips
          _buildDateRangeChips(),
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

            // Summary table
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

  // ── Data Mode Toggle (Backtest / Forward / Combined) ──

  Widget _buildDataModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          _dataModeButton('Backtest', 'backtest', const Color(0xFFE8833A)),
          _dataModeButton('Forward', 'forwardtest', const Color(0xFF58A6FF)),
          _dataModeButton('Combined', 'combined', const Color(0xFF50C878)),
        ],
      ),
    );
  }

  Widget _dataModeButton(String label, String value, Color accentColor) {
    final selected = _dataMode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _dataMode = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? accentColor.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: selected
                ? Border.all(color: accentColor.withOpacity(0.4))
                : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? accentColor : const Color(0xFF8B949E),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (selected)
                Text(
                  _dataModeSubtitle(value),
                  style: TextStyle(
                    color: accentColor.withOpacity(0.6),
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _dataModeSubtitle(String mode) {
    switch (mode) {
      case 'backtest':
        return 'Before 11 Feb 2025';
      case 'forwardtest':
        return 'From 11 Feb 2025';
      default:
        return 'All trades';
    }
  }

  // ── Date Range Chips ──

  Widget _buildDateRangeChips() {
    const ranges = ['3m', '6m', '1y', '2y', 'all'];
    final labels = {
      '3m': '3M',
      '6m': '6M',
      '1y': '1Y',
      '2y': '2Y',
      'all': 'All',
    };

    return Row(
      children: ranges.map((r) {
        final isSelected = r == _dateRange;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => setState(() => _dateRange = r),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                labels[r]!,
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
      }).toList(),
    );
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
