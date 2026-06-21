import 'dart:async';

import 'package:get/get.dart';

import '../../../../services/auth_service.dart';
import '../../auth_routes.dart';

/// Verifies the 6-digit code sent to [email]. On success it carries the
/// backend `reset_token` forward to the reset-password screen.
class VerifyOtpController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  static const codeLength = 6;

  String email = '';
  final code = ''.obs;
  final submitting = false.obs;
  final error = RxnString();

  // Resend cooldown.
  final secondsLeft = 0.obs;
  Timer? _timer;

  bool get canVerify => code.value.length == codeLength;
  bool get canResend => secondsLeft.value == 0;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['email'] is String) email = args['email'] as String;
    _startCooldown();
  }

  void onCodeChanged(String value) {
    code.value = value;
    if (error.value != null) error.value = null;
  }

  void _startCooldown([int seconds = 30]) {
    _timer?.cancel();
    secondsLeft.value = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft.value <= 1) {
        secondsLeft.value = 0;
        t.cancel();
      } else {
        secondsLeft.value--;
      }
    });
  }

  Future<void> verify() async {
    if (!canVerify) {
      error.value = 'Enter the $codeLength-digit code.';
      return;
    }
    error.value = null;
    submitting.value = true;
    try {
      final res = await _auth.verifyOtp(email: email, code: code.value);
      if (res.success) {
        final resetToken =
            res.rawJson?['reset_token'] as String? ?? code.value;
        Get.toNamed(AuthRoutes.resetPassword,
            arguments: {'email': email, 'token': resetToken});
      } else {
        error.value = res.error ?? 'Invalid or expired code.';
      }
    } catch (_) {
      error.value = 'Something went wrong. Please try again.';
    } finally {
      submitting.value = false;
    }
  }

  Future<void> resend() async {
    if (!canResend) return;
    await _auth.forgotPassword(email: email);
    _startCooldown();
  }

  void changeEmail() => Get.back();

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
