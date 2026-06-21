import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../controller/matrix_controller.dart';
import '../models/matrix_models.dart';

/// Role-based matrix table: permissions as rows (grouped by category), roles as
/// columns. Horizontally scrollable; the permission column is fixed-width and
/// the role columns carry tappable grant cells. Column headers toggle a whole
/// role at once.
class MatrixTable extends StatelessWidget {
  final MatrixController controller;
  const MatrixTable({super.key, required this.controller});

  static const double _labelW = 150;
  static const double _cellW = 76;

  @override
  Widget build(BuildContext context) {
    final m = controller.matrix.value!;
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackSm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderRow(roles: m.roles, controller: controller),
            const SizedBox(height: AppSpacing.stackSm),
            for (final cat in m.categories) ...[
              _CategoryRow(category: cat, width: _totalWidth(m)),
              for (final p in cat.permissions)
                _PermRow(perm: p, roles: m.roles, controller: controller),
            ],
          ],
        ),
      ),
    );
  }

  double _totalWidth(PermissionMatrix m) =>
      _labelW + m.roles.length * _cellW;
}

class _HeaderRow extends StatelessWidget {
  final List<MatrixRole> roles;
  final MatrixController controller;
  const _HeaderRow({required this.roles, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: MatrixTable._labelW),
        for (final r in roles)
          SizedBox(
            width: MatrixTable._cellW,
            child: Obx(() {
              final focused = controller.focusRoleId == r.id;
              return GestureDetector(
                onTap: () => controller.setRoleAll(
                    r.id, !_allGranted(controller, r.id)),
                child: Column(
                  children: [
                    Icon(r.icon,
                        size: 18,
                        color:
                            focused ? AppColors.primary : AppColors.onSurface),
                    const SizedBox(height: 2),
                    Text(r.shortLabel,
                        style: AppTypography.labelMd.copyWith(
                          fontWeight:
                              focused ? FontWeight.w800 : FontWeight.w600,
                          color: focused
                              ? AppColors.primary
                              : AppColors.onSurface,
                        )),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }

  bool _allGranted(MatrixController c, String role) {
    final m = c.matrix.value!;
    for (final cat in m.categories) {
      for (final p in cat.permissions) {
        if (!c.isGranted(p.key, role)) return false;
      }
    }
    return true;
  }
}

class _CategoryRow extends StatelessWidget {
  final MatrixCategory category;
  final double width;
  const _CategoryRow({required this.category, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(top: AppSpacing.stackSm, bottom: 4),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.stackSm, vertical: 6),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(category.icon, size: 15, color: category.color),
          const SizedBox(width: 6),
          Text(category.title,
              style: AppTypography.labelMd.copyWith(
                  color: category.color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  final MatrixPermission perm;
  final List<MatrixRole> roles;
  final MatrixController controller;
  const _PermRow(
      {required this.perm, required this.roles, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: MatrixTable._labelW,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: Text(perm.label, style: AppTypography.bodyMd),
            ),
          ),
          for (final r in roles)
            SizedBox(
              width: MatrixTable._cellW,
              child: Center(
                child: Obx(() => _Cell(
                      granted: controller.isGranted(perm.key, r.id),
                      onTap: () => controller.toggle(perm.key, r.id),
                    )),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final bool granted;
  final VoidCallback onTap;
  const _Cell({required this.granted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: granted ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: granted ? AppColors.primary : AppColors.outlineVariant,
            width: 1.5,
          ),
        ),
        child: granted
            ? const Icon(Icons.check_rounded,
                size: 18, color: AppColors.onPrimary)
            : null,
      ),
    );
  }
}
