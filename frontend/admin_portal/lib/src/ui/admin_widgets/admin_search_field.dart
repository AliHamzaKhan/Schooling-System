import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Rounded white search pill used at the top of list screens. Optional trailing
/// [action] (e.g. a filter/tune button) sits to the right, outside the field.
class AdminSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final Widget? action;

  const AdminSearchField({
    super.key,
    this.hint = 'Search…',
    this.onChanged,
    this.controller,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final field = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: AppColors.outline),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTypography.bodyLg.copyWith(color: AppColors.outline),
                isCollapsed: true,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );

    if (action == null) return field;
    return Row(
      children: [
        Expanded(child: field),
        const SizedBox(width: AppSpacing.stackSm),
        action!,
      ],
    );
  }
}

/// Square icon button sized to match [AdminSearchField] (used for filter/tune).
class AdminIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const AdminIconButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.outlineVariant, width: 1),
          ),
          child: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}
