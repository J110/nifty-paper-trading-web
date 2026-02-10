import 'package:flutter/material.dart';

import '../../../models/signal.dart';
import '../../../config/theme.dart';

/// A horizontal stacked bar showing 6 colored zone segments with a
/// marker/arrow indicating the current prediction position.
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

  // Full range: -8% to 0%
  static const double _minValue = -8.0;
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

            // Zone labels
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: zones.map((zone) {
                final color = _parseHexColor(zone.color);
                final isActive = zone.active;
                return Container(
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
                  child: Text(
                    zone.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? color : const Color(0xFF8B949E),
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Distance text
            Text(
              distText,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF8B949E),
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

    final totalRange = (_maxValue - _minValue).abs(); // 5.0
    final segmentWidths = <double>[];

    for (final zone in zones) {
      final parts = zone.range.split(' to ');
      if (parts.length == 2) {
        final low = double.tryParse(parts[0].trim()) ?? 0;
        final high = double.tryParse(parts[1].trim()) ?? 0;
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
