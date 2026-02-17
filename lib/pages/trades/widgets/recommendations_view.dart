import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../models/recommendation.dart';
import '../../../providers/trades_provider.dart';
import '../../../services/api_service.dart' show friendlyError;
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';

class RecommendationsView extends ConsumerWidget {
  final String version;

  const RecommendationsView({
    super.key,
    required this.version,
  });

  /// Today's date as ISO string for the API (IST = UTC+5:30).
  String get _todayDate {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (
      version: version,
      fromDate: _todayDate,
      toDate: _todayDate,
    ) as RecommendationsParams;

    final asyncData = ref.watch(recommendationsProvider(params));

    return asyncData.when(
      loading: () =>
          const LoadingWidget(message: 'Loading recommendations...'),
      error: (err, _) => AppErrorWidget(
        message: friendlyError(err),
        onRetry: () => ref.invalidate(recommendationsProvider(params)),
      ),
      data: (response) => _RecommendationsContent(
        response: response,
      ),
    );
  }
}

class _RecommendationsContent extends StatelessWidget {
  final RecommendationsResponse response;

  const _RecommendationsContent({required this.response});

  static final _dateFormat = DateFormat('d MMM yyyy');
  static final _inrFormat = NumberFormat('#,##0', 'en_IN');

  @override
  Widget build(BuildContext context) {
    final recs = response.recommendations;

    if (recs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 12),
            Text(
              'No recommendations for today',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check back after market hours',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date
          Row(
            children: [
              const Text(
                "Today's Recommendation",
                style: TextStyle(
                  color: Color(0xFFC9D1D9),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(recs.first.date),
                style: const TextStyle(
                  color: Color(0xFF484F58),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Recommendation cards (should be 1 for today, but handle multiple)
          ...recs.map((r) => _buildRecommendationCard(r)),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Recommendation r) {
    final signalInfo = _signalDisplay(r.signal);
    final niftyFormatted = _inrFormat.format(r.niftySpot);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: signalInfo.color.withOpacity(0.4),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Signal badge row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: signalInfo.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  signalInfo.label,
                  style: TextStyle(
                    color: signalInfo.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (r.tradeType != null) ...[
                const SizedBox(width: 10),
                Text(
                  _formatTradeType(r.tradeType!),
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Details grid
          Row(
            children: [
              _detailTile(
                'Prediction',
                '${r.predictedDrawdownPct.toStringAsFixed(2)}%',
                AppTheme.pnlColor(r.predictedDrawdownPct),
              ),
              _detailTile(
                'Position Size',
                '${(r.sizeMult * 100).toStringAsFixed(0)}%',
                null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _detailTile(
                'Nifty Spot',
                niftyFormatted,
                null,
              ),
              _detailTile(
                'India VIX',
                r.vix.toStringAsFixed(2),
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
    );
  }

  Widget _detailTile(String label, String value, Color? valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF484F58),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFFC9D1D9),
              fontSize: 16,
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
