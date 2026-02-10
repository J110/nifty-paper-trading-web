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

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Label + info icon
              Row(
                children: [
                  Expanded(
                    child: Text(
                      indicator.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF8B949E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (indicator.description.isNotEmpty)
                    Icon(
                      Icons.info_outline,
                      size: 13,
                      color: const Color(0xFF484F58),
                    ),
                ],
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
                  Expanded(
                    child: Text(
                      _capitalizeFirst(indicator.classification),
                      style: TextStyle(
                        fontSize: 11,
                        color: classColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final classColor = _classificationColor(indicator.classification);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF30363D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title + value
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      indicator.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: classColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: classColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      indicator.formattedValue,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: classColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              if (indicator.description.isNotEmpty)
                Text(
                  indicator.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8B949E),
                  ),
                ),
              const SizedBox(height: 16),

              // Bullish/Bearish explanation
              if (indicator.bullishWhen.isNotEmpty)
                _SignalRow(
                  icon: Icons.trending_up,
                  color: AppTheme.profit,
                  label: 'Bullish',
                  description: indicator.bullishWhen,
                ),
              if (indicator.bearishWhen.isNotEmpty) ...[
                const SizedBox(height: 10),
                _SignalRow(
                  icon: Icons.trending_down,
                  color: AppTheme.loss,
                  label: 'Bearish',
                  description: indicator.bearishWhen,
                ),
              ],
              const SizedBox(height: 16),

              // Current classification
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: classColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: classColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: classColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Currently ${_capitalizeFirst(indicator.classification)}',
                      style: TextStyle(
                        color: classColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

class _SignalRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String description;

  const _SignalRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFC9D1D9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
