import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../models/permission_models.dart';

/// Glass card for one permission group: colored left rail + titled header with
/// an icon, then a divided list of toggle rows.
class PermissionGroupCard extends StatelessWidget {
  final PermissionGroup group;
  final void Function(String key, bool value) onToggle;

  const PermissionGroupCard({super.key, required this.group, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: group.color,
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
                        Icon(group.icon, color: group.color, size: 24),
                        const SizedBox(width: AppSpacing.stackSm),
                        Text(group.title, style: AppTypography.headlineLg.copyWith(fontSize: 22)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    for (var i = 0; i < group.items.length; i++) ...[
                      _ToggleRow(
                        item: group.items[i],
                        onChanged: (v) => onToggle(group.items[i].key, v),
                      ),
                      if (i != group.items.length - 1)
                        const Divider(height: AppSpacing.stackLg, color: AppColors.outlineVariant),
                    ],
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

class _ToggleRow extends StatelessWidget {
  final PermissionItem item;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(item.subtitle, style: AppTypography.bodyMd),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.stackMd),
        Switch(
          value: item.enabled,
          onChanged: onChanged,
          activeThumbColor: AppColors.onPrimary,
          activeTrackColor: const Color(0xFF3B82F6),
          inactiveThumbColor: AppColors.onSurfaceVariant,
          inactiveTrackColor: AppColors.surfaceContainerHighest,
        ),
      ],
    );
  }
}
