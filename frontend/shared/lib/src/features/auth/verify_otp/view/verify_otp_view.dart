import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../ui/tokens/app_colors.dart';
import '../../../../ui/tokens/app_spacing.dart';
import '../../../../ui/tokens/app_typography.dart';
import '../../../../ui/widgets/primary_button.dart';
import '../../components/auth_icon_badge.dart';
import '../../components/auth_link_button.dart';
import '../../components/auth_shell.dart';
import '../controller/verify_otp_controller.dart';
import '../components/otp_input.dart';
import 'package:shared/shared.dart';

class VerifyOtpView extends GetView<VerifyOtpController> {
  const VerifyOtpView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AuthIconBadge(icon: AppIcons.verifiedUserOutlined)),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Verify Your Account',
              textAlign: TextAlign.center, style: AppTypography.headlineLg),
          const SizedBox(height: AppSpacing.stackSm),
          Text.rich(
            TextSpan(
              text: "We've sent a 6-digit code to\n",
              style: AppTypography.bodyLg,
              children: [
                TextSpan(
                  text: controller.email,
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.stackXl),

          OtpInput(
            length: VerifyOtpController.codeLength,
            onChanged: controller.onCodeChanged,
            onCompleted: controller.verify,
          ),

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

          Obx(() => Center(
                child: AuthLinkButton(
                  label: controller.canResend
                      ? 'Resend Verification Code'
                      : 'Resend in ${controller.secondsLeft.value}s',
                  emphasized: false,
                  onTap: controller.resend,
                ),
              )),
          Center(
            child: AuthLinkButton(
              label: 'Change Email Address',
              emphasized: false,
              onTap: controller.changeEmail,
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),

          Obx(() => PrimaryButton(
                label: 'Verify',
                expanded: true,
                trailingIcon: null,
                isLoading: controller.submitting.value,
                onPressed: controller.verify,
              )),
          const SizedBox(height: AppSpacing.stackLg),

          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(AppIcons.shieldOutlined,
                  size: 16, color: AppColors.outline),
              const SizedBox(width: 8),
              Text('SECURE ACADEMIC GATEWAY',
                  style: AppTypography.labelCaps.copyWith(color: AppColors.outline)),
            ],
          ),
        ],
      ),
    );
  }
}
