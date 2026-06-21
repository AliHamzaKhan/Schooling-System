import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../ui/tokens/app_colors.dart';
import '../../../../ui/tokens/app_radius.dart';
import '../../../../ui/tokens/app_spacing.dart';
import '../../../../ui/tokens/app_typography.dart';
import '../../../../ui/widgets/glass_input.dart';
import '../../../../ui/widgets/primary_button.dart';
import '../../components/auth_icon_badge.dart';
import '../../components/auth_link_button.dart';
import '../../components/auth_shell.dart';
import '../../components/or_divider.dart';
import '../controller/forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      action: const _HelpCenterPill(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AuthIconBadge(icon: Icons.lock_reset)),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Forgot Password?',
              textAlign: TextAlign.center, style: AppTypography.headlineLg),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            'Enter your email or phone number to receive a verification code',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLg,
          ),
          const SizedBox(height: AppSpacing.stackXl),

          GlassInput(
            label: 'Email or phone number',
            hint: 'name@university.edu',
            controller: controller.identifierCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline,
            onSubmitted: (_) => controller.sendCode(),
          ),

          Obx(() {
            final err = controller.error.value;
            if (err == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.stackSm),
              child: Text(err,
                  style: AppTypography.bodySm.copyWith(color: AppColors.error)),
            );
          }),
          const SizedBox(height: AppSpacing.stackLg),

          Obx(() => PrimaryButton(
                label: 'Send Code',
                expanded: true,
                isLoading: controller.submitting.value,
                onPressed: controller.sendCode,
              )),
          const SizedBox(height: AppSpacing.stackXl),

          const OrDivider(),
          const SizedBox(height: AppSpacing.stackMd),
          Center(
            child: AuthLinkButton(
              label: 'Back to Login',
              leadingIcon: Icons.arrow_back,
              onTap: controller.backToLogin,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpCenterPill extends StatelessWidget {
  const _HelpCenterPill();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Help Center',
              style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
        ),
      ),
    );
  }
}
