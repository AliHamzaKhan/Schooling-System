import 'package:get/get.dart';

import 'view/access_denied_view.dart';
import 'view/session_restore_view.dart';

import 'forgot_password/binding/forgot_password_binding.dart';
import 'forgot_password/view/forgot_password_view.dart';
import 'login/binding/login_binding.dart';
import 'login/view/login_view.dart';
import 'reset_password/binding/reset_password_binding.dart';
import 'reset_password/view/reset_password_view.dart';
import 'verify_otp/binding/verify_otp_binding.dart';
import 'verify_otp/view/verify_otp_view.dart';

/// Route names + GetPages for the shared auth flow.
///
/// Both portals spread [AuthRoutes.pages] into their `GetMaterialApp.getPages`
/// and use [AuthRoutes.login] as the initial route when logged out:
/// ```dart
/// getPages: [...AuthRoutes.pages, ...AppRoutes.pages],
/// ```
class AuthRoutes {
  AuthRoutes._();

  static const login = '/login';
  static const restore = '/restore-session';
  static const accessDenied = '/access-denied';
  static const forgotPassword = '/forgot-password';
  static const verifyOtp = '/verify-otp';
  static const resetPassword = '/reset-password';

  static final pages = <GetPage>[
    GetPage(name: restore, page: () => const SessionRestoreView()),
    GetPage(name: accessDenied, page: () => const AccessDeniedView()),
    GetPage(
      name: login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: verifyOtp,
      page: () => const VerifyOtpView(),
      binding: VerifyOtpBinding(),
    ),
    GetPage(
      name: resetPassword,
      page: () => const ResetPasswordView(),
      binding: ResetPasswordBinding(),
    ),
  ];
}
