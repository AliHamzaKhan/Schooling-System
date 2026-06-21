import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Lightweight bar chart for the Enrollment Distribution card — labeled bars
/// at the bottom, horizontal gridlines, no axis values on the y-axis.
class EnrollmentDistributionChart extends StatelessWidget {
  final Map<String, int> data;
  const EnrollmentDistributionChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final maxV = entries.fold<int>(1, (m, e) => e.value > m ? e.value : m);
    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _GridPainter(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackSm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final e in entries) ...[
                      Expanded(
                        child: FractionallySizedBox(
                          heightFactor: e.value / maxV,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.18),
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
              for (final e in entries)
                Expanded(
                  child: Text(e.key,
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
      ..color = AppColors.outlineVariant.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => false;
}
