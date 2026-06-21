import 'package:flutter/material.dart';

import '../../../ui/tokens/app_colors.dart';
import '../../../ui/tokens/app_spacing.dart';
import '../../../ui/tokens/app_typography.dart';
import '../auth_config.dart';

/// Shared footer for every auth screen — copyright line + Privacy / Terms /
/// Support links. Kept identical across login/forgot/otp/reset for consistency.
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '© ${AuthConfig.copyrightYear} ${AuthConfig.appName.toUpperCase()}. ALL RIGHTS RESERVED.',
          textAlign: TextAlign.center,
          style: AppTypography.labelCaps.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _FooterLink('Privacy'),
            SizedBox(width: AppSpacing.stackLg),
            _FooterLink('Terms'),
            SizedBox(width: AppSpacing.stackLg),
            _FooterLink('Support'),
          ],
        ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  const _FooterLink(this.label);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(label,
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
      ),
    );
  }
}
