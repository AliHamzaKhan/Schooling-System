import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../ui/tokens/app_colors.dart';
import '../../../../ui/tokens/app_radius.dart';
import '../../../../ui/tokens/app_spacing.dart';
import '../../../../ui/tokens/app_typography.dart';
import '../../../../ui/widgets/glass_input.dart';
import '../../../../ui/widgets/primary_button.dart';
import '../../../../ui/forms/screen_text_controllers.dart';
import '../../auth_config.dart';
import '../../components/auth_shell.dart';
import '../components/institution_dropdown.dart';
import '../components/remember_me_checkbox.dart';
import '../controller/login_controller.dart';
import 'package:shared/shared.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with ScreenTextControllers {
  final controller = Get.find<LoginController>();

  // Owned by this screen: created here, disposed with it.
  late final _emailCtrl = boundController(controller.email);
  late final _passwordCtrl = boundController(controller.password);

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      showBack: false,
      // The brand sits in the body now, and the fields stand on the background
      // instead of inside a card.
      showBrand: false,
      showCard: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandMark(),
          const SizedBox(height: AppSpacing.stackXl),

          Text('Login', style: AppTypography.displayLg),
          const SizedBox(height: AppSpacing.stackLg),

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
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: AppIcons.alternateEmail,
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
                controller: _passwordCtrl,
                obscureText: controller.obscurePassword.value,
                prefixIcon: AppIcons.lockOutline,
                onSubmitted: (_) => controller.submit(),
                suffix: IconButton(
                  splashRadius: 18,
                  icon: Icon(
                    controller.obscurePassword.value
                        ? AppIcons.visibilityOutlined
                        : AppIcons.visibilityOffOutlined,
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
                canStorePassword: controller.canRememberPassword,
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
        ],
      ),
    );
  }
}

/// Logo + app name above the form. Uses [AuthConfig.logoAsset] when the host app
/// bundles one, and falls back to a tinted icon mark when it doesn't.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  static const double _size = 76;

  @override
  Widget build(BuildContext context) {
    final asset = AuthConfig.logoAsset;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: asset == null
                ? Container(
                    width: _size,
                    height: _size,
                    color: AppColors.primary.withValues(alpha: 0.10),
                    child: const Icon(AppIcons.schoolRounded,
                        size: 40, color: AppColors.primary),
                  )
                : Image.asset(
                    asset,
                    width: _size,
                    height: _size,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            AuthConfig.appName,
            textAlign: TextAlign.center,
            style: AppTypography.headlineLg.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
