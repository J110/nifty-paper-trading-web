import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/trade.dart';
import '../../models/chart_data.dart';
import '../../providers/trades_provider.dart';
import '../shared/loading_widget.dart';
import '../shared/error_widget.dart';
import 'widgets/portfolio_summary.dart';
import 'widgets/equity_curve.dart';
import 'widgets/trade_list.dart';
import 'widgets/delay_analysis_view.dart';
import 'widgets/returns_chart.dart';

class TradesPage extends ConsumerWidget {
  final String version;

  const TradesPage({super.key, required this.version});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(tradesProvider(version));
    final equityAsync = ref.watch(equityCurveProvider(version));
    final accentColor = AppTheme.versionColor(version);
    final label = AppConstants.versionLabels[version] ?? version;

    return tradesAsync.when(
      loading: () => const LoadingWidget(message: 'Loading trades...'),
      error: (err, _) => AppErrorWidget(
        message: 'Failed to load trades: $err',
        onRetry: () => ref.invalidate(tradesProvider(version)),
      ),
      data: (trades) => _TradesPageContent(
        version: version,
        label: label,
        accentColor: accentColor,
        trades: trades,
        equityAsync: equityAsync,
      ),
    );
  }
}

class _TradesPageContent extends StatefulWidget {
  final String version;
  final String label;
  final Color accentColor;
  final TradesResponse trades;
  final AsyncValue<List<EquityPoint>> equityAsync;

  const _TradesPageContent({
    required this.version,
    required this.label,
    required this.accentColor,
    required this.trades,
    required this.equityAsync,
  });

  @override
  State<_TradesPageContent> createState() => _TradesPageContentState();
}

class _TradesPageContentState extends State<_TradesPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final trades = widget.trades;

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
            Tab(text: 'Delays'),
            Tab(text: 'Returns'),
          ],
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: PortfolioSummary(
                  portfolio: trades.portfolio,
                  accentColor: widget.accentColor,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _buildEquityCurveSection(),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Open Trades tab
            trades.openTrades.isEmpty
                ? _buildEmptyState('No open trades')
                : TradeList(
                    trades: trades.openTrades,
                    isOpen: true,
                  ),
            // Closed Trades tab
            trades.closedTrades.isEmpty
                ? _buildEmptyState('No closed trades yet')
                : TradeList(
                    trades: trades.closedTrades,
                    isOpen: false,
                  ),
            // Delay Analysis tab
            DelayAnalysisView(version: widget.version),
            // Returns tab
            ReturnsChart(version: widget.version),
          ],
        ),
      ),
    );
  }

  Widget _buildEquityCurveSection() {
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
            child: widget.equityAsync.when(
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
