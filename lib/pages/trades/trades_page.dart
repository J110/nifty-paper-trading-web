import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/trade.dart';
import '../../models/chart_data.dart';
import '../../providers/trades_provider.dart';
import '../../services/api_service.dart' show friendlyError;
import '../shared/loading_widget.dart';
import '../shared/error_widget.dart';
import 'widgets/portfolio_summary.dart';
import 'widgets/equity_curve.dart';
import 'widgets/trade_list.dart';
import 'widgets/delay_analysis_view.dart';
import 'widgets/returns_chart.dart';

/// Forward test start date (shared constant).
final forwardTestStart = DateTime(2026, 2, 11);

class TradesPage extends ConsumerWidget {
  final String version;

  const TradesPage({super.key, required this.version});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(tradesProvider(version));
    final accentColor = AppTheme.versionColor(version);
    final label = AppConstants.versionLabels[version] ?? version;

    return tradesAsync.when(
      loading: () => const LoadingWidget(message: 'Loading trades...'),
      error: (err, _) => AppErrorWidget(
        message: friendlyError(err),
        onRetry: () => ref.invalidate(tradesProvider(version)),
      ),
      data: (trades) => _TradesPageContent(
        version: version,
        label: label,
        accentColor: accentColor,
        trades: trades,
      ),
    );
  }
}

class _TradesPageContent extends ConsumerStatefulWidget {
  final String version;
  final String label;
  final Color accentColor;
  final TradesResponse trades;

  const _TradesPageContent({
    required this.version,
    required this.label,
    required this.accentColor,
    required this.trades,
  });

  @override
  ConsumerState<_TradesPageContent> createState() =>
      _TradesPageContentState();
}

class _TradesPageContentState extends ConsumerState<_TradesPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _dataMode = 'combined'; // shared across all sections

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Filter trades by data mode (backtest/forward/combined).
  List<TradeItem> _filterTrades(List<TradeItem> trades) {
    if (_dataMode == 'combined') return trades;
    return trades.where((t) {
      final entryStr = t.entryDate;
      if (entryStr == null) return true;
      final entryDt = DateTime.tryParse(entryStr);
      if (entryDt == null) return true;
      if (_dataMode == 'backtest') {
        return entryDt.isBefore(forwardTestStart);
      } else {
        return !entryDt.isBefore(forwardTestStart);
      }
    }).toList();
  }

  /// Compute portfolio stats from a filtered list of closed trades.
  Portfolio _computeFilteredPortfolio(List<TradeItem> closedTrades) {
    const startingCapital = AppConstants.initialCapital;
    final trades = closedTrades.where((t) => t.realizedPnl != null).toList();
    final totalPnl =
        trades.fold(0.0, (sum, t) => sum + (t.realizedPnl ?? 0));
    final winners = trades.where((t) => t.realizedPnl! > 0).toList();
    final losers = trades.where((t) => t.realizedPnl! < 0).toList();
    final winningPnl =
        winners.fold(0.0, (sum, t) => sum + (t.realizedPnl ?? 0));
    final losingPnl =
        losers.fold(0.0, (sum, t) => sum + (t.realizedPnl ?? 0));

    return Portfolio(
      startingCapital: startingCapital,
      currentCapital: startingCapital + totalPnl,
      totalPnl: totalPnl,
      totalReturnPct: totalPnl / startingCapital * 100,
      realizedPnl: totalPnl,
      unrealizedPnl: 0,
      deployedCapital: 0,
      availableCapital: startingCapital + totalPnl,
      openPositions: 0,
      closedPositions: trades.length,
      totalTrades: trades.length,
      winRate: trades.isNotEmpty
          ? winners.length / trades.length * 100
          : 0,
      avgPnl: trades.isNotEmpty ? totalPnl / trades.length : 0,
      profitFactor: losingPnl != 0
          ? winningPnl / losingPnl.abs()
          : (winningPnl > 0 ? 999.0 : 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trades = widget.trades;

    // Filter trades by data mode
    final filteredOpen = _filterTrades(trades.openTrades);
    final filteredClosed = _filterTrades(trades.closedTrades);

    // Compute portfolio: use API data for combined, compute client-side for filtered
    final portfolio = _dataMode == 'combined'
        ? trades.portfolio
        : _computeFilteredPortfolio(filteredClosed);

    // Equity curve with data mode
    final equityParams = (version: widget.version, dataMode: _dataMode);
    final equityAsync = ref.watch(equityCurveProvider(equityParams));

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: widget.accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.version} - ${widget.label}',
              style: const TextStyle(
                color: Color(0xFFC9D1D9),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: widget.accentColor,
          labelColor: widget.accentColor,
          unselectedLabelColor: const Color(0xFF8B949E),
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Open'),
            Tab(text: 'Closed'),
            Tab(text: 'Delay Impact'),
            Tab(text: 'Returns'),
          ],
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Data mode toggle (shared across all tabs)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildDataModeToggle(),
              ),
            ),
            // Portfolio summary (respects data mode)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: PortfolioSummary(
                  portfolio: portfolio,
                  accentColor: widget.accentColor,
                ),
              ),
            ),
            // Equity curve (respects data mode via provider)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _buildEquityCurveSection(equityAsync),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Open Trades tab
            filteredOpen.isEmpty
                ? _buildEmptyState('No open trades')
                : TradeList(
                    trades: filteredOpen,
                    isOpen: true,
                    dataMode: _dataMode,
                  ),
            // Closed Trades tab
            filteredClosed.isEmpty
                ? _buildEmptyState('No closed trades yet')
                : TradeList(
                    trades: filteredClosed,
                    isOpen: false,
                    dataMode: _dataMode,
                  ),
            // Delay Analysis tab
            DelayAnalysisView(
              version: widget.version,
              dataMode: _dataMode,
            ),
            // Returns tab
            ReturnsChart(
              version: widget.version,
              dataMode: _dataMode,
            ),
          ],
        ),
      ),
    );
  }

  // ── Data Mode Toggle (shared) ──

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
        return 'Before 11 Feb 2026';
      case 'forwardtest':
        return 'From 11 Feb 2026';
      default:
        return 'All trades';
    }
  }

  Widget _buildEquityCurveSection(AsyncValue<List<EquityPoint>> equityAsync) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Equity Curve',
            style: TextStyle(
              color: Color(0xFFC9D1D9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: equityAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Failed to load curve',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ),
              data: (points) => points.isEmpty
                  ? Center(
                      child: Text(
                        'No data yet',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : EquityCurveChart(
                      points: points,
                      lineColor: widget.accentColor,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
