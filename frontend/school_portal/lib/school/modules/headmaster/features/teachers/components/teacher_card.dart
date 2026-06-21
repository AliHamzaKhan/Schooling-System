import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/teacher.dart';

/// Teacher list card: avatar, name, department, status badge, then a row of
/// quick-contact icon buttons (mail / chat) opposite a "View Profile" link.
/// Accent-colored left rail per teacher.
class TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback? onView;
  final VoidCallback? onMail;
  final VoidCallback? onChat;

  const TeacherCard({
    super.key,
    required this.teacher,
    this.onView,
    this.onMail,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final t = teacher;
    final canChat = t.status == TeacherStatus.active;
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: t.accent,
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
                        _Avatar(teacher: t),
                        const SizedBox(width: AppSpacing.stackMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.name,
                                  style: AppTypography.titleLg
                                      .copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(t.department, style: AppTypography.bodyMd),
                            ],
                          ),
                        ),
                        _StatusBadge(status: t.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    const Divider(height: 1, color: AppColors.outlineVariant),
                    const SizedBox(height: AppSpacing.stackMd),
                    Row(
                      children: [
                        _IconDot(icon: Icons.mail_outline_rounded, onTap: onMail),
                        const SizedBox(width: AppSpacing.stackSm),
                        if (canChat)
                          _IconDot(
                              icon: Icons.chat_bubble_outline_rounded, onTap: onChat),
                        const Spacer(),
                        GestureDetector(
                          onTap: onView,
                          child: Text(
                            'View Profile',
                            style: AppTypography.labelMd.copyWith(
                                color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
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

class _Avatar extends StatelessWidget {
  final Teacher teacher;
  const _Avatar({required this.teacher});

  @override
  Widget build(BuildContext context) {
    if (teacher.avatarUrl != null) {
      return CircleAvatar(radius: 26, backgroundImage: NetworkImage(teacher.avatarUrl!));
    }
    return CircleAvatar(
      radius: 26,
      backgroundColor: teacher.accent.withValues(alpha: 0.18),
      child: Text(teacher.initials,
          style: AppTypography.titleLg.copyWith(color: teacher.accent)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TeacherStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final muted = status == TeacherStatus.onLeave;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: muted
            ? AppColors.surfaceContainerHigh
            : status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: status.color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status.label,
              style: AppTypography.labelMd
                  .copyWith(color: muted ? AppColors.onSurfaceVariant : status.color)),
        ],
      ),
    );
  }
}

class _IconDot extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _IconDot({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerHigh,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}
