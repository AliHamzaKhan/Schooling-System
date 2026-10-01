import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../ui/tokens/app_colors.dart';
import '../../../ui/tokens/app_radius.dart';
import '../../../ui/tokens/app_spacing.dart';
import '../../../ui/tokens/app_typography.dart';
import '../auth_config.dart';
import 'auth_footer.dart';
import 'package:shared/shared.dart';

/// One scaffold for every auth screen so spacing, the brand bar, the card, the
/// background and the footer stay pixel-identical across login / forgot / OTP /
/// reset. Screens only supply their inner card content.
class AuthShell extends StatelessWidget {
  /// Card body — the screen-specific content.
  final Widget child;

  /// Show the leading back button in the top bar (false on the root login).
  final bool showBack;

  /// Optional top-right action (e.g. the "Help Center" pill on Forgot).
  final Widget? action;

  /// Show the brand wordmark in the top bar.
  final bool showBrand;

  /// Retained for caller compatibility; every auth form now uses the same
  /// white surface for contrast over the illustrated color wash.
  final bool showCard;

  const AuthShell({
    super.key,
    required this.child,
    this.showBack = true,
    this.action,
    this.showBrand = true,
    this.showCard = true,
  });

  static const double _maxCardWidth = 440;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0ECFF),
              AppColors.background,
              Color(0xFFEAF7F4),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(showBack: showBack, showBrand: showBrand, action: action),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.containerPaddingMobile,
                    vertical: AppSpacing.stackLg,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _maxCardWidth,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeSlideIn(child: _Card(child: child)),
                          const SizedBox(height: AppSpacing.stackXl),
                          const AuthFooter(),
                          const SizedBox(height: AppSpacing.stackMd),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool showBack;
  final bool showBrand;
  final Widget? action;
  const _TopBar({required this.showBack, required this.showBrand, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        children: [
          if (showBack)
            _CircleIconButton(
              icon: AppIcons.arrowBack,
              tooltip: 'Back',
              onTap: () => Get.back(),
            )
          else
            const SizedBox(width: 4),
          const SizedBox(width: 8),
          if (showBrand)
            Text(
              AuthConfig.appName,
              style: AppTypography.titleLg.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          const Spacer(),
          ?action,
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Icon-only control: named for screen readers, hinted on hover.
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: AppColors.surfaceContainerLowest,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 20, color: AppColors.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
