import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import 'school/config/app_pages.dart';
import 'school/config/app_routes.dart';
import 'school/config/image_constant.dart';
import 'school/config/role_home.dart';
import 'school/constants/app_strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvConfig.bootstrap();
  // restoreSession: false — the splash owns the `/auth/me` restore so the first
  // frame is branding rather than a blank window held open by a network call.
  await initSharedServices(restoreSession: false);

  // School portal auth config.
  AuthConfig.appName = AppStrings.appName;
  // Logo above the login form — the asset lives in this package, not `shared`.
  AuthConfig.logoAsset = ImageConstant.appIcon;
  // No public schools endpoint yet → login is email + password only.
  AuthConfig.requireInstitution = false;
  AuthConfig.institutionsLoader = null;
  // No backend for forgot/OTP/reset yet → show a graceful message.
  AuthConfig.passwordResetEnabled = false;
  AuthConfig.homeRoute = AppRoutes.home;
  // Route the signed-in user to their module shell based on role. Returning
  // null falls back to AuthConfig.homeRoute.
  AuthConfig.homeRouteResolver = homeRouteForRoles;

  runApp(const SchoolPortalApp());
}

class SchoolPortalApp extends StatelessWidget {
  const SchoolPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Always the splash: it restores the session and replaces itself with
      // login or the role's module shell.
      initialRoute: AppRoutes.splash,
      getPages: [
        ...AuthRoutes.pages,
        ...AppPages.pages,
      ],
    );
  }
}
