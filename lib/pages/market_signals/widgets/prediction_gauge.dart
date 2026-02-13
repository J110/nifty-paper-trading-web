import 'dart:math';
import 'package:flutter/material.dart';

import '../../../models/signal.dart';
import '../../../config/theme.dart';

/// A semicircle gauge showing predicted max drawdown.
///
/// The gauge arc spans from left (0%, bullish) to right (-8%, bearish).
/// Value and zone label are rendered as Flutter widgets overlaid on the arc.
/// The Card uses [Clip.hardEdge] so nothing leaks outside.
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
    // Fixed height that works on all screen widths.
    // Arc is drawn within this box; labels placed with Stack.
    const double boxHeight = 190;

    return Card(
      clipBehavior: Clip.hardEdge, // Prevents any paint overflow
      child: SizedBox(
        height: boxHeight,
        width: double.infinity,
        child: Stack(
          children: [
            // The gauge arc, ticks, and needle
            Positioned.fill(
              child: CustomPaint(
                painter: _GaugePainter(
                  predictedDrawdownPct: predictedDrawdownPct,
                  zones: zones,
                ),
              ),
            ),
            // Overlaid text: value + zone badge, centred in the arc
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${predictedDrawdownPct.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _valueColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _zoneColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: _zoneColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      currentZone,
                      style: TextStyle(
                        color: _zoneColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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

  Color get _valueColor {
    if (predictedDrawdownPct <= -3.5) return AppTheme.loss;
    if (predictedDrawdownPct <= -2.0) return const Color(0xFFFF9800);
    if (predictedDrawdownPct <= -1.0) return const Color(0xFFFFD54F);
    return AppTheme.profit;
  }

  Color get _zoneColor {
    for (final z in zones) {
      if (z.active) return _resolveZoneColor(z);
    }
    return AppTheme.neutral;
  }

  static Color _resolveZoneColor(Zone zone) {
    if (zone.name == 'No Trade (Bear)') {
      return const Color(0xFFB71C1C);
    }
    return _parseHexColor(zone.color);
  }

  static Color _parseHexColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}

// ---------------------------------------------------------------------------
// CustomPainter – draws the arc, tick labels, needle, and centre dot.
//
// Geometry (for a given Size):
//   - centre pivot placed 20 px above the bottom edge
//   - radius sized so the top of the arc + label padding = top edge
//   - tick labels drawn at radius + 16 (compact)
// ---------------------------------------------------------------------------
class _GaugePainter extends CustomPainter {
  final double predictedDrawdownPct;
  final List<Zone> zones;

  double get minValue => zones.length > 6 ? -15.0 : -8.0;
  static const double maxValue = 0.0;

  static const List<Color> _fallbackColorsLeftToRight = [
    Color(0xFF00E676),
    Color(0xFF66BB6A),
    Color(0xFFA5D6A7),
    Color(0xFFFFD54F),
    Color(0xFFFF9800),
    Color(0xFFB71C1C),
  ];

  _GaugePainter({
    required this.predictedDrawdownPct,
    required this.zones,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Pivot at the bottom centre, with a small bottom margin for the
    // horizontal tick labels (0%, -8%) that sit just below the baseline.
    const double bottomMargin = 20;
    final center = Offset(size.width / 2, size.height - bottomMargin);

    // Radius: fit within the box so the top of the arc plus the label
    // padding (16 px above the arc) sits at y ≈ 4.
    // topmost painted pixel ≈ center.y - radius - 16
    // We want that ≥ 0  →  radius ≤ center.y - 16
    final maxRadiusForHeight = center.dy - 16;
    final maxRadiusForWidth = size.width / 2 - 30; // 30 px side margin for labels
    final radius = min(maxRadiusForHeight, maxRadiusForWidth);

    if (radius < 30) return; // Sanity: too small to draw

    _drawArcSegments(canvas, center, radius);
    _drawTicks(canvas, center, radius);
    _drawNeedle(canvas, center, radius);
    _drawCenterDot(canvas, center);
  }

  // -- Arc segments ----------------------------------------------------------

  void _drawArcSegments(Canvas canvas, Offset center, double radius) {
    final arcWidth = radius * 0.18;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    if (zones.isNotEmpty) {
      final zoneRanges = _parseZoneRanges();
      double currentAngle = pi; // start from left (0%)

      for (int i = 0; i < zoneRanges.length; i++) {
        // Positive sweep → counterclockwise → through the TOP semicircle
        final sweepAngle = zoneRanges[i] * pi;
        final paint = Paint()
          ..color = _resolveZoneColor(zones[i])
          ..style = PaintingStyle.stroke
          ..strokeWidth = arcWidth
          ..strokeCap = StrokeCap.butt;
        canvas.drawArc(arcRect, currentAngle, sweepAngle, false, paint);
        currentAngle += sweepAngle;
      }
    } else {
      final n = _fallbackColorsLeftToRight.length;
      final seg = pi / n;
      for (int i = 0; i < n; i++) {
        final paint = Paint()
          ..color = _fallbackColorsLeftToRight[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.18
          ..strokeCap = StrokeCap.butt;
        // Positive sweep through the top
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          pi + i * seg,
          seg,
          false,
          paint,
        );
      }
    }
  }

  // -- Tick labels -----------------------------------------------------------

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    final tickPaint = Paint()
      ..color = const Color(0xFF8B949E)
      ..strokeWidth = 1.5;
    final textStyle = TextStyle(
      color: const Color(0xFF8B949E),
      fontSize: 9,
    );

    final maxTick = minValue.abs().toInt();
    final labelStep = maxTick > 10 ? 3 : 2;

    for (int i = 0; i <= maxTick; i++) {
      if (i % labelStep != 0) continue;

      final value = -i.toDouble();
      final angle = _valueToAngle(value);

      // Short tick line just outside the arc
      final inner = Offset(
        center.dx + (radius * 0.92) * cos(angle),
        center.dy + (radius * 0.92) * sin(angle),
      );
      final outer = Offset(
        center.dx + (radius + 8) * cos(angle),
        center.dy + (radius + 8) * sin(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);

      // Label
      final tp = TextPainter(
        text: TextSpan(text: '${value.toInt()}%', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final lbl = Offset(
        center.dx + (radius + 16) * cos(angle) - tp.width / 2,
        center.dy + (radius + 16) * sin(angle) - tp.height / 2,
      );
      tp.paint(canvas, lbl);
    }
  }

  // -- Needle ----------------------------------------------------------------

  void _drawNeedle(Canvas canvas, Offset center, double radius) {
    final clamped = predictedDrawdownPct.clamp(minValue, maxValue);
    final angle = _valueToAngle(clamped);
    final len = radius * 0.72;

    // Shadow
    canvas.drawLine(
      center,
      Offset(center.dx + len * cos(angle) + 1,
          center.dy + len * sin(angle) + 1),
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Needle line
    final tip = Offset(
      center.dx + len * cos(angle),
      center.dy + len * sin(angle),
    );
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Arrowhead
    final perp = angle + pi / 2;
    const aw = 5.0;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - 12 * cos(angle) + aw * cos(perp),
        tip.dy - 12 * sin(angle) + aw * sin(perp),
      )
      ..lineTo(
        tip.dx - 12 * cos(angle) - aw * cos(perp),
        tip.dy - 12 * sin(angle) - aw * sin(perp),
      )
      ..close();
    canvas.drawPath(
        path, Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  // -- Centre dot ------------------------------------------------------------

  void _drawCenterDot(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 7, Paint()..color = const Color(0xFF30363D));
    canvas.drawCircle(center, 4, Paint()..color = const Color(0xFF58A6FF));
  }

  // -- Helpers ---------------------------------------------------------------

  /// Map a value to an angle on the UPPER semicircle.
  ///   0%  (safe)    → π     (left)
  ///  -4%  (middle)  → 3π/2  (top)
  ///  -8%  (danger)  → 2π≡0  (right)
  double _valueToAngle(double value) {
    // normalized: 0 at 0% (left), 1 at minValue (right)
    final n = (maxValue - value) / (maxValue - minValue);
    return pi + n * pi; // π → 2π
  }

  List<double> _parseZoneRanges() {
    if (zones.isEmpty) return List.filled(7, 1.0 / 7);
    final widths = <double>[];
    final totalRange = (maxValue - minValue).abs();
    for (final zone in zones) {
      final parts = zone.range.split(' to ');
      if (parts.length == 2) {
        final lo =
            double.tryParse(parts[0].trim().replaceAll('%', '')) ?? 0;
        final hi =
            double.tryParse(parts[1].trim().replaceAll('%', '')) ?? 0;
        widths.add((hi - lo).abs() / totalRange);
      } else {
        widths.add(1.0 / zones.length);
      }
    }
    final s = widths.fold(0.0, (a, b) => a + b);
    if (s > 0) return widths.map((w) => w / s).toList();
    return List.filled(zones.length, 1.0 / zones.length);
  }

  static Color _parseHexColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  static Color _resolveZoneColor(Zone zone) {
    if (zone.name == 'No Trade (Bear)') {
      return const Color(0xFFB71C1C);
    }
    return _parseHexColor(zone.color);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.predictedDrawdownPct != predictedDrawdownPct ||
      oldDelegate.zones.length != zones.length;
}
