import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// A named series for [PortalMultiLineChart].
class LineSeries {
  final List<double> points;
  final Color color;
  final String label;
  final bool fill;

  const LineSeries({
    required this.points,
    required this.color,
    required this.label,
    this.fill = true,
  });
}

/// Smooth multi-series area/line chart with x-axis labels and a horizontal
/// grid. Pure CustomPainter — no chart deps.
class PortalMultiLineChart extends StatelessWidget {
  final List<LineSeries> series;
  final List<String> xLabels;
  final double height;

  const PortalMultiLineChart({
    super.key,
    required this.series,
    required this.xLabels,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _Painter(series: series, xLabels: xLabels)),
    );
  }
}

class _Painter extends CustomPainter {
  final List<LineSeries> series;
  final List<String> xLabels;
  _Painter({required this.series, required this.xLabels});

  static const double _bottomPad = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final chartH = size.height - _bottomPad;
    double maxV = 1;
    for (final s in series) {
      for (final p in s.points) {
        if (p > maxV) maxV = p;
      }
    }

    final grid = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = chartH - (i / 3) * chartH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (final s in series) {
      if (s.points.length < 2) continue;
      final dx = size.width / (s.points.length - 1);
      Offset pt(int i) => Offset(i * dx, chartH - (s.points[i] / maxV) * chartH);

      final path = Path()..moveTo(pt(0).dx, pt(0).dy);
      for (var i = 0; i < s.points.length - 1; i++) {
        final p0 = pt((i - 1).clamp(0, s.points.length - 1));
        final p1 = pt(i);
        final p2 = pt(i + 1);
        final p3 = pt((i + 2).clamp(0, s.points.length - 1));
        final cp1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
        final cp2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
      }

      if (s.fill) {
        final fillPath = Path.from(path)
          ..lineTo(size.width, chartH)
          ..lineTo(0, chartH)
          ..close();
        canvas.drawPath(
          fillPath,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [s.color.withValues(alpha: 0.28), Colors.transparent],
            ).createShader(Rect.fromLTWH(0, 0, size.width, chartH)),
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (xLabels.isNotEmpty) {
      final dx = size.width / (xLabels.length - 1).clamp(1, 999);
      for (var i = 0; i < xLabels.length; i++) {
        final tp = TextPainter(
          text: TextSpan(text: xLabels[i], style: AppTypography.bodySm),
          textDirection: TextDirection.ltr,
        )..layout();
        final x = (i * dx - tp.width / 2).clamp(0, size.width - tp.width).toDouble();
        tp.paint(canvas, Offset(x, size.height - tp.height));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) =>
      old.series != series || old.xLabels != xLabels;
}
