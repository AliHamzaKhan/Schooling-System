import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/student.dart';

/// Horizontal student card: avatar + status ring on the left, name/roll on top,
/// grade + section chips underneath, status pill on the right. Overflow menu
/// stays in the top-right corner; tapping the surface opens the student.
class StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;

  const StudentCard({super.key, required this.student, this.onTap, this.onMenu});

  @override
  Widget build(BuildContext context) {
    final accent = student.status.color;
    return GlassSurface(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarBadge(student: student, accent: accent),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          student.name,
                          style: AppTypography.titleLg
                              .copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _StatusPill(status: student.status),
                      if (onMenu != null)
                        InkResponse(
                          onTap: onMenu,
                          radius: 20,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.more_vert_rounded,
                                size: 20, color: AppColors.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Roll #${student.roll}',
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.stackMd),
                  Wrap(
                    spacing: AppSpacing.stackSm,
                    runSpacing: 6,
                    children: [
                      _Chip(icon: Icons.school_outlined, text: student.grade),
                      _Chip(
                          icon: Icons.groups_outlined,
                          text: 'Sec ${student.section}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final Student student;
  final Color accent;
  const _AvatarBadge({required this.student, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 2),
      ),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: accent.withValues(alpha: 0.18),
        backgroundImage: student.avatarUrl != null
            ? NetworkImage(student.avatarUrl!)
            : null,
        child: student.avatarUrl == null
            ? Text(student.initials,
                style: AppTypography.titleLg
                    .copyWith(color: accent, fontWeight: FontWeight.w700))
            : null,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final StudentStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: status.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(status.label,
              style: AppTypography.labelMd
                  .copyWith(color: status.color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(text,
              style: AppTypography.labelMd
                  .copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
