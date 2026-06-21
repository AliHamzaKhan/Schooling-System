import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../services/auth_service.dart';
import '../../../../ui/tokens/app_colors.dart';
import '../../auth_routes.dart';
import '../../models/password_strength.dart';

/// Handles the "Create New Password" step: live strength/requirements feedback,
/// confirmation match, and the reset call using the token from the OTP step.
class ResetPasswordController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  String email = '';
  String token = '';

  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  final password = ''.obs;
  final confirm = ''.obs;
  final obscureNew = true.obs;
  final obscureConfirm = true.obs;
  final submitting = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      email = (args['email'] as String?) ?? '';
      token = (args['token'] as String?) ?? '';
    }
  }

  PasswordStrength get strength => PasswordStrength.of(password.value);
  bool get rulesPass => passwordMeetsAllRules(password.value);
  bool get matches => confirm.value.isNotEmpty && password.value == confirm.value;
  bool get canSubmit => rulesPass && matches;

  void onPasswordChanged(String v) {
    password.value = v;
    if (error.value != null) error.value = null;
  }

  void onConfirmChanged(String v) => confirm.value = v;
  void toggleNew() => obscureNew.toggle();
  void toggleConfirm() => obscureConfirm.toggle();

  Future<void> submit() async {
    if (!rulesPass) {
      error.value = 'Password does not meet the requirements.';
      return;
    }
    if (!matches) {
      error.value = 'Passwords do not match.';
      return;
    }
    error.value = null;
    submitting.value = true;
    try {
      final res = await _auth.resetPassword(token: token, newPassword: password.value);
      if (res.success) {
        Get.offNamedUntil(AuthRoutes.login, (route) => false);
        Get.snackbar(
          'Password updated',
          'You can now sign in with your new password.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primary,
          colorText: AppColors.onPrimary,
          margin: const EdgeInsets.all(16),
        );
      } else {
        error.value = res.error ?? 'Could not reset password. Try again.';
      }
    } catch (_) {
      error.value = 'Something went wrong. Please try again.';
    } finally {
      submitting.value = false;
    }
  }

  void cancel() => Get.offNamedUntil(AuthRoutes.login, (route) => false);

  @override
  void onClose() {
    newCtrl.dispose();
    confirmCtrl.dispose();
    super.onClose();
  }
}
