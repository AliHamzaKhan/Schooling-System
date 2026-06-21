import 'package:flutter/material.dart';

import '../../../ui/tokens/app_colors.dart';
import '../../../ui/tokens/app_typography.dart';

/// Text link with an optional leading/trailing icon — "Back to Login",
/// "Cancel and return to Login", "Resend Verification Code", etc.
class AuthLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color? color;
  final bool emphasized;

  const AuthLinkButton({
    super.key,
    required this.label,
    required this.onTap,
    this.leadingIcon,
    this.trailingIcon,
    this.color,
    this.emphasized = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? (emphasized ? AppColors.onSurface : AppColors.primary);
    final style = AppTypography.labelMd.copyWith(
      color: c,
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
      fontSize: 14,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 18, color: c),
              const SizedBox(width: 8),
            ],
            Text(label, style: style),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, size: 18, color: c),
            ],
          ],
        ),
      ),
    );
  }
}
