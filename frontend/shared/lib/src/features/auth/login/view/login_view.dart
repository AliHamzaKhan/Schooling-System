import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../ui/tokens/app_colors.dart';
import '../../../../ui/tokens/app_spacing.dart';
import '../../../../ui/tokens/app_typography.dart';
import '../../../../ui/widgets/glass_input.dart';
import '../../../../ui/widgets/primary_button.dart';
import '../../auth_config.dart';
import '../../components/auth_shell.dart';
import '../components/institution_dropdown.dart';
import '../components/remember_me_checkbox.dart';
import '../controller/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome Back', style: AppTypography.displayLg),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            'Please select your role and enter your credentials to continue.',
            style: AppTypography.bodyLg,
          ),
          const SizedBox(height: AppSpacing.stackXl),

          // Institution (school portal only).
          if (controller.requireInstitution) ...[
            Obx(() => InstitutionDropdown(
                  items: controller.institutions,
                  value: controller.selectedInstitution.value,
                  onChanged: controller.selectInstitution,
                  loading: controller.loadingInstitutions.value,
                )),
            const SizedBox(height: AppSpacing.stackLg),
          ],

          // Email / username.
          GlassInput(
            label: 'Email or Username',
            hint: 'name@school.edu',
            controller: controller.emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.alternate_email,
          ),
          const SizedBox(height: AppSpacing.stackLg),

          // Password label + forgot link.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PASSWORD',
                  style: AppTypography.labelCaps
                      .copyWith(color: AppColors.onSurfaceVariant)),
              GestureDetector(
                onTap: controller.goToForgotPassword,
                child: Text('Forgot Password?',
                    style: AppTypography.labelMd
                        .copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Obx(() => GlassInput(
                hint: '••••••••',
                controller: controller.passwordCtrl,
                obscureText: controller.obscurePassword.value,
                prefixIcon: Icons.lock_outline,
                onSubmitted: (_) => controller.submit(),
                suffix: IconButton(
                  splashRadius: 18,
                  icon: Icon(
                    controller.obscurePassword.value
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onPressed: controller.toggleObscure,
                ),
              )),
          const SizedBox(height: AppSpacing.stackMd),

          Obx(() => RememberMeCheckbox(
                value: controller.rememberMe.value,
                onChanged: controller.toggleRemember,
              )),

          // Error.
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
                label: 'Secure Login',
                expanded: true,
                isLoading: controller.submitting.value,
                onPressed: controller.submit,
              )),
          const SizedBox(height: AppSpacing.stackXl),

          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.stackLg),

          Center(
            child: Text.rich(
              TextSpan(
                text: 'New to ${AuthConfig.appName}? ',
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                children: [
                  TextSpan(
                    text: 'Contact your administrator',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
