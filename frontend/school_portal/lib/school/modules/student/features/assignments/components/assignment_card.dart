import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/assignment.dart';

/// Active-assignment card: a subject icon chip + status pill, the title and
/// description, then a footer with the due date, points, and a chevron.
class AssignmentCard extends StatelessWidget {
  final StudentAssignment assignment;
  final VoidCallback? onTap;
  const AssignmentCard({super.key, required this.assignment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    const accents = [AppColors.primary, AppColors.tertiary, AppColors.secondary,
      Color(0xFF986016), Color(0xFF2673B8)];
    final accent = accents[a.subject.runes.fold<int>(0, (sum, char) => sum + char) % accents.length];
    return GlassSurface(
      fill: Color.alphaBlend(accent.withValues(alpha: .055), Colors.white),
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(
                  AppIcons.menuBookRounded,
                  size: 20,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Expanded(
                child: Text(
                  a.subject.isEmpty ? 'Assignment' : a.subject,
                  style: AppTypography.titleMd.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusBadge(status: a.status),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(a.title, style: AppTypography.headlineLg.copyWith(fontSize: 21)),
          if (a.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              a.description,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.stackMd),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              Icon(
                a.dueIsUrgent
                    ? AppIcons.accessTimeRounded
                    : AppIcons.calendarTodayOutlined,
                size: 14,
                color: a.dueIsUrgent
                    ? AppColors.error
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  a.dueLine,
                  style: AppTypography.bodyMd.copyWith(
                    color: a.dueIsUrgent
                        ? AppColors.error
                        : AppColors.onSurfaceVariant,
                    fontWeight: a.dueIsUrgent
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
              const Spacer(),
              if (a.points > 0) ...[
                Text(
                  '${a.points} pts',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(
                AppIcons.chevronRightRounded,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ],
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
      child: Text(
        status.label,
        style: AppTypography.labelMd.copyWith(
          color: muted ? AppColors.onSurfaceVariant : status.color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
