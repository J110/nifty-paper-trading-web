import 'package:flutter/material.dart';

import '../../../models/activity.dart';
import '../../../config/theme.dart';

/// Timeline-style log of today's trading activity with pipeline status.
class TodayActivityLog extends StatelessWidget {
  final TodayActivity activity;
  const TodayActivityLog({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pipeline status chips
            _PipelineStatusRow(status: activity.pipelineStatus),
            const SizedBox(height: 16),

            // Event timeline
            if (activity.events.isEmpty)
              _EmptyState()
            else
              ...activity.events.map(
                (event) => _EventRow(event: event),
              ),
          ],
        ),
      ),
    );
  }
}

// ---- Pipeline Status Row ----

class _PipelineStatusRow extends StatelessWidget {
  final PipelineStatus status;
  const _PipelineStatusRow({required this.status});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _StatusChip(
          label: 'Prediction',
          done: status.predictionGenerated,
          detail: status.predictionTime,
        ),
        _StatusChip(
          label: '${status.tradesEntered} Trades',
          done: status.tradesEntered > 0,
        ),
        _StatusChip(
          label: 'Exits',
          done: status.exitsChecked,
        ),
        _StatusChip(
          label: 'EOD',
          done: status.eodProcessed,
        ),
        _StatusChip(
          label: '${status.priceSnapshots} Snaps',
          done: status.priceSnapshots > 0,
          useBlue: true,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool done;
  final String? detail;
  final bool useBlue;

  const _StatusChip({
    required this.label,
    required this.done,
    this.detail,
    this.useBlue = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = useBlue
        ? const Color(0xFF58A6FF)
        : done
            ? AppTheme.profit
            : const Color(0xFF484F58);

    return Tooltip(
      message: detail ?? '',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: done ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Empty State ----

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.schedule,
            size: 32,
            color: const Color(0xFF484F58),
          ),
          const SizedBox(height: 8),
          Text(
            'No pipeline activity yet today',
            style: TextStyle(
              color: const Color(0xFF8B949E),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Predictions run at 9:20 AM IST on weekdays',
            style: TextStyle(
              color: const Color(0xFF484F58),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Event Row ----

class _EventRow extends StatelessWidget {
  final ActivityEvent event;
  const _EventRow({required this.event});

  Color get _dotColor {
    switch (event.type) {
      case 'prediction':
        return const Color(0xFF58A6FF); // blue
      case 'trade_opened':
        return AppTheme.profit; // green
      case 'trade_closed':
        return const Color(0xFFFF9800); // orange
      case 'no_trade':
        return const Color(0xFF484F58); // grey
      default:
        return const Color(0xFF8B949E);
    }
  }

  IconData get _icon {
    switch (event.type) {
      case 'prediction':
        return Icons.insights;
      case 'trade_opened':
        return Icons.add_circle_outline;
      case 'trade_closed':
        return Icons.remove_circle_outline;
      case 'no_trade':
        return Icons.block;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _dotColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot + line
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Icon(_icon, size: 16, color: color),
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: color.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 0, 0, 8),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: color.withOpacity(0.15), width: 2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time + version row
                    Row(
                      children: [
                        Text(
                          event.time,
                          style: TextStyle(
                            fontSize: 10,
                            color: const Color(0xFF484F58),
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (event.version != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF21262D),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              event.version!,
                              style: TextStyle(
                                fontSize: 9,
                                color: const Color(0xFF8B949E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Message
                    Text(
                      event.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // Detail
                    if (event.detail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.detail,
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF8B949E),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
