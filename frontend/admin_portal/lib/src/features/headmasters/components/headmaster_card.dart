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
                            style: AdminType.cardTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        _StatusBadge(status: h.status),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded,
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
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.block_rounded, color: AdminPalette.danger),
                          title: Text('Deactivate', style: TextStyle(color: AdminPalette.danger)),
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
      backgroundColor: AdminPalette.tint,
      child: Text(headmaster.initials,
          style: AdminType.rowTitle.copyWith(color: AdminPalette.muted)),
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
