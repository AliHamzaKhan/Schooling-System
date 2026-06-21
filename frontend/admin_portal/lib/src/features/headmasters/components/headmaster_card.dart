import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/headmaster.dart';

/// Headmaster list card: overflow menu, avatar, name + status badge, then
/// school / email / phone rows. Status-colored left rail. Missing fields show
/// muted placeholders ("Unassigned", "Not provided").
class HeadmasterCard extends StatelessWidget {
  final Headmaster headmaster;
  final VoidCallback? onMenu;

  const HeadmasterCard({super.key, required this.headmaster, this.onMenu});

  @override
  Widget build(BuildContext context) {
    final h = headmaster;
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: h.status.color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: onMenu,
                          child: const Icon(Icons.more_vert_rounded,
                              size: 20, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(width: AppSpacing.stackSm),
                        _Avatar(headmaster: h),
                        const SizedBox(width: AppSpacing.stackMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(h.name, style: AppTypography.titleLg),
                              const SizedBox(height: 4),
                              _StatusBadge(status: h.status),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    _InfoRow(
                      icon: Icons.apartment_rounded,
                      text: h.school ?? 'Unassigned',
                      muted: h.school == null,
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    _InfoRow(icon: Icons.mail_outline_rounded, text: h.email),
                    const SizedBox(height: AppSpacing.stackSm),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      text: h.phone ?? 'Not provided',
                      muted: h.phone == null,
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
  final Headmaster headmaster;
  const _Avatar({required this.headmaster});

  @override
  Widget build(BuildContext context) {
    if (headmaster.avatarUrl != null) {
      return CircleAvatar(radius: 24, backgroundImage: NetworkImage(headmaster.avatarUrl!));
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.surfaceContainerHigh,
      child: Text(headmaster.initials,
          style: AppTypography.titleMd.copyWith(color: AppColors.onSurfaceVariant)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final HeadmasterStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: status.color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(status.label, style: AppTypography.bodyMd.copyWith(color: status.color)),
      ],
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
          child: Text(
            text,
            style: AppTypography.bodyMd.copyWith(
              color: color,
              fontStyle: muted ? FontStyle.italic : FontStyle.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
