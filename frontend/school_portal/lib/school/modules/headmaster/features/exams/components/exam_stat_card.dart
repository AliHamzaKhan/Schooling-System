import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Compact stat card with a colored left rail (Active / Upcoming / Pending).
class ExamStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final Widget? trailing;

  const ExamStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
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
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: AppTypography.bodyMd),
                          const SizedBox(height: 2),
                          Text(value,
                              style: AppTypography.displayLg
                                  .copyWith(fontSize: 32, color: AppColors.primary)),
                        ],
                      ),
                    ),
                    ?trailing,
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
