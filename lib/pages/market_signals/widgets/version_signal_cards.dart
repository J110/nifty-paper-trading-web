import 'package:flutter/material.dart';

import '../../../models/signal.dart';
import '../../../config/theme.dart';

/// Displays 3 cards side-by-side, one per model version (v5.4.2, v5.4.3, v5.4.4).
///
/// Each card shows the version label, signal type (BULL PUT / IRON CONDOR / NO TRADE),
/// size multiplier, and position size percentage. Cards are color-coded by version.
class VersionSignalCards extends StatelessWidget {
  final Map<String, VersionSignal> versionSignals;

  /// The ordered list of versions to display.
  static const _versions = ['v5.4.2', 'v5.4.3', 'v5.4.4'];

  const VersionSignalCards({
    super.key,
    required this.versionSignals,
  });

  @override
  Widget build(BuildContext context) {
    if (versionSignals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No version signals available',
              style: TextStyle(
                color: const Color(0xFF8B949E),
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: _versions.map((version) {
        final signal = versionSignals[version];
        final isLast = version == _versions.last;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: signal != null
                ? _VersionCard(version: version, signal: signal)
                : _EmptyVersionCard(version: version),
          ),
        );
      }).toList(),
    );
  }
}

class _VersionCard extends StatelessWidget {
  final String version;
  final VersionSignal signal;

  const _VersionCard({
    required this.version,
    required this.signal,
  });

  @override
  Widget build(BuildContext context) {
    final versionColor = AppTheme.versionColor(version);
    final signalColor = _signalTypeColor(signal.signal);

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF30363D)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              versionColor.withOpacity(0.08),
              const Color(0xFF161B22),
            ],
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version label with colored dot
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: versionColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  version,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: versionColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Signal type badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: signalColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _formatSignalType(signal.signal),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: signalColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Size multiplier
            _MetricRow(
              label: 'Size',
              value: '${signal.sizeMult.toStringAsFixed(1)}x',
            ),
            const SizedBox(height: 4),

            // Position size %
            _MetricRow(
              label: 'Position',
              value: '${signal.positionSizePct.toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  String _formatSignalType(String signal) {
    return signal.toUpperCase().replaceAll('_', ' ');
  }

  Color _signalTypeColor(String signal) {
    final s = signal.toLowerCase();
    if (s.contains('bull') || s.contains('put')) {
      return AppTheme.profit;
    }
    if (s.contains('iron') || s.contains('condor')) {
      return const Color(0xFFFF9800);
    }
    if (s.contains('no') || s.contains('none')) {
      return AppTheme.loss;
    }
    return AppTheme.neutral;
  }
}

class _EmptyVersionCard extends StatelessWidget {
  final String version;
  const _EmptyVersionCard({required this.version});

  @override
  Widget build(BuildContext context) {
    final versionColor = AppTheme.versionColor(version);

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: versionColor.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  version,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: versionColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'N/A',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF8B949E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: const Color(0xFF8B949E),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
