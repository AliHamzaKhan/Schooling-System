import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Horizontal grid + bar plot for grade letter distribution (A/B/C/D/F).
class GradeDistributionChart extends StatelessWidget {
  final Map<String, int> distribution;
  const GradeDistributionChart({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    final maxV = distribution.values.fold<int>(1, (m, v) => v > m ? v : m);
    return SizedBox(
      height: 140,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _GridPainter(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final entry in distribution.entries) ...[
                      Expanded(
                        child: FractionallySizedBox(
                          heightFactor: entry.value / maxV,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppRadius.sm)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final letter in distribution.keys)
                Expanded(
                  child: Text(letter,
                      textAlign: TextAlign.center, style: AppTypography.bodySm),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => false;
}
