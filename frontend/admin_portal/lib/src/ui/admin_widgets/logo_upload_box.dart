import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Dashed drag-and-drop placeholder for uploading a school logo. Tapping fires
/// [onTap] (wire to an image picker later).
class LogoUploadBox extends StatelessWidget {
  final VoidCallback? onTap;
  const LogoUploadBox({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        radius: AppRadius.card,
        color: AppColors.outlineVariant,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackXl),
          alignment: Alignment.center,
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_upload_outlined,
                    color: AppColors.primary, size: 26),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Text('Click to upload or drag and drop',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMd.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('SVG, PNG, JPG or GIF (max. 800×400px)',
                  style: AppTypography.bodySm),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal dashed-border container (avoids adding a package for one widget).
class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  const DottedBorder({
    super.key,
    required this.child,
    required this.color,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
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
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _DashedPainter old) =>
      old.color != color || old.radius != radius;
}
