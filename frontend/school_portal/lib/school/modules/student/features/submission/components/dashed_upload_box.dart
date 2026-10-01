import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Dashed-border drop zone for the submission form. Shows an upload icon +
/// label when empty; when a [filename] is set, swaps to a "file ready" state.
class DashedUploadBox extends StatelessWidget {
  final String? filename;
  final VoidCallback? onTap;
  const DashedUploadBox({super.key, this.filename, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AccessibleTap(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedPainter(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
          alignment: Alignment.center,
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  filename == null
                      ? AppIcons.uploadFileRounded
                      : AppIcons.checkCircleOutlineRounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                filename ?? 'Click to upload or drag and drop',
                textAlign: TextAlign.center,
                style: AppTypography.titleMd.copyWith(
                    color: AppColors.onSurface, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                filename == null
                    ? 'PDF only (max 10 MB)'
                    : 'Tap to remove and pick another file',
                style: AppTypography.bodySm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(AppRadius.card));
    final path = Path()..addRRect(rrect);
    final dashed = Path();
    const dash = 6.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        dashed.addPath(metric.extractPath(dist, dist + dash), Offset.zero);
        dist += dash + gap;
      }
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..color = AppColors.outlineVariant
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _DashedPainter old) => false;
}
