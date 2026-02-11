import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/trade.dart';
import '../../providers/trades_provider.dart';
import '../../services/api_service.dart' show friendlyError;
import '../shared/loading_widget.dart';
import '../shared/error_widget.dart';
import 'widgets/trade_list.dart';
import 'widgets/returns_chart.dart';
import 'widgets/recommendations_view.dart';

/// Forward test start date (shared constant).
final forwardTestStart = DateTime(2026, 2, 11);

/// Period options for filtering backtest data range.
const _periodOptions = ['1m', '3m', '6m', '1y', '2y', 'all'];
const _periodLabels = {
  '1m': '1M',
  '3m': '3M',
  '6m': '6M',
  '1y': '1Y',
  '2y': '2Y',
  'all': 'All',
};
const _periodDays = {
  '1m': 30,
  '3m': 90,
  '6m': 180,
  '1y': 365,
  '2y': 730,
  'all': 0, // 0 = no limit
};

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
  String _backtestPeriod = 'all'; // period filter for backtest/combined modes

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

  /// Compute the cutoff date based on the selected period.
  /// Returns null if 'all' is selected (no cutoff).
  DateTime? get _periodCutoff {
    final days = _periodDays[_backtestPeriod] ?? 0;
    if (days == 0) return null;
    return DateTime.now().subtract(Duration(days: days));
  }

  /// ISO date string for the period cutoff (for API calls).
  String? get _periodFromDate {
    final cutoff = _periodCutoff;
    if (cutoff == null) return null;
    return '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
  }

  /// Filter trades by data mode (backtest/forward/combined) and period.
  List<TradeItem> _filterTrades(List<TradeItem> trades) {
    return trades.where((t) {
      final entryStr = t.entryDate;
      if (entryStr == null) return true;
      final entryDt = DateTime.tryParse(entryStr);
      if (entryDt == null) return true;

      // Data mode filter
      if (_dataMode == 'backtest' && !entryDt.isBefore(forwardTestStart)) {
        return false;
      }
      if (_dataMode == 'forwardtest' && entryDt.isBefore(forwardTestStart)) {
        return false;
      }

      // Period filter (applies to backtest and combined modes)
      if (_dataMode != 'forwardtest') {
        final cutoff = _periodCutoff;
        if (cutoff != null && entryDt.isBefore(cutoff)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final trades = widget.trades;

    // Filter trades by data mode + period
    final filteredOpen = _filterTrades(trades.openTrades);
    final filteredClosed = _filterTrades(trades.closedTrades);

    // Check which tab is active to decide what to show in the header
    // Reco tab (index 3) doesn't need data mode or period
    final currentTab = _tabController.index;

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
          onTap: (_) => setState(() {}), // rebuild to update header
          tabs: const [
            Tab(text: 'Returns'),
            Tab(text: 'Open'),
            Tab(text: 'Closed'),
            Tab(text: 'Reco'),
          ],
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          // Reco tab: no header controls
          if (currentTab == 3) return [];

          return [
            // Data mode toggle (shared across Returns, Open, Closed)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildDataModeToggle(),
              ),
            ),
            // Period selector (shown for backtest and combined modes)
            if (_dataMode != 'forwardtest')
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _buildPeriodSelector(),
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 12),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Returns tab (default)
            ReturnsChart(
              version: widget.version,
              dataMode: _dataMode,
              periodFromDate: _periodFromDate,
            ),
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
            // Recommendations tab (today only)
            RecommendationsView(
              version: widget.version,
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
        onTap: () {
          setState(() {
            _dataMode = value;
            // Reset period to 'all' when switching modes
            if (value == 'forwardtest') {
              _backtestPeriod = 'all';
            }
          });
        },
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

  // ── Period Selector ──

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        const Text(
          'Period',
          style: TextStyle(
            color: Color(0xFF8B949E),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 10),
        ..._periodOptions.map((p) {
          final isSelected = p == _backtestPeriod;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () {
                if (!isSelected) {
                  setState(() => _backtestPeriod = p);
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
                  _periodLabels[p]!,
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
      ],
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
