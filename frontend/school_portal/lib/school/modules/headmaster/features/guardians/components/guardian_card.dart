import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/profile_avatar.dart';
import '../models/guardian.dart';

/// Guardian card: avatar + name + status pill, contact rows, linked students
/// chip group, then either "View Profile" (active) or "Invite to Portal"
/// (pending).
class GuardianCard extends StatelessWidget {
  final Guardian guardian;
  final VoidCallback? onView;
  final VoidCallback? onInvite;
  final VoidCallback? onMenu;

  const GuardianCard({
    super.key,
    required this.guardian,
    this.onView,
    this.onInvite,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final g = guardian;
    final isPending = g.status == GuardianStatus.pending;
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: g.status.color,
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
                        _Avatar(guardian: g),
                        const SizedBox(width: AppSpacing.stackMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.name, style: AppTypography.headlineLg.copyWith(fontSize: 22)),
                              const SizedBox(height: 4),
                              _StatusBadge(status: g.status),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: onMenu,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.more_vert_rounded,
                                size: 20, color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    _InfoRow(icon: Icons.mail_outline_rounded, text: g.email),
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      text: g.phone ?? 'No phone added',
                      muted: g.phone == null,
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    _LinkedStudents(students: g.linkedStudents),
                    const SizedBox(height: AppSpacing.stackMd),
                    if (isPending)
                      PrimaryButton(
                        label: 'Invite to Portal',
                        leadingIcon: Icons.send_rounded,
                        trailingIcon: null,
                        expanded: true,
                        onPressed: onInvite,
                      )
                    else
                      GhostButton(
                        label: 'View Profile',
                        expanded: true,
                        onPressed: onView,
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
  final Guardian guardian;
  const _Avatar({required this.guardian});

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(
      name: guardian.name,
      url: guardian.avatarUrl,
      size: 56,
      accent: AppColors.onSurfaceVariant,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final GuardianStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 13, color: status.color),
          const SizedBox(width: 4),
          Text(status.label,
              style: AppTypography.labelMd.copyWith(color: status.color)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool muted;
  const _InfoRow({required this.icon, required this.text, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.outline : AppColors.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.stackSm),
        Expanded(
          child: Text(text,
              style: AppTypography.bodyMd.copyWith(
                color: color,
                fontStyle: muted ? FontStyle.italic : FontStyle.normal,
              )),
        ),
      ],
    );
  }
}

class _LinkedStudents extends StatelessWidget {
  final List<LinkedStudent> students;
  const _LinkedStudents({required this.students});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Linked Students',
              style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.stackSm),
          Wrap(
            spacing: AppSpacing.stackSm,
            runSpacing: 6,
            children: [
              for (final s in students) _StudentChip(student: s),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentChip extends StatelessWidget {
  final LinkedStudent student;
  const _StudentChip({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: student.color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(student.label, style: AppTypography.labelMd),
        ],
      ),
    );
  }
}
