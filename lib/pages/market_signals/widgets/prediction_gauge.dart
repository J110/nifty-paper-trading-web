import 'dart:math';
import 'package:flutter/material.dart';

import '../../../models/signal.dart';
import '../../../config/theme.dart';

/// A semicircle gauge showing predicted max drawdown.
///
/// Layout: LEFT = 0% (green, bullish) → RIGHT = -8% or -15% (red, bearish).
/// Range adapts: -8% for 6 zones (v5.x), -15% for 7+ zones (v6.2+).
/// The needle points right for more negative (dangerous) predictions
/// and left for milder predictions.
class PredictionGauge extends StatelessWidget {
  final double predictedDrawdownPct;
  final String currentZone;
  final List<Zone> zones;

  const PredictionGauge({
    super.key,
    required this.predictedDrawdownPct,
    required this.currentZone,
    required this.zones,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // Gauge height scales with available width to prevent overflow
                final gaugeWidth = constraints.maxWidth;
                final gaugeHeight = gaugeWidth * 0.55; // semicircle aspect ratio
                return ClipRect(
                  child: SizedBox(
                    height: gaugeHeight,
                    child: CustomPaint(
                      size: Size(gaugeWidth, gaugeHeight),
                      painter: _GaugePainter(
                        predictedDrawdownPct: predictedDrawdownPct,
                        zones: zones,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Prediction value
            Text(
              '${predictedDrawdownPct.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _valueColor,
              ),
            ),
            const SizedBox(height: 4),
            // Current zone label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: _zoneColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _zoneColor.withOpacity(0.4)),
              ),
              child: Text(
                currentZone,
                style: TextStyle(
                  color: _zoneColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _valueColor {
    // More negative = more red
    if (predictedDrawdownPct <= -3.5) return AppTheme.loss;
    if (predictedDrawdownPct <= -2.0) return const Color(0xFFFF9800);
    if (predictedDrawdownPct <= -1.0) return const Color(0xFFFFD54F);
    return AppTheme.profit;
  }

  Color get _zoneColor {
    // Find active zone color
    for (final z in zones) {
      if (z.active) {
        return _resolveZoneColor(z);
      }
    }
    return AppTheme.neutral;
  }

  /// Ensure No Trade zone is always visually distinct from Iron Condor
  static Color _resolveZoneColor(Zone zone) {
    if (zone.name == 'No Trade (Bear)') {
      return const Color(0xFFB71C1C); // Material Red 900 — deep crimson
    }
    return _parseHexColor(zone.color);
  }

  static Color _parseHexColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}

class _GaugePainter extends CustomPainter {
  final double predictedDrawdownPct;
  final List<Zone> zones;

  // Gauge range adapts: 0% to -8% for 6 zones, 0% to -15% for 7+ zones
  double get minValue => zones.length > 6 ? -15.0 : -8.0;
  static const double maxValue = 0.0;

  // Fallback zone colors — drawn LEFT to RIGHT: green → red
  // Only used when zone data is empty. Normally API zone colors are used.
  static const List<Color> _fallbackColorsLeftToRight = [
    Color(0xFF00E676), // Strong Bull (bright green) — left
    Color(0xFF66BB6A), // Moderate Bull (green)
    Color(0xFFA5D6A7), // Bull Full (light green)
    Color(0xFFFFD54F), // Bull Half (yellow)
    Color(0xFFFF9800), // Iron Condor (orange)
    Color(0xFFB71C1C), // No Trade / Bear (dark red) — right
  ];

  _GaugePainter({
    required this.predictedDrawdownPct,
    required this.zones,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Reserve space: 35px top for tick labels, 10px bottom for center dot
    final center = Offset(size.width / 2, size.height - 10);
    final radius = min(size.width / 2 - 35, size.height - 45);

    _drawArcSegments(canvas, center, radius);
    _drawTicks(canvas, center, radius);
    _drawNeedle(canvas, center, radius);
    _drawCenterDot(canvas, center);
  }

  void _drawArcSegments(Canvas canvas, Offset center, double radius) {
    final arcWidth = radius * 0.18;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    if (zones.isNotEmpty) {
      // Zones from API: [Strong Bull (0%), ..., No Trade (-8%)]
      // On the gauge: 0% = left (pi), -8% = right (0)
      // So Strong Bull is drawn at left (pi) and No Trade at right (0)
      final zoneRanges = _parseZoneRanges();
      double currentAngle = pi; // Start from left (0%)

      for (int i = 0; i < zoneRanges.length; i++) {
        final fraction = zoneRanges[i];
        final sweepAngle = -fraction * pi; // Sweep towards right (0)

        // Use zone color — No Trade overridden to deep crimson for visibility
        final color = _resolveZoneColor(zones[i]);

        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = arcWidth
          ..strokeCap = StrokeCap.butt;

        canvas.drawArc(arcRect, currentAngle, sweepAngle, false, paint);
        currentAngle += sweepAngle;
      }
    } else {
      // Fallback: equal segments, green on left → red on right
      final numSegments = _fallbackColorsLeftToRight.length;
      final segmentAngle = pi / numSegments;
      for (int i = 0; i < numSegments; i++) {
        final paint = Paint()
          ..color = _fallbackColorsLeftToRight[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = arcWidth
          ..strokeCap = StrokeCap.butt;

        final startAngle = pi - (i * segmentAngle);
        canvas.drawArc(arcRect, startAngle, -segmentAngle, false, paint);
      }
    }
  }

  static Color _parseHexColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  static Color _resolveZoneColor(Zone zone) {
    if (zone.name == 'No Trade (Bear)') {
      return const Color(0xFFB71C1C); // Material Red 900 — deep crimson
    }
    return _parseHexColor(zone.color);
  }

  List<double> _parseZoneRanges() {
    if (zones.isEmpty) {
      return List.filled(7, 1.0 / 7);
    }

    final widths = <double>[];
    final totalRange = (maxValue - minValue).abs(); // 8.0 or 15.0

    for (final zone in zones) {
      final parts = zone.range.split(' to ');
      if (parts.length == 2) {
        final low = double.tryParse(parts[0].trim().replaceAll('%', '')) ?? 0;
        final high = double.tryParse(parts[1].trim().replaceAll('%', '')) ?? 0;
        widths.add((high - low).abs() / totalRange);
      } else {
        widths.add(1.0 / zones.length);
      }
    }

    // Normalize to sum to 1.0
    final sum = widths.fold(0.0, (a, b) => a + b);
    if (sum > 0) {
      return widths.map((w) => w / sum).toList();
    }
    return List.filled(zones.length, 1.0 / zones.length);
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    final tickPaint = Paint()
      ..color = const Color(0xFF8B949E)
      ..strokeWidth = 1.5;

    final textStyle = TextStyle(
      color: const Color(0xFF8B949E),
      fontSize: 10,
    );

    // Draw tick marks dynamically based on gauge range
    final maxTick = minValue.abs().toInt(); // 8 or 15
    final labelStep = maxTick > 10 ? 3 : 2; // every 3% for -15 range, every 2% for -8

    for (int i = 0; i <= maxTick; i++) {
      final value = -i.toDouble();
      final angle = _valueToAngle(value);

      final outerPoint = Offset(
        center.dx + (radius + 14) * cos(angle),
        center.dy + (radius + 14) * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - radius * 0.09) * cos(angle),
        center.dy + (radius - radius * 0.09) * sin(angle),
      );

      // Only draw tick lines at label intervals to avoid crowding on -15 range
      if (i % labelStep == 0) {
        canvas.drawLine(innerPoint, outerPoint, tickPaint);

        final tp = TextPainter(
          text: TextSpan(text: '${value.toInt()}%', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        final labelOffset = Offset(
          center.dx + (radius + 28) * cos(angle) - tp.width / 2,
          center.dy + (radius + 28) * sin(angle) - tp.height / 2,
        );
        tp.paint(canvas, labelOffset);
      }
    }
  }

  void _drawNeedle(Canvas canvas, Offset center, double radius) {
    final clampedValue = predictedDrawdownPct.clamp(minValue, maxValue);
    final angle = _valueToAngle(clampedValue);

    final needleLength = radius * 0.75;

    // Needle shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final shadowTip = Offset(
      center.dx + needleLength * cos(angle) + 1,
      center.dy + needleLength * sin(angle) + 1,
    );
    canvas.drawLine(center, shadowTip, shadowPaint);

    // Needle
    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final tip = Offset(
      center.dx + needleLength * cos(angle),
      center.dy + needleLength * sin(angle),
    );
    canvas.drawLine(center, tip, needlePaint);

    // Small arrowhead at tip
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final arrowPath = Path();
    final perpAngle = angle + pi / 2;
    final arrowSize = 5.0;
    arrowPath.moveTo(tip.dx, tip.dy);
    arrowPath.lineTo(
      tip.dx - 12 * cos(angle) + arrowSize * cos(perpAngle),
      tip.dy - 12 * sin(angle) + arrowSize * sin(perpAngle),
    );
    arrowPath.lineTo(
      tip.dx - 12 * cos(angle) - arrowSize * cos(perpAngle),
      tip.dy - 12 * sin(angle) - arrowSize * sin(perpAngle),
    );
    arrowPath.close();
    canvas.drawPath(arrowPath, arrowPaint);
  }

  void _drawCenterDot(Canvas canvas, Offset center) {
    // Outer ring
    canvas.drawCircle(
      center,
      8,
      Paint()..color = const Color(0xFF30363D),
    );
    // Inner dot
    canvas.drawCircle(
      center,
      5,
      Paint()..color = const Color(0xFF58A6FF),
    );
  }

  /// Maps a value to an angle on the semicircle.
  /// 0% (safe) -> pi (left), minValue (danger) -> 0 (right)
  double _valueToAngle(double value) {
    // normalized: 0% → 0.0 (left), minValue → 1.0 (right)
    final normalized = (maxValue - value) / (maxValue - minValue);
    return pi * (1.0 - normalized); // pi (left) .. 0 (right)
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.predictedDrawdownPct != predictedDrawdownPct ||
        oldDelegate.zones.length != zones.length;
  }
}
