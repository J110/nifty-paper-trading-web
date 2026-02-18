import 'package:flutter/material.dart';

import '../../../models/signal.dart';
import '../../../config/theme.dart';

/// Displays the top reasons driving the model's prediction, ranked by
/// feature importance. Each reason shows a bullish/bearish/neutral
/// classification with an importance bar.
class PredictionReasoning extends StatelessWidget {
  final List<PredictionReason> reasons;
  final String summary;

  const PredictionReasoning({
    super.key,
    required this.reasons,
    this.summary = '',
  });

  @override
  Widget build(BuildContext context) {
    if (reasons.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No reasoning available',
              style: TextStyle(
                color: const Color(0xFF8B949E),
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    final maxImportance =
        reasons.map((r) => r.importancePct).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plain-English summary narrative
            if (summary.isNotEmpty) ...[
              Text(
                summary,
                style: const TextStyle(
                  color: Color(0xFFC9D1D9),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
            ],
            // Count chips: "4 bearish · 2 bullish · 1 neutral"
            _ReasoningSummary(reasons: reasons),
            const SizedBox(height: 16),
            // Individual reason rows
            ...reasons.asMap().entries.map((entry) {
              final idx = entry.key;
              final reason = entry.value;
              return Column(
                children: [
                  _ReasonRow(reason: reason, maxImportance: maxImportance),
                  if (idx < reasons.length - 1)
                    Divider(
                      color: const Color(0xFF21262D),
                      height: 20,
                      thickness: 1,
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Summary line showing count of bullish, bearish, neutral factors.
class _ReasoningSummary extends StatelessWidget {
  final List<PredictionReason> reasons;

  const _ReasoningSummary({required this.reasons});

  @override
  Widget build(BuildContext context) {
    final bearishCount = reasons.where((r) => r.direction == 'bearish').length;
    final bullishCount = reasons.where((r) => r.direction == 'bullish').length;
    final neutralCount = reasons.where((r) => r.direction == 'neutral').length;

    return Row(
      children: [
        if (bearishCount > 0) ...[
          _CountChip(
            count: bearishCount,
            label: 'bearish',
            color: AppTheme.loss,
          ),
          const SizedBox(width: 12),
        ],
        if (bullishCount > 0) ...[
          _CountChip(
            count: bullishCount,
            label: 'bullish',
            color: AppTheme.profit,
          ),
          const SizedBox(width: 12),
        ],
        if (neutralCount > 0)
          _CountChip(
            count: neutralCount,
            label: 'neutral',
            color: AppTheme.neutral,
          ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _CountChip({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// A single reason row: dot + label + value + importance bar + reason text.
class _ReasonRow extends StatelessWidget {
  final PredictionReason reason;
  final double maxImportance;

  const _ReasonRow({required this.reason, required this.maxImportance});

  Color get _directionColor {
    switch (reason.direction) {
      case 'bullish':
        return AppTheme.profit;
      case 'bearish':
        return AppTheme.loss;
      default:
        return AppTheme.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final barFraction =
        maxImportance > 0 ? reason.importancePct / maxImportance : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: dot + label + value
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _directionColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                reason.label,
                style: const TextStyle(
                  color: Color(0xFFC9D1D9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              reason.formattedValue,
              style: TextStyle(
                color: _directionColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Importance bar
        Row(
          children: [
            const SizedBox(width: 18), // align with text after dot
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  child: LinearProgressIndicator(
                    value: barFraction,
                    backgroundColor: const Color(0xFF21262D),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _directionColor.withAlpha(180),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${reason.importancePct.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Reason text
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Text(
            reason.reason,
            style: const TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
