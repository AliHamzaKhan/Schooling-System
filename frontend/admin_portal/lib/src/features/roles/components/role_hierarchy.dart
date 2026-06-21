import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/role_models.dart';

/// Hierarchical permission visualization — renders roles as authority tiers
/// (level 0 at the top), each tier a row of chips, connected by a vertical
/// spine. Higher tiers inherit/oversee the tiers below.
class RoleHierarchy extends StatelessWidget {
  final List<MapEntry<int, List<ManagedRole>>> levels;
  const RoleHierarchy({super.key, required this.levels});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.stackSm),
              Text('Permission Hierarchy',
                  style: AppTypography.titleMd
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          for (var i = 0; i < levels.length; i++)
            _Tier(
              level: levels[i].key,
              roles: levels[i].value,
              isLast: i == levels.length - 1,
            ),
        ],
      ),
    );
  }
}

class _Tier extends StatelessWidget {
  final int level;
  final List<ManagedRole> roles;
  final bool isLast;
  const _Tier(
      {required this.level, required this.roles, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: Text('L$level',
                    style: AppTypography.labelMd.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 10)),
              ),
              if (!isLast)
                Expanded(
                    child: Container(width: 2, color: AppColors.outlineVariant)),
            ],
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.stackLg),
              child: Wrap(
                spacing: AppSpacing.stackSm,
                runSpacing: AppSpacing.stackSm,
                children: [
                  for (final r in roles) _RoleChip(role: r),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final ManagedRole role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final c = role.active ? role.color : AppColors.onSurfaceVariant;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(role.icon, size: 14, color: c),
          const SizedBox(width: 5),
          Text(role.name,
              style: AppTypography.labelMd
                  .copyWith(color: c, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
