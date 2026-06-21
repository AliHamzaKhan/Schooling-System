import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../models/permission_models.dart';

/// Horizontal, single-select role chips with leading icons. The selected role
/// fills navy; the rest are glass pills.
class RoleTabs extends StatelessWidget {
  final List<PermissionRole> roles;
  final String selectedId;
  final ValueChanged<PermissionRole> onSelected;

  const RoleTabs({
    super.key,
    required this.roles,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: roles.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.stackMd),
        itemBuilder: (context, i) {
          final role = roles[i];
          final selected = role.id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(role),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackLg),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.outlineVariant,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(role.icon,
                      size: 18,
                      color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.stackSm),
                  Text(
                    role.label,
                    style: AppTypography.titleMd.copyWith(
                      color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
