import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/profile_avatar.dart';
import '../models/teacher.dart';

/// Teacher roster card: accent avatar (with status ring), name + status pill,
/// department chip, and a right-aligned "View Profile" CTA with quick-contact
/// icon buttons.
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
      onTap: onView,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AvatarBadge(teacher: t),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(t.name,
                                style: AppTypography.titleLg
                                    .copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          _StatusPill(status: t.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _DeptChip(text: t.department),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Row(
              children: [
                _IconDot(icon: AppIcons.mailOutlineRounded, onTap: onMail),
                const SizedBox(width: AppSpacing.stackSm),
                if (canChat)
                  _IconDot(
                      icon: AppIcons.chatBubbleOutlineRounded, onTap: onChat),
                const Spacer(),
                InkWell(
                  onTap: onView,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View Profile',
                            style: AppTypography.labelMd.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        const Icon(AppIcons.arrowForwardRounded,
                            size: 16, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final Teacher teacher;
  const _AvatarBadge({required this.teacher});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            Border.all(color: teacher.accent.withValues(alpha: 0.35), width: 2),
      ),
      child: ProfileAvatar(
        name: teacher.name,
        url: teacher.avatarUrl,
        size: 56,
        accent: teacher.accent,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final TeacherStatus status;
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
                  BoxDecoration(color: status.color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status.label,
              style: AppTypography.labelMd
                  .copyWith(color: status.color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DeptChip extends StatelessWidget {
  final String text;
  const _DeptChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.apartmentOutlined,
              size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(text,
              style: AppTypography.labelMd
                  .copyWith(fontWeight: FontWeight.w600)),
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
