import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Rounded white search pill used at the top of list screens.
class PortalSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const PortalSearchField({
    super.key,
    this.hint = 'Search…',
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
  }
}
