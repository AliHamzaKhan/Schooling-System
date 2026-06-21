import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Single-value progress ring (one solid arc against a muted track) with a
/// centered percent + caption. Used on the Attendance "Daily Rates" cards.
class RingChart extends StatelessWidget {
  final double progress; // 0..1
  final Color color;
  final String value;
  final String caption;
  final double size;
  final double thickness;

  const RingChart({
    super.key,
    required this.progress,
    required this.color,
    required this.value,
    required this.caption,
    this.size = 110,
    this.thickness = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: progress, color: color, thickness: thickness),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: AppTypography.headlineLg.copyWith(
                      fontWeight: FontWeight.w700, color: color)),
              Text(caption, style: AppTypography.bodySm),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double thickness;
  _RingPainter({required this.progress, required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - thickness) / 2;

    final track = Paint()
      ..color = AppColors.surfaceContainerHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress.clamp(0, 1) * 2 * math.pi,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color || old.thickness != thickness;
}
