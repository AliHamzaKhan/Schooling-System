import 'package:get/get.dart';

import '../../../../services/auth_service.dart';
import '../../auth_config.dart';
import '../../auth_routes.dart';

/// Requests a verification code for the entered email/phone, then routes to the
/// OTP screen carrying the identifier forward.
class ForgotPasswordController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  /// Field value. Its `TextEditingController` is owned by [ForgotPasswordView]'s
  /// State, so it is disposed with the screen.
  final identifier = ''.obs;
  final submitting = false.obs;
  final error = RxnString();

  Future<void> sendCode() async {
    error.value = null;
    if (!AuthConfig.passwordResetEnabled) {
      error.value =
          'Password reset isn\'t available yet. Please contact your administrator.';
      return;
    }
    final entered = identifier.value.trim();
    if (entered.isEmpty) {
      error.value = 'Enter your email or phone number.';
      return;
    }

    submitting.value = true;
    try {
      final res = await _auth.forgotPassword(email: entered);
      if (res.success) {
        Get.toNamed(AuthRoutes.verifyOtp, arguments: {'email': entered});
      } else {
        error.value = res.error ?? 'Could not send a code. Try again.';
      }
    } catch (_) {
      error.value = 'Something went wrong. Please try again.';
    } finally {
      submitting.value = false;
    }
  }

  void backToLogin() => Get.offNamedUntil(
        AuthRoutes.login,
        (route) => false,
      );
}
