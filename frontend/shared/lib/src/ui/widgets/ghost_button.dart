import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_elevation.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_typography.dart';

/// Secondary / ghost button — glass-filled with a 1 px border.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool expanded;

  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final btn = AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: AppElevation.l1Fill,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.outlineVariant, width: 1),
            ),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, color: AppColors.onSurface, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, color: AppColors.onSurface, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
