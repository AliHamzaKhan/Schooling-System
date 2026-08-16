import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../ui/tokens/app_colors.dart';
import '../../../../ui/tokens/app_spacing.dart';
import '../../../../ui/tokens/app_typography.dart';
import '../../../../ui/widgets/glass_input.dart';
import '../../../../ui/widgets/primary_button.dart';
import '../../components/auth_icon_badge.dart';
import '../../components/auth_link_button.dart';
import '../../components/auth_shell.dart';
import '../../../../ui/forms/screen_text_controllers.dart';
import '../components/password_requirements.dart';
import '../components/password_strength_bar.dart';
import '../controller/reset_password_controller.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView>
    with ScreenTextControllers {
  final controller = Get.find<ResetPasswordController>();

  late final _newCtrl = textController();
  late final _confirmCtrl = textController();

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AuthIconBadge(icon: Icons.lock_reset, size: 56)),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Create New Password',
              textAlign: TextAlign.center, style: AppTypography.headlineLg),
          const SizedBox(height: AppSpacing.stackSm),
          Text('Choose a strong password for your account.',
              textAlign: TextAlign.center, style: AppTypography.bodyLg),
          const SizedBox(height: AppSpacing.stackXl),

          // New password.
          Obx(() => GlassInput(
                label: 'New Password',
                hint: 'Enter new password',
                controller: _newCtrl,
                obscureText: controller.obscureNew.value,
                onChanged: controller.onPasswordChanged,
                suffix: _EyeButton(
                  obscured: controller.obscureNew.value,
                  onPressed: controller.toggleNew,
                ),
              )),
          const SizedBox(height: AppSpacing.stackSm),
          Obx(() => PasswordStrengthBar(strength: controller.strength)),
          const SizedBox(height: AppSpacing.stackLg),

          // Confirm password.
          Obx(() => GlassInput(
                label: 'Confirm Password',
                hint: 'Re-enter password',
                controller: _confirmCtrl,
                obscureText: controller.obscureConfirm.value,
                onChanged: controller.onConfirmChanged,
                errorText: (controller.confirm.value.isNotEmpty &&
                        !controller.matches)
                    ? 'Passwords do not match'
                    : null,
                suffix: _EyeButton(
                  obscured: controller.obscureConfirm.value,
                  onPressed: controller.toggleConfirm,
                ),
              )),
          const SizedBox(height: AppSpacing.stackLg),

          Obx(() => PasswordRequirements(password: controller.password.value)),

          Obx(() {
            final err = controller.error.value;
            if (err == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.stackMd),
              child: Text(err,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm.copyWith(color: AppColors.error)),
            );
          }),
          const SizedBox(height: AppSpacing.stackLg),

          Obx(() => PrimaryButton(
                label: 'Reset Password',
                expanded: true,
                trailingIcon: null,
                isLoading: controller.submitting.value,
                onPressed: controller.submit,
              )),
          const SizedBox(height: AppSpacing.stackMd),

          Center(
            child: AuthLinkButton(
              label: 'Cancel and return to Login',
              leadingIcon: Icons.logout,
              onTap: controller.cancel,
            ),
          ),
        ],
      ),
    );
  }
}

class _EyeButton extends StatelessWidget {
  final bool obscured;
  final VoidCallback onPressed;
  const _EyeButton({required this.obscured, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      splashRadius: 18,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: AppColors.onSurfaceVariant,
      ),
      onPressed: onPressed,
    );
  }
}
