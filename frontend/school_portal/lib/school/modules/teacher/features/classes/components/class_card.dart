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
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent rail doubles as the class-teacher signal.
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.stackMd,
                  vertical: AppSpacing.stackSm,
                ),
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
                    const SizedBox(height: 4),
                    // Subjects this teacher takes for the section.
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final s in item.subjects) _SubjectChip(label: s),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Meta(
                            icon: Icons.people_alt_outlined,
                            label: '${item.studentCount}'),
                        const SizedBox(width: AppSpacing.stackMd),
                        _Meta(
                            icon: Icons.schedule_rounded,
                            label: '${item.periodsPerWeek}/wk'),
                        if (item.room != null) ...[
                          const SizedBox(width: AppSpacing.stackMd),
                          Flexible(
                            child: _Meta(
                                icon: Icons.location_on_outlined,
                                label: item.room!),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.stackSm),
              child: Icon(Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
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
          const Icon(Icons.star_rounded, size: 12, color: AppColors.primary),
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
