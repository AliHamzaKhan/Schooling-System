import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// One wedge of a [DonutChart].
class DonutSlice {
  final double value;
  final Color color;
  final String label;
  const DonutSlice({required this.value, required this.color, required this.label});
}

/// Ring chart with a centered headline value/caption. Pure CustomPainter so we
/// avoid pulling in a charting dependency.
class DonutChart extends StatelessWidget {
  final List<DonutSlice> slices;
  final double size;
  final double thickness;
  final String centerValue;
  final String centerCaption;

  const DonutChart({
    super.key,
    required this.slices,
    required this.centerValue,
    required this.centerCaption,
    this.size = 160,
    this.thickness = 22,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(slices: slices, thickness: thickness),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerValue,
                  style: AppTypography.headlineLg.copyWith(fontWeight: FontWeight.w700)),
              Text(centerCaption, style: AppTypography.bodySm),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSlice> slices;
  final double thickness;
  _DonutPainter({required this.slices, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return;
    final rect = Offset.zero & size;
    final inset = thickness / 2 + 2;
    final arcRect = rect.deflate(inset);
    var start = -math.pi / 2;
    const gap = 0.04; // small spacing between wedges

    for (final s in slices) {
      final sweep = (s.value / total) * (2 * math.pi) - gap;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(arcRect, start + gap / 2, sweep, false, paint);
      start += (s.value / total) * (2 * math.pi);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.slices != slices || old.thickness != thickness;
}
