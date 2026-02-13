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
///
/// The percentage value and zone label are overlaid inside the semicircle
/// area so there is no dead space above or below.
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
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Compute gauge dimensions to keep it compact
            final availableWidth = constraints.maxWidth;
            // Radius limited by half width minus label margin
            final radius = (availableWidth / 2 - 36).clamp(60.0, 160.0);
            // Total height: radius (arc) + 30 (tick labels below baseline)
            final gaugeHeight = radius + 34;

            return SizedBox(
              height: gaugeHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  // The arc + needle + ticks
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GaugePainter(
                        predictedDrawdownPct: predictedDrawdownPct,
                        zones: zones,
                      ),
                    ),
                  ),
                  // Overlay: value + zone label centred in the semicircle
                  Positioned(
                    left: 0,
                    right: 0,
                    // Place text roughly in the centre of the arc area
                    top: radius * 0.38,
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
                            border: Border.all(
                              color: _zoneColor.withOpacity(0.4),
                            ),
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
            );
          },
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
    // Radius fits width minus tick-label margin
    final radius = (size.width / 2 - 36).clamp(60.0, 160.0);
    // Center the arc at horizontal centre, baseline near the bottom
    // Leave 30 px below baseline for the bottom tick labels
    final center = Offset(size.width / 2, size.height - 30);

    _drawArcSegments(canvas, center, radius);
    _drawTicks(canvas, center, radius);
    _drawNeedle(canvas, center, radius);
    _drawCenterDot(canvas, center);
  }

  void _drawArcSegments(Canvas canvas, Offset center, double radius) {
    final arcWidth = radius * 0.18;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    if (zones.isNotEmpty) {
      final zoneRanges = _parseZoneRanges();
      double currentAngle = pi;

      for (int i = 0; i < zoneRanges.length; i++) {
        final fraction = zoneRanges[i];
        final sweepAngle = -fraction * pi;

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
      final numSegments = _fallbackColorsLeftToRight.length;
      final segmentAngle = pi / numSegments;
      for (int i = 0; i < numSegments; i++) {
        final paint = Paint()
          ..color = _fallbackColorsLeftToRight[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.18
          ..strokeCap = StrokeCap.butt;

        final startAngle = pi - (i * segmentAngle);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          -segmentAngle,
          false,
          paint,
        );
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
      return const Color(0xFFB71C1C);
    }
    return _parseHexColor(zone.color);
  }

  List<double> _parseZoneRanges() {
    if (zones.isEmpty) return List.filled(7, 1.0 / 7);

    final widths = <double>[];
    final totalRange = (maxValue - minValue).abs();

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

    final sum = widths.fold(0.0, (a, b) => a + b);
    if (sum > 0) return widths.map((w) => w / sum).toList();
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

    final maxTick = minValue.abs().toInt();
    final labelStep = maxTick > 10 ? 3 : 2;

    for (int i = 0; i <= maxTick; i++) {
      final value = -i.toDouble();
      final angle = _valueToAngle(value);

      final outerPoint = Offset(
        center.dx + (radius + 12) * cos(angle),
        center.dy + (radius + 12) * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - radius * 0.09) * cos(angle),
        center.dy + (radius - radius * 0.09) * sin(angle),
      );

      if (i % labelStep == 0) {
        canvas.drawLine(innerPoint, outerPoint, tickPaint);

        final tp = TextPainter(
          text: TextSpan(text: '${value.toInt()}%', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        final labelOffset = Offset(
          center.dx + (radius + 24) * cos(angle) - tp.width / 2,
          center.dy + (radius + 24) * sin(angle) - tp.height / 2,
        );
        tp.paint(canvas, labelOffset);
      }
    }
  }

  void _drawNeedle(Canvas canvas, Offset center, double radius) {
    final clampedValue = predictedDrawdownPct.clamp(minValue, maxValue);
    final angle = _valueToAngle(clampedValue);
    final needleLength = radius * 0.75;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final shadowTip = Offset(
      center.dx + needleLength * cos(angle) + 1,
      center.dy + needleLength * sin(angle) + 1,
    );
    canvas.drawLine(center, shadowTip, shadowPaint);

    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final tip = Offset(
      center.dx + needleLength * cos(angle),
      center.dy + needleLength * sin(angle),
    );
    canvas.drawLine(center, tip, needlePaint);

    // Arrowhead
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final arrowPath = Path();
    final perpAngle = angle + pi / 2;
    const arrowSize = 5.0;
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
    canvas.drawCircle(
      center,
      8,
      Paint()..color = const Color(0xFF30363D),
    );
    canvas.drawCircle(
      center,
      5,
      Paint()..color = const Color(0xFF58A6FF),
    );
  }

  double _valueToAngle(double value) {
    final normalized = (maxValue - value) / (maxValue - minValue);
    return pi * (1.0 - normalized);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.predictedDrawdownPct != predictedDrawdownPct ||
        oldDelegate.zones.length != zones.length;
  }
}
