import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/assignment.dart';

/// Assignment list row: subject icon, title, class + due line, turn-in progress
/// bar with `x/total Turned In` label, and a status pill on the right.
class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback? onTap;

  const AssignmentCard({super.key, required this.assignment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    final wash =
        a.status == AssignmentStatus.closed && a.id == 'A-4'; // soft red bg
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      onTap: onTap,
      fill: wash ? AppColors.error.withValues(alpha: 0.06) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: a.iconAccent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(a.icon, color: a.iconAccent, size: 20),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title,
                        style: AppTypography.titleLg
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(AppIcons.tagRounded,
                            size: 13, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(a.className, style: AppTypography.bodyMd),
                        const SizedBox(width: 6),
                        Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                                color: AppColors.outline,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Icon(AppIcons.eventOutlined,
                            size: 13, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(a.dueLabel,
                              style: AppTypography.bodyMd,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              Expanded(
                child: Text(
                    '${a.turnedIn}/${a.total} Turned In',
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              _StatusPill(status: a.status),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: a.progress,
              minHeight: 6,
              color: a.iconAccent,
              backgroundColor: AppColors.surfaceContainerHigh,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final AssignmentStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final muted = status == AssignmentStatus.draft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: muted
            ? AppColors.surfaceContainerHigh
            : status.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status.label,
        style: AppTypography.labelCaps.copyWith(
          color: muted ? AppColors.onSurfaceVariant : status.color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
