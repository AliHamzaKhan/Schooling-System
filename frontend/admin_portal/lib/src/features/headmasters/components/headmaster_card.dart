import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/headmaster.dart';

/// Headmaster list card: status-colored left rail, avatar, name + status badge,
/// an overflow menu (Edit / Delete), then school / email / phone rows.
class HeadmasterCard extends StatelessWidget {
  final Headmaster headmaster;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HeadmasterCard({
    super.key,
    required this.headmaster,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final h = headmaster;
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: h.status.color, width: 5)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.stackMd, AppSpacing.stackMd, AppSpacing.stackSm, AppSpacing.stackMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(headmaster: h),
                  const SizedBox(width: AppSpacing.stackMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.name,
                            style: AppTypography.titleLg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        _StatusBadge(status: h.status),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded,
                        size: 20, color: AppColors.onSurfaceVariant),
                    onSelected: (v) {
                      if (v == 'edit') onEdit?.call();
                      if (v == 'delete') onDelete?.call();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.block_rounded, color: AppColors.error),
                          title: Text('Deactivate', style: TextStyle(color: AppColors.error)),
                        ),
                      ),
                    ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: status.color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
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
