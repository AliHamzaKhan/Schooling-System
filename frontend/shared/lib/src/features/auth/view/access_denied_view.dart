import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/auth_service.dart';
import '../../../ui/tokens/app_colors.dart';
import '../../../ui/tokens/app_radius.dart';
import '../../../ui/tokens/app_spacing.dart';
import '../../../ui/tokens/app_typography.dart';
import '../../../ui/widgets/primary_button.dart';
import '../auth_routes.dart';

/// Safe landing page when a valid account opens a portal route its role does
/// not own. We keep the session long enough to explain the problem, then offer
/// an explicit account switch.
class AccessDeniedView extends StatelessWidget {
  const AccessDeniedView({super.key});

  Future<void> _signOut() async {
    if (Get.isRegistered<AuthService>()) {
      await Get.find<AuthService>().logout();
    }
    Get.offAllNamed(AuthRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final roles = Get.isRegistered<AuthService>()
        ? Get.find<AuthService>().roleCodes.join(', ')
        : '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.containerPaddingMobile),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.stackXl),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: .10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.error,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    Text(
                      'This portal is not assigned to your account',
                      textAlign: TextAlign.center,
                      style: AppTypography.titleLg,
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(
                      roles.isEmpty
                          ? 'Your account has no supported role. Contact your administrator or sign in with another account.'
                          : 'Signed in as $roles. Use the portal assigned to that role, or switch accounts.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLg.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackXl),
                    PrimaryButton(label: 'Switch account', onPressed: _signOut),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
