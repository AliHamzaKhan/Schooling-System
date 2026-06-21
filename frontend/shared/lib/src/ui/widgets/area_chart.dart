import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// Smooth area chart with a primary→transparent gradient fill.
///
/// Uses Catmull-Rom interpolation through the provided points (per DESIGN.md
/// "fluid health journeys"). Lightweight — drawn with a CustomPainter so we
/// don't pull in a charting dependency for the design-system package.
class GlassAreaChart extends StatelessWidget {
  final List<double> points;
  final double height;
  final Color? lineColor;
  final Color? fillStart;
  final Color? fillEnd;
  final double strokeWidth;

  const GlassAreaChart({
    super.key,
    required this.points,
    this.height = 120,
    this.lineColor,
    this.fillStart,
    this.fillEnd,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _AreaChartPainter(
          points: points,
          lineColor: lineColor ?? AppColors.primary,
          fillStart: fillStart ?? AppColors.primary.withValues(alpha: 0.30),
          fillEnd: fillEnd ?? Colors.transparent,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final Color fillStart;
  final Color fillEnd;
  final double strokeWidth;

  _AreaChartPainter({
    required this.points,
    required this.lineColor,
    required this.fillStart,
    required this.fillEnd,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxV = points.reduce((a, b) => a > b ? a : b);
    final minV = points.reduce((a, b) => a < b ? a : b);
    final span = (maxV - minV).abs() < 0.0001 ? 1.0 : (maxV - minV);
    final dx = size.width / (points.length - 1);

    Offset pt(int i) => Offset(
          i * dx,
          size.height - ((points[i] - minV) / span) * (size.height - strokeWidth) - strokeWidth / 2,
        );

    final linePath = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = pt((i - 1).clamp(0, points.length - 1));
      final p1 = pt(i);
      final p2 = pt(i + 1);
      final p3 = pt((i + 2).clamp(0, points.length - 1));
      // Catmull-Rom → cubic bezier conversion (alpha = 0.5 centripetal).
      final cp1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final cp2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    // Fill area — close the path down to the bottom.
    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillStart, fillEnd],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter old) =>
      old.points != points ||
      old.lineColor != lineColor ||
      old.fillStart != fillStart ||
      old.fillEnd != fillEnd ||
      old.strokeWidth != strokeWidth;
}
