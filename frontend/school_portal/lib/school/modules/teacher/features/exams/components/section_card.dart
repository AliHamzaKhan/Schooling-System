import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Glass card with an accent left rail, a soft circular icon badge in the
/// header, and a section title — the building block for the Create Exam form.
class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final Widget? trailing;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.accent = AppColors.primary,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: accent, size: 18),
                        ),
                        const SizedBox(width: AppSpacing.stackSm),
                        Expanded(
                            child: Text(title,
                                style: AppTypography.headlineLg.copyWith(fontSize: 22))),
                        ?trailing,
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    ...children,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashed-border drop zone used inside the "Exam Content" section for adding
/// questions or uploading a PDF.
class DashedDropZone extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final Color accent;

  const DashedDropZone({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.onAction,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return _Dashed(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackLg),
              child: Text(subtitle,
                  textAlign: TextAlign.center, style: AppTypography.bodyMd),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Material(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(actionLabel,
                      style: AppTypography.labelMd.copyWith(
                          color: AppColors.onSurface, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dashed extends StatelessWidget {
  final Widget child;
  const _Dashed({required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(),
      child: child,
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(AppRadius.button));
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
