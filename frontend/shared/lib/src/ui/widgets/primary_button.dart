import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_typography.dart';
import '../../assets/app_icons.dart';

/// Primary action button — vertical gradient from `primary` to a darker shade.
///
/// 12 px radius per DESIGN.md ("sophisticated squircle feel").
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final IconData? leadingIcon;
  final bool isLoading;
  final bool expanded;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.trailingIcon = AppIcons.arrowForward,
    this.leadingIcon,
    this.isLoading = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final labelWidget = Text(
      label,
      textAlign: TextAlign.center,
      style: AppTypography.bodyLg.copyWith(
        color: AppColors.onPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
    final btn = AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.primaryGradientEnd],
              ),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, color: AppColors.onPrimary, size: 18),
                  const SizedBox(width: 8),
                ],
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                else if (expanded)
                  Flexible(child: labelWidget)
                else
                  labelWidget,
                if (trailingIcon != null && !isLoading) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, color: AppColors.onPrimary, size: 18),
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
