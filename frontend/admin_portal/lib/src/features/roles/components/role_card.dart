import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../ui/admin_widgets/status_pill.dart';
import '../models/role_models.dart';

/// A role row on Role Management: icon, name + description, user/permission
/// counts, a System/Custom pill, and an active toggle.
class RoleCard extends StatelessWidget {
  final ManagedRole role;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onConfigure;

  const RoleCard({
    super.key,
    required this.role,
    required this.onToggle,
    this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      onTap: onConfigure,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: role.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(role.icon, color: role.color, size: 22),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(role.name,
                              style: AppTypography.titleMd
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: AppSpacing.stackSm),
                        StatusPill(
                          label: role.system ? 'System' : 'Custom',
                          color: role.system
                              ? AppColors.primary
                              : AppColors.aiAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(role.description, style: AppTypography.bodyMd),
                  ],
                ),
              ),
              Switch(
                value: role.active,
                onChanged: onToggle,
                activeThumbColor: AppColors.onPrimary,
                activeTrackColor: const Color(0xFF3B82F6),
                inactiveThumbColor: AppColors.onSurfaceVariant,
                inactiveTrackColor: AppColors.surfaceContainerHighest,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              _Meta(
                  icon: Icons.people_alt_outlined,
                  text: '${role.userCount} users'),
              const SizedBox(width: AppSpacing.stackMd),
              _Meta(
                  icon: Icons.vpn_key_outlined,
                  text: '${role.permissionCount} permissions'),
              const Spacer(),
              Text('Level ${role.level}',
                  style: AppTypography.labelMd
                      .copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: AppTypography.bodyMd),
      ],
    );
  }
}
