import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/my_class.dart';

/// Full-width class row, one per line.
///
/// Laid out horizontally and sized by its content rather than a fixed height,
/// so long class names or a wide subject list wrap instead of overflowing.
/// Vertical padding is deliberately tight so a full timetable stays scannable.
class ClassCard extends StatelessWidget {
  final MyClass item;
  final VoidCallback? onTap;

  const ClassCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = item.isClassTeacher ? AppColors.primary : AppColors.tertiary;
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rounded subject badge — tinted in the class-teacher accent.
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(
              item.isClassTeacher
                  ? AppIcons.workspacePremiumRounded
                  : AppIcons.menuBookRounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMd
                              .copyWith(fontWeight: FontWeight.w800)),
                    ),
                    if (item.isClassTeacher) ...[
                      const SizedBox(width: 6),
                      const _ClassTeacherBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Subjects this teacher takes for the section.
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final s in item.subjects) _SubjectChip(label: s),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Meta(
                        icon: AppIcons.peopleAltOutlined,
                        label: '${item.studentCount}'),
                    const SizedBox(width: AppSpacing.stackMd),
                    _Meta(
                        icon: AppIcons.scheduleRounded,
                        label: '${item.periodsPerWeek}/wk'),
                    if (item.room != null) ...[
                      const SizedBox(width: AppSpacing.stackMd),
                      Flexible(
                        child: _Meta(
                            icon: AppIcons.locationOnOutlined,
                            label: item.room!),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.stackSm, top: 10),
            child: Icon(AppIcons.chevronRightRounded,
                color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ClassTeacherBadge extends StatelessWidget {
  const _ClassTeacherBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.starRounded, size: 12, color: AppColors.primary),
          const SizedBox(width: 3),
          Text('Class teacher',
              style: AppTypography.labelMd.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final String label;
  const _SubjectChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(label,
          style: AppTypography.labelMd
              .copyWith(color: AppColors.onSurfaceVariant)),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Meta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm),
        ),
      ],
    );
  }
}
