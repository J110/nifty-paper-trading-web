import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../models/recommendation.dart';
import '../../../providers/trades_provider.dart';
import '../../../services/api_service.dart' show friendlyError;
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';

/// Time filter options for recommendations.
const _timeFilters = [
  'today',
  '2d',
  '1w',
  '1m',
  '3m',
  '6m',
  '1y',
  '2y',
  'all',
];
const _timeFilterLabels = {
  'today': 'Today',
  '2d': '2D',
  '1w': '1W',
  '1m': '1M',
  '3m': '3M',
  '6m': '6M',
  '1y': '1Y',
  '2y': '2Y',
  'all': 'All',
};

/// Map a time filter key to a from_date ISO string (or null for 'all').
String? _timeFilterToFromDate(String filter) {
  if (filter == 'all') return null;
  final now = DateTime.now();
  final DateTime cutoff;
  switch (filter) {
    case 'today':
      cutoff = DateTime(now.year, now.month, now.day);
      break;
    case '2d':
      cutoff = now.subtract(const Duration(days: 1));
      break;
    case '1w':
      cutoff = now.subtract(const Duration(days: 7));
      break;
    case '1m':
      cutoff = now.subtract(const Duration(days: 30));
      break;
    case '3m':
      cutoff = now.subtract(const Duration(days: 90));
      break;
    case '6m':
      cutoff = now.subtract(const Duration(days: 180));
      break;
    case '1y':
      cutoff = now.subtract(const Duration(days: 365));
      break;
    case '2y':
      cutoff = now.subtract(const Duration(days: 730));
      break;
    default:
      return null;
  }
  return '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
}

class RecommendationsView extends ConsumerStatefulWidget {
  final String version;

  const RecommendationsView({
    super.key,
    required this.version,
  });

  @override
  ConsumerState<RecommendationsView> createState() =>
      _RecommendationsViewState();
}

class _RecommendationsViewState extends ConsumerState<RecommendationsView> {
  String _timeFilter = '1m';

  static final _dateFormat = DateFormat('d MMM yyyy');

  RecommendationsParams get _params => (
        version: widget.version,
        fromDate: _timeFilterToFromDate(_timeFilter),
        toDate: null,
      );

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(recommendationsProvider(_params));

    return asyncData.when(
      loading: () =>
          const LoadingWidget(message: 'Loading recommendations...'),
      error: (err, _) => AppErrorWidget(
        message: friendlyError(err),
        onRetry: () => ref.invalidate(recommendationsProvider(_params)),
      ),
      data: (response) => _buildContent(response),
    );
  }

  Widget _buildContent(RecommendationsResponse response) {
    final recs = response.recommendations;

    // Compute summary counts
    int bullFull = 0, bullHalf = 0, ironCondor = 0, noTrade = 0;
    for (final r in recs) {
      switch (r.signal) {
        case 'bull_full':
          bullFull++;
          break;
        case 'bull_half':
          bullHalf++;
          break;
        case 'iron_condor':
          ironCondor++;
          break;
        default:
          noTrade++;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time filter chips
          _buildTimeFilterRow(),
          const SizedBox(height: 12),

          // Summary card
          _buildSummaryCard(recs.length, bullFull, bullHalf, ironCondor,
              noTrade),
          const SizedBox(height: 14),

          // Recommendations list (newest first)
          if (recs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  'No recommendations for this period',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...recs.reversed.map((r) => _buildRecommendationCard(r)),
        ],
      ),
    );
  }

  // ── Time Filter Row ──

  Widget _buildTimeFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _timeFilters.map((f) {
          final isSelected = f == _timeFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () {
                if (!isSelected) setState(() => _timeFilter = f);
              },
              child: Container(
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
                  _timeFilterLabels[f]!,
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
      ),
    );
  }

  // ── Summary Card ──

  Widget _buildSummaryCard(int total, int bullFull, int bullHalf,
      int ironCondor, int noTrade) {
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
          Text(
            '$total Recommendations',
            style: const TextStyle(
              color: Color(0xFFC9D1D9),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _summaryChip('Bull Full', bullFull, const Color(0xFF00E676)),
              const SizedBox(width: 6),
              _summaryChip('Bull Half', bullHalf, const Color(0xFFFFD54F)),
              const SizedBox(width: 6),
              _summaryChip(
                  'Iron Condor', ironCondor, const Color(0xFFFF9800)),
              const SizedBox(width: 6),
              _summaryChip('No Trade', noTrade, const Color(0xFF8B949E)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recommendation Card ──

  Widget _buildRecommendationCard(Recommendation r) {
    final signalInfo = _signalDisplay(r.signal);
    final formattedDate = _formatDate(r.date);
    final niftyFormatted =
        NumberFormat('#,##0', 'en_IN').format(r.niftySpot);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: signalInfo.color.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Signal badge (left)
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: signalInfo.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: signal + date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: signalInfo.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        signalInfo.label,
                        style: TextStyle(
                          color: signalInfo.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (r.tradeType != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        _formatTradeType(r.tradeType!),
                        style: const TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 10,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Color(0xFF484F58),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Bottom row: details
                Row(
                  children: [
                    _detailChip(
                      'Prediction',
                      '${r.predictedDrawdownPct.toStringAsFixed(2)}%',
                      AppTheme.pnlColor(r.predictedDrawdownPct),
                    ),
                    const SizedBox(width: 8),
                    _detailChip(
                      'Size',
                      '${(r.sizeMult * 100).toStringAsFixed(0)}%',
                      null,
                    ),
                    const SizedBox(width: 8),
                    _detailChip(
                      'Nifty',
                      niftyFormatted,
                      null,
                    ),
                    const SizedBox(width: 8),
                    _detailChip(
                      'VIX',
                      r.vix.toStringAsFixed(1),
                      r.vix > 20
                          ? AppTheme.loss
                          : r.vix > 15
                              ? const Color(0xFFFFD54F)
                              : AppTheme.profit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailChip(String label, String value, Color? valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF484F58),
              fontSize: 9,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFFC9D1D9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return _dateFormat.format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  String _formatTradeType(String tradeType) {
    switch (tradeType) {
      case 'bull_put':
        return 'Bull Put Spread';
      case 'iron_condor':
        return 'Iron Condor';
      case 'bear_put_debit':
        return 'Bear Put Debit';
      default:
        return tradeType;
    }
  }

  _SignalDisplay _signalDisplay(String signal) {
    switch (signal) {
      case 'bull_full':
        return _SignalDisplay('Bull Full', const Color(0xFF00E676));
      case 'bull_half':
        return _SignalDisplay('Bull Half', const Color(0xFFFFD54F));
      case 'iron_condor':
        return _SignalDisplay('Iron Condor', const Color(0xFFFF9800));
      case 'bear_debit':
        return _SignalDisplay('Bear Debit', const Color(0xFFEF5350));
      default:
        return _SignalDisplay('No Trade', const Color(0xFF8B949E));
    }
  }
}

class _SignalDisplay {
  final String label;
  final Color color;
  _SignalDisplay(this.label, this.color);
}
