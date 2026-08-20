import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/headmaster.dart';
import '../../../ui/admin_theme.dart';
import '../../../ui/admin_widgets/admin_surface.dart';

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
    return AdminCard(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
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
                        style: AdminType.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    _StatusBadge(status: h.status),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(AppIcons.moreVertRounded,
                    size: 20, color: AdminPalette.muted),
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
                      leading: Icon(AppIcons.editOutlined),
                      title: Text('Edit'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(AppIcons.blockRounded, color: AdminPalette.danger),
                      title: Text('Deactivate', style: TextStyle(color: AdminPalette.danger)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          const Divider(height: 1, color: AdminPalette.border),
          const SizedBox(height: AppSpacing.stackMd),
          _InfoRow(
            icon: AppIcons.apartmentRounded,
            text: h.school ?? 'Unassigned',
            muted: h.school == null,
          ),
          const SizedBox(height: AppSpacing.stackSm),
          _InfoRow(icon: AppIcons.mailOutlineRounded, text: h.email),
          const SizedBox(height: AppSpacing.stackSm),
          _InfoRow(
            icon: AppIcons.phoneOutlined,
            text: h.phone ?? 'Not provided',
            muted: h.phone == null,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final Headmaster headmaster;
  const _Avatar({required this.headmaster});

  @override
  Widget build(BuildContext context) {
    final ring = headmaster.status.color;
    final Widget avatar = headmaster.avatarUrl != null
        ? CircleAvatar(radius: 24, backgroundImage: NetworkImage(headmaster.avatarUrl!))
        : CircleAvatar(
            radius: 24,
            backgroundColor: ring.withValues(alpha: 0.12),
            child: Text(headmaster.initials,
                style: AdminType.rowTitle.copyWith(color: ring)),
          );
    // Thin status-colored ring around the avatar — keeps the status cue the
    // removed left rail used to carry.
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring.withValues(alpha: 0.55), width: 2),
      ),
      child: avatar,
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
              style: AdminType.label.copyWith(color: status.color)),
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
    final color = muted ? AdminPalette.faint : AdminPalette.muted;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.stackSm),
        Expanded(
          child: Text(
            text,
            style: AdminType.body.copyWith(
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
