import 'package:flutter/material.dart';

import '../../../models/signal.dart';
import '../../../config/theme.dart';

/// A 2-column grid of indicator cards with expand/collapse.
///
/// Initially shows top 6 indicators. A "Show All" button expands to reveal
/// the full list.
class IndicatorGrid extends StatefulWidget {
  final List<Indicator> indicators;

  const IndicatorGrid({
    super.key,
    required this.indicators,
  });

  @override
  State<IndicatorGrid> createState() => _IndicatorGridState();
}

class _IndicatorGridState extends State<IndicatorGrid> {
  bool _expanded = false;
  static const int _collapsedCount = 6;

  @override
  Widget build(BuildContext context) {
    if (widget.indicators.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No indicators available',
              style: TextStyle(
                color: const Color(0xFF8B949E),
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    final visibleIndicators = _expanded
        ? widget.indicators
        : widget.indicators.take(_collapsedCount).toList();

    final hasMore = widget.indicators.length > _collapsedCount;

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.7,
          ),
          itemCount: visibleIndicators.length,
          itemBuilder: (context, index) {
            return _IndicatorCard(indicator: visibleIndicators[index]);
          },
        ),
        if (hasMore) ...[
          const SizedBox(height: 8),
          _ExpandButton(
            expanded: _expanded,
            totalCount: widget.indicators.length,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
        ],
      ],
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  final Indicator indicator;
  const _IndicatorCard({required this.indicator});

  @override
  Widget build(BuildContext context) {
    final classColor = _classificationColor(indicator.classification);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Label
            Text(
              indicator.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF8B949E),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),

            // Value
            Text(
              indicator.formattedValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),

            // Classification badge
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: classColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _capitalizeFirst(indicator.classification),
                  style: TextStyle(
                    fontSize: 11,
                    color: classColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _classificationColor(String classification) {
    switch (classification.toLowerCase()) {
      case 'bullish':
        return AppTheme.profit;
      case 'bearish':
        return AppTheme.loss;
      case 'neutral':
      default:
        return AppTheme.neutral;
    }
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _ExpandButton extends StatelessWidget {
  final bool expanded;
  final int totalCount;
  final VoidCallback onTap;

  const _ExpandButton({
    required this.expanded,
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              expanded
                  ? 'Show Less'
                  : 'Show All ($totalCount)',
              style: TextStyle(
                color: const Color(0xFF58A6FF),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 18,
              color: const Color(0xFF58A6FF),
            ),
          ],
        ),
      ),
    );
  }
}
