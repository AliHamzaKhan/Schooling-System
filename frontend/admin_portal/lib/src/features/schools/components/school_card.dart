import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../ui/admin_widgets/status_pill.dart';
import '../models/school.dart';

/// School Management list row: logo, name, location + student count, tenure
/// line, a status pill, an overflow menu, and a status-colored left rail.
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
    final accent = school.status.color;
    return GlassSurface(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
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
                        _Logo(school: school),
                        const SizedBox(width: AppSpacing.stackMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(school.name, style: AppTypography.titleLg),
                              const SizedBox(height: 6),
                              _MetaRow(
                                icon: Icons.location_on_outlined,
                                text: school.location,
                                trailingIcon: Icons.people_alt_outlined,
                                trailingText: '${_compact(school.students)} Students',
                              ),
                              const SizedBox(height: 4),
                              _MetaRow(
                                icon: school.status == SchoolStatus.trial
                                    ? Icons.timer_outlined
                                    : school.status == SchoolStatus.expired
                                        ? Icons.history_rounded
                                        : Icons.calendar_today_outlined,
                                text: school.tenureLabel,
                                tint: school.status == SchoolStatus.trial
                                    ? school.status.color
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Row(
                      children: [
                        StatusPill(
                          label: school.status.label,
                          color: school.status.color,
                          icon: Icons.circle,
                        ),
                        if (school.planCode != null) ...[
                          const SizedBox(width: AppSpacing.stackSm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              school.planName ?? school.planCode!,
                              style: AppTypography.labelMd
                                  .copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        ],
                        const Spacer(),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert_rounded,
                              size: 20, color: AppColors.onSurfaceVariant),
                          onSelected: (v) {
                            if (v == 'edit') onEdit?.call();
                            if (v == 'subscription') onSubscription?.call();
                            if (v == 'delete') onDelete?.call();
                            if (v == 'activate') onActivate?.call();
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Edit'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'subscription',
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.card_membership_outlined),
                                title: Text('Subscription'),
                              ),
                            ),
                            if (_isSuspended)
                              const PopupMenuItem(
                                value: 'activate',
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.check_circle_outline_rounded,
                                      color: AppColors.primary),
                                  title: Text('Activate',
                                      style: TextStyle(color: AppColors.primary)),
                                ),
                              )
                            else
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.block_rounded, color: AppColors.error),
                                  title: Text('Deactivate',
                                      style: TextStyle(color: AppColors.error)),
                                ),
                              ),
                          ],
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

  static String _compact(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)},${(n % 1000).toString().padLeft(3, '0')}' : '$n';
}

class _Logo extends StatelessWidget {
  final School school;
  const _Logo({required this.school});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.button),
        image: school.logoUrl != null
            ? DecorationImage(
                image: NetworkImage(school.logoUrl!), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: school.logoUrl == null
          ? Text(school.initial,
              style: AppTypography.titleLg.copyWith(color: AppColors.onSurfaceVariant))
          : null,
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final IconData? trailingIcon;
  final String? trailingText;
  final Color? tint;

  const _MetaRow({
    required this.icon,
    required this.text,
    this.trailingIcon,
    this.trailingText,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMd.copyWith(color: tint ?? AppColors.onSurfaceVariant);
    final color = tint ?? AppColors.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: style, overflow: TextOverflow.ellipsis)),
        if (trailingIcon != null && trailingText != null) ...[
          const SizedBox(width: AppSpacing.stackMd),
          Icon(trailingIcon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(trailingText!, style: style),
        ],
      ],
    );
  }
}
