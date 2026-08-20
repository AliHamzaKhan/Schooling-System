import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../schools/models/school.dart';
import '../../../../ui/admin_theme.dart';
import '../../../../ui/admin_widgets/admin_surface.dart';

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
    return AdminCard(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      onTap: onTap,
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
                    style: AdminType.cardTitle.copyWith(color: accent)),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(school.name, style: AdminType.cardTitle),
                    if (school.code.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(school.code, style: AdminType.body),
                    ],
                  ],
                ),
              ),
              const Icon(AppIcons.chevronRightRounded,
                  color: AdminPalette.muted),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              _Badge(
                icon: AppIcons.verifiedUserOutlined,
                label: hasPlan ? school.planName! : 'No plan',
                color: hasPlan ? AdminPalette.ink : AdminPalette.muted,
                neutral: !hasPlan,
              ),
              const SizedBox(width: AppSpacing.stackSm),
              _Badge(
                icon: AppIcons.circle,
                label: school.status.label,
                color: accent,
              ),
            ],
          ),
        ],
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
            ? AdminPalette.tint
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label, style: AdminType.label.copyWith(color: color)),
        ],
      ),
    );
  }
}
