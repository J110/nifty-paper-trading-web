import 'package:flutter/material.dart';

import '../../../models/signal.dart';
import '../../../config/theme.dart';

/// A horizontal stacked bar showing colored zone segments with a
/// marker/arrow indicating the current prediction position.
/// Supports 6 zones (v5.x) or 7 zones (v6.2+ with bear debit tiers).
class ZoneBreakdown extends StatelessWidget {
  final double predictedDrawdownPct;
  final List<Zone> zones;
  final String currentZone;

  const ZoneBreakdown({
    super.key,
    required this.predictedDrawdownPct,
    required this.zones,
    required this.currentZone,
  });

  // Full range adapts based on zone count
  double get _minValue => zones.length > 6 ? -15.0 : -8.0;
  static const double _maxValue = 0.0;

  @override
  Widget build(BuildContext context) {
    final activeZone = zones.firstWhere(
      (z) => z.active,
      orElse: () => zones.isNotEmpty ? zones.first : _fallbackZone,
    );

    final distText = _formatDistanceText(activeZone);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Marker row
            SizedBox(
              height: 28,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final markerPos = _markerPosition(constraints.maxWidth);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: markerPos - 12,
                        bottom: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${predictedDrawdownPct.toStringAsFixed(2)}%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            CustomPaint(
                              size: const Size(10, 6),
                              painter: _ArrowPainter(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Stacked bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 28,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    final segments = _buildSegments(totalWidth);

                    return Stack(
                      children: [
                        Row(
                          children: segments,
                        ),
                        // Vertical marker line
                        Positioned(
                          left: _markerPosition(totalWidth),
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 2,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Zone labels (tappable for details)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: zones.map((zone) {
                final color = _parseHexColor(zone.color);
                final isActive = zone.active;
                return GestureDetector(
                  onTap: () => _showZoneDetail(context, zone),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? color.withOpacity(0.2)
                          : const Color(0xFF21262D),
                      borderRadius: BorderRadius.circular(4),
                      border: isActive
                          ? Border.all(color: color.withOpacity(0.6))
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          zone.name,
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive ? color : const Color(0xFF8B949E),
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.info_outline,
                          size: 10,
                          color: isActive
                              ? color.withOpacity(0.6)
                              : const Color(0xFF484F58),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Active zone description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeZone.name,
                    style: TextStyle(
                      color: _parseHexColor(activeZone.color),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _zoneDescription(activeZone.name),
                    style: const TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$distText  \u2022  Range: ${activeZone.range}',
                    style: const TextStyle(
                      color: Color(0xFF484F58),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSegments(double totalWidth) {
    if (zones.isEmpty) {
      return [
        Expanded(
          child: Container(color: AppTheme.neutral.withOpacity(0.3)),
        ),
      ];
    }

    final totalRange = (_maxValue - _minValue).abs();
    final segmentWidths = <double>[];

    for (final zone in zones) {
      final parts = zone.range.split(' to ');
      if (parts.length == 2) {
        final low = double.tryParse(parts[0].trim().replaceAll('%', '')) ?? 0;
        final high = double.tryParse(parts[1].trim().replaceAll('%', '')) ?? 0;
        segmentWidths.add((high - low).abs() / totalRange);
      } else {
        segmentWidths.add(1.0 / zones.length);
      }
    }

    // Normalize
    final sum = segmentWidths.fold(0.0, (a, b) => a + b);
    final normalized =
        sum > 0 ? segmentWidths.map((w) => w / sum).toList() : segmentWidths;

    return List.generate(zones.length, (i) {
      final color = _parseHexColor(zones[i].color);
      final isActive = zones[i].active;
      final flex = (normalized[i] * 1000).round().clamp(1, 1000);

      return Expanded(
        flex: flex,
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.5),
            border: Border(
              right: i < zones.length - 1
                  ? BorderSide(
                      color: const Color(0xFF0D1117).withOpacity(0.5),
                      width: 1,
                    )
                  : BorderSide.none,
            ),
          ),
        ),
      );
    });
  }

  double _markerPosition(double totalWidth) {
    final clamped = predictedDrawdownPct.clamp(_minValue, _maxValue);
    // 0 maps to 0 (left), -8 maps to totalWidth (right)
    final normalized = (_maxValue - clamped) / (_maxValue - _minValue);
    return (normalized * totalWidth).clamp(0.0, totalWidth);
  }

  String _formatDistanceText(Zone activeZone) {
    final dist = activeZone.distanceToBoundary.abs();
    return '${dist.toStringAsFixed(2)}% from zone boundary';
  }

  static final _fallbackZone = Zone(
    name: 'Unknown',
    range: '-5.00 to 0.00',
    color: '#8B949E',
    active: true,
    distanceToBoundary: 0,
  );

  static String _zoneDescription(String zoneName) {
    switch (zoneName) {
      case 'Strong Bull':
        return 'Model predicts near-zero drawdown. Very bullish — '
            'we sell a Bull Put Spread at full position size. '
            'Expect Nifty to stay flat or rise.';
      case 'Moderate Bull':
        return 'Mild drawdown predicted (<1%). Still bullish — '
            'we sell a Bull Put Spread at full position. '
            'Nifty may dip slightly but likely recovers.';
      case 'Bull (Full Position)':
        return 'Drawdown 1-1.5% predicted. Cautiously bullish — '
            'we sell a Bull Put Spread at full position size. '
            'This is the threshold where the model still favours upside.';
      case 'Bull (Half Position)':
        return 'Drawdown 1.5-2.5% predicted. Uncertainty rising — '
            'we sell a Bull Put Spread but at reduced (half) position size '
            'to limit risk exposure.';
      case 'Iron Condor':
        return 'Drawdown 2.5-3.5% predicted. Neutral/volatile — '
            'we sell an Iron Condor (both a put spread and call spread) '
            'to profit from sideways movement and collect premium from both sides.';
      case 'No Trade (Bear)':
        return 'Drawdown >3.5% predicted. Bearish — '
            'we stay out of the market entirely. '
            'The risk of a large move down is too high to sell premium.';
      case 'Bear Moderate':
        return 'Drawdown 3.5-9% predicted. Moderately bearish — '
            'v6.2 buys a Bear Put Debit Spread at 25% position size. '
            'Asymmetric payoff: risk the debit to profit from a crash.';
      case 'Bear Strong':
        return 'Drawdown >9% predicted. Extremely bearish — '
            'v6.2 buys a Bear Put Debit Spread at 50% position size. '
            'High-conviction crash signal with maximum bear sizing.';
      default:
        return 'Zone classification based on the model\'s predicted Nifty drawdown.';
    }
  }

  static String _zoneAction(String zoneName) {
    switch (zoneName) {
      case 'Strong Bull':
        return 'Sell Bull Put Spread \u2022 100% position';
      case 'Moderate Bull':
        return 'Sell Bull Put Spread \u2022 100% position';
      case 'Bull (Full Position)':
        return 'Sell Bull Put Spread \u2022 100% position';
      case 'Bull (Half Position)':
        return 'Sell Bull Put Spread \u2022 50% position';
      case 'Iron Condor':
        return 'Sell Iron Condor \u2022 100% position';
      case 'No Trade (Bear)':
        return 'No trade \u2022 Stay in cash';
      case 'Bear Moderate':
        return 'Buy Bear Put Debit \u2022 25% position (T2)';
      case 'Bear Strong':
        return 'Buy Bear Put Debit \u2022 50% position (T1)';
      default:
        return '';
    }
  }

  void _showZoneDetail(BuildContext context, Zone zone) {
    final color = _parseHexColor(zone.color);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF30363D),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Zone name + range badge
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  zone.name,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    zone.range,
                    style: const TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Description
            Text(
              _zoneDescription(zone.name),
              style: const TextStyle(
                color: Color(0xFFC9D1D9),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            // Action
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_circle_outline,
                      size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(
                    _zoneAction(zone.name),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (zone.active) ...[
              const SizedBox(height: 10),
              Text(
                'Currently active \u2022 ${zone.distanceToBoundary.abs().toStringAsFixed(2)}% from zone boundary',
                style: const TextStyle(
                  color: Color(0xFF484F58),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Color _parseHexColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}

/// Paints a small downward-pointing arrow for the marker.
class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
