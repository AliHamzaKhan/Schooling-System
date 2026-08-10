import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../schools/models/school.dart';

/// Row for a school whose module permissions can be configured: icon, name,
/// code, a plan badge and a status badge, and a chevron. Accent-colored left
/// rail follows the school's status color.
class SchoolPermissionCard extends StatelessWidget {
  final School school;
  final VoidCallback onTap;

  const SchoolPermissionCard({super.key, required this.school, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = school.status.color;
    final hasPlan = (school.planName ?? '').isNotEmpty;
    return GlassSurface(
      padding: EdgeInsets.zero,
      onTap: onTap,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(school.initial,
                              style: AppTypography.titleLg.copyWith(color: accent)),
                        ),
                        const SizedBox(width: AppSpacing.stackMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(school.name, style: AppTypography.titleLg),
                              if (school.code.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(school.code, style: AppTypography.bodyMd),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.onSurfaceVariant),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Row(
                      children: [
                        _Badge(
                          icon: Icons.verified_user_outlined,
                          label: hasPlan ? school.planName! : 'No plan',
                          color: hasPlan ? AppColors.primary : AppColors.onSurfaceVariant,
                          neutral: !hasPlan,
                        ),
                        const SizedBox(width: AppSpacing.stackSm),
                        _Badge(
                          icon: Icons.circle,
                          label: school.status.label,
                          color: accent,
                        ),
                      ],
                    ),
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

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool neutral;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
    this.neutral = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: neutral
            ? AppColors.surfaceContainerHigh
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.labelMd.copyWith(color: color)),
        ],
      ),
    );
  }
}
