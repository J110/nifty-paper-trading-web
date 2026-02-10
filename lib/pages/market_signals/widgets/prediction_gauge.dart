import 'dart:math';
import 'package:flutter/material.dart';

import '../../../models/signal.dart';
import '../../../config/theme.dart';

/// A semicircle gauge showing predicted max drawdown.
///
/// Layout: LEFT = 0% (green, bullish) → RIGHT = -8% (red, bearish).
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
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: CustomPaint(
                size: const Size(double.infinity, 180),
                painter: _GaugePainter(
                  predictedDrawdownPct: predictedDrawdownPct,
                  zones: zones,
                ),
              ),
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
        return _parseHexColor(z.color);
      }
    }
    return AppTheme.neutral;
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

  // Gauge range: 0% (safe, left) to -8% (danger, right)
  static const double minValue = -8.0; // rightmost (most bearish)
  static const double maxValue = 0.0;  // leftmost (most bullish)

  // Zone colors — drawn LEFT to RIGHT: green → red
  // Reversed from the API order so green is on the left (0%) and red on the right (-8%)
  static const List<Color> _zoneColorsLeftToRight = [
    Color(0xFF00E676), // Strong Bull (bright green) — left
    Color(0xFF66BB6A), // Moderate Bull (green)
    Color(0xFFA5D6A7), // Bull Full (light green)
    Color(0xFFFFD54F), // Bull Half (yellow)
    Color(0xFFFF9800), // Iron Condor (orange)
    Color(0xFFEF5350), // No Trade (red) — right
  ];

  _GaugePainter({
    required this.predictedDrawdownPct,
    required this.zones,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = min(size.width / 2 - 20, size.height - 30);

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

        final color = i < _zoneColorsLeftToRight.length
            ? _zoneColorsLeftToRight[i]
            : Colors.grey;

        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = arcWidth
          ..strokeCap = StrokeCap.butt;

        canvas.drawArc(arcRect, currentAngle, sweepAngle, false, paint);
        currentAngle += sweepAngle;
      }
    } else {
      // Fallback: 6 equal segments, green on left → red on right
      final segmentAngle = pi / 6;
      for (int i = 0; i < 6; i++) {
        final paint = Paint()
          ..color = _zoneColorsLeftToRight[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = arcWidth
          ..strokeCap = StrokeCap.butt;

        final startAngle = pi - (i * segmentAngle);
        canvas.drawArc(arcRect, startAngle, -segmentAngle, false, paint);
      }
    }
  }

  List<double> _parseZoneRanges() {
    if (zones.isEmpty) {
      return List.filled(6, 1.0 / 6);
    }

    final widths = <double>[];
    final totalRange = (maxValue - minValue).abs(); // 8.0

    for (final zone in zones) {
      final parts = zone.range.split(' to ');
      if (parts.length == 2) {
        final low = double.tryParse(parts[0].trim()) ?? 0;
        final high = double.tryParse(parts[1].trim()) ?? 0;
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

    // Draw tick marks at 0, -1, -2, ..., -8
    for (int i = 0; i <= 8; i++) {
      final value = -i.toDouble(); // 0, -1, -2, ..., -8
      final angle = _valueToAngle(value);

      final outerPoint = Offset(
        center.dx + (radius + 14) * cos(angle),
        center.dy + (radius + 14) * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - radius * 0.09) * cos(angle),
        center.dy + (radius - radius * 0.09) * sin(angle),
      );

      canvas.drawLine(innerPoint, outerPoint, tickPaint);

      // Label — only show every 2% to avoid crowding
      if (i % 2 == 0) {
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
  /// 0% (safe) -> pi (left), -8% (danger) -> 0 (right)
  double _valueToAngle(double value) {
    // normalized: 0% → 0.0 (left), -8% → 1.0 (right)
    final normalized = (maxValue - value) / (maxValue - minValue);
    return pi * (1.0 - normalized); // pi (left) .. 0 (right)
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.predictedDrawdownPct != predictedDrawdownPct;
  }
}
