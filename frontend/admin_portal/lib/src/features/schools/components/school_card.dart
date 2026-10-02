import 'package:flutter/material.dart';

import '../../../ui/admin_theme.dart';
import '../../../ui/admin_widgets/admin_surface.dart';
import '../models/school.dart';
import 'package:shared/shared.dart';

/// Schools Directory row: logo chip, name + code, status chip, the school's
/// key facts, and a "Manage" action with the overflow menu.
class SchoolCard extends StatelessWidget {
  final School school;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onSubscription;
  final VoidCallback? onDelete;
  final VoidCallback? onActivate;

  const SchoolCard({
    super.key,
    required this.school,
    this.onTap,
    this.onEdit,
    this.onSubscription,
    this.onDelete,
    this.onActivate,
  });

  /// Suspended schools surface as [SchoolStatus.expired] in the UI; those get an
  /// "Activate" action instead of "Deactivate".
  bool get _isSuspended => school.status == SchoolStatus.expired;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Logo(school: school),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(school.name,
                        style: AdminType.cardTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(
                      school.code.isEmpty ? '—' : 'ID: ${school.code}',
                      style: AdminType.meta
                          .copyWith(fontSize: 12, color: AdminPalette.faint),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AdminStatusChip(
                label: school.status.label,
                color: school.status.color,
                background: school.status.softColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdminMetaRow(
              icon: AppIcons.locationOnOutlined, text: school.location),
          const SizedBox(height: 10),
          AdminMetaRow(
            icon: AppIcons.peopleAltOutlined,
            text: '${_compact(school.students)} Students',
          ),
          const SizedBox(height: 10),
          AdminMetaRow(
            icon: AppIcons.desktopWindowsOutlined,
            text: school.planName ?? school.planCode ?? 'No plan',
          ),
          const SizedBox(height: 10),
          AdminMetaRow(
            icon: school.status == SchoolStatus.trial
                ? AppIcons.timerOutlined
                : school.status == SchoolStatus.expired
                    ? AppIcons.historyRounded
                    : AppIcons.calendarTodayOutlined,
            text: school.tenureLabel,
            tint: school.status == SchoolStatus.trial
                ? school.status.color
                : null,
          ),
          const Divider(height: 24, color: AdminPalette.divider),
          Row(
            children: [
              _OverflowMenu(
                isSuspended: _isSuspended,
                onEdit: onEdit,
                onSubscription: onSubscription,
                onDelete: onDelete,
                onActivate: onActivate,
              ),
              const Spacer(),
              AdminInlineAction(
                label: 'Manage',
                trailingIcon: AppIcons.arrowForwardRounded,
                onTap: onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _compact(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

class _Logo extends StatelessWidget {
  final School school;
  const _Logo({required this.school});

  @override
  Widget build(BuildContext context) {
    if (school.logoUrl != null) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: AdminRadius.brTile,
          image: DecorationImage(
              image: schoolImage(school.logoUrl!), fit: BoxFit.cover),
        ),
      );
    }
    return const AdminIconTile(icon: AppIcons.schoolOutlined, size: 46);
  }
}

class _OverflowMenu extends StatelessWidget {
  final bool isSuspended;
  final VoidCallback? onEdit;
  final VoidCallback? onSubscription;
  final VoidCallback? onDelete;
  final VoidCallback? onActivate;

  const _OverflowMenu({
    required this.isSuspended,
    this.onEdit,
    this.onSubscription,
    this.onDelete,
    this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      color: AdminPalette.card,
      shape: const RoundedRectangleBorder(borderRadius: AdminRadius.brTile),
      icon: const Icon(AppIcons.moreHorizRounded,
          size: 20, color: AdminPalette.faint),
      onSelected: (v) {
        if (v == 'edit') onEdit?.call();
        if (v == 'subscription') onSubscription?.call();
        if (v == 'delete') onDelete?.call();
        if (v == 'activate') onActivate?.call();
      },
      itemBuilder: (_) => [
        _item('edit', AppIcons.editOutlined, 'Edit', AdminPalette.ink),
        _item('subscription', AppIcons.cardMembershipOutlined, 'Subscription',
            AdminPalette.ink),
        if (isSuspended)
          _item('activate', AppIcons.checkCircleOutlineRounded, 'Activate',
              AdminPalette.positive)
        else
          _item('delete', AppIcons.blockRounded, 'Deactivate',
              AdminPalette.danger),
      ],
    );
  }

  PopupMenuItem<String> _item(
          String value, IconData icon, String label, Color color) =>
      PopupMenuItem<String>(
        value: value,
        height: 44,
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(label, style: AdminType.label.copyWith(color: color)),
          ],
        ),
      );
}
