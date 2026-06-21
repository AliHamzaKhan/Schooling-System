import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../models/permission_models.dart';

/// Row for a school whose permissions can be configured: icon, name, ID, a plan
/// badge, an "X/Y Active" module chip, and a chevron. Accent-colored left rail.
class SchoolPermissionCard extends StatelessWidget {
  final SchoolPermissionSummary school;
  final VoidCallback onTap;

  const SchoolPermissionCard({super.key, required this.school, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                color: school.accent,
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
                          decoration: BoxDecoration(
                            color: school.planColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Icon(school.icon, color: school.planColor, size: 24),
                        ),
                        const SizedBox(width: AppSpacing.stackMd),
                        Expanded(
                          child: Text(school.name, style: AppTypography.titleLg),
                        ),
                        const SizedBox(width: AppSpacing.stackSm),
                        Text('ID: ${school.id}', style: AppTypography.bodyMd),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.onSurfaceVariant),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Row(
                      children: [
                        _Badge(
                          icon: Icons.verified_user_outlined,
                          label: school.planLabel,
                          color: school.planColor,
                        ),
                        const SizedBox(width: AppSpacing.stackSm),
                        _Badge(
                          icon: Icons.grid_view_rounded,
                          label: '${school.activeModules}/${school.totalModules} Active',
                          color: AppColors.onSurfaceVariant,
                          neutral: true,
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
