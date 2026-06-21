import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/assignment.dart';

/// Active assignment row: subject tag dot + status pill, title, description,
/// divider, and a due-date footer (urgent ones turn red with a clock icon).
class AssignmentCard extends StatelessWidget {
  final StudentAssignment assignment;
  final VoidCallback? onTap;
  const AssignmentCard({super.key, required this.assignment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = assignment;
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
                color: a.accent,
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
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: a.accent, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(a.subject,
                              style: AppTypography.titleMd.copyWith(
                                  color: a.accent, fontWeight: FontWeight.w700)),
                        ),
                        _StatusBadge(status: a.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(a.title,
                        style: AppTypography.headlineLg.copyWith(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(a.description, style: AppTypography.bodyLg),
                    const SizedBox(height: AppSpacing.stackMd),
                    const Divider(height: 1, color: AppColors.outlineVariant),
                    const SizedBox(height: AppSpacing.stackMd),
                    Row(
                      children: [
                        Icon(
                          a.dueIsUrgent
                              ? Icons.access_time_rounded
                              : Icons.calendar_today_outlined,
                          size: 14,
                          color: a.dueIsUrgent
                              ? AppColors.error
                              : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(a.dueLine,
                            style: AppTypography.bodyMd.copyWith(
                              color: a.dueIsUrgent
                                  ? AppColors.error
                                  : AppColors.onSurfaceVariant,
                              fontWeight: a.dueIsUrgent
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            )),
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

class _StatusBadge extends StatelessWidget {
  final StudentAssignmentStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final muted = status == StudentAssignmentStatus.notStarted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: muted
            ? Colors.transparent
            : status.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: muted ? Border.all(color: AppColors.outlineVariant) : null,
      ),
      child: Text(status.label,
          style: AppTypography.labelMd.copyWith(
              color: muted ? AppColors.onSurfaceVariant : status.color,
              fontWeight: FontWeight.w700)),
    );
  }
}
