import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import 'school/config/app_pages.dart';
import 'school/config/app_routes.dart';
import 'school/constants/app_strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvConfig.bootstrap(Environment.debug);
  await initSharedServices();

  // School portal auth config.
  AuthConfig.appName = AppStrings.appName;
  // No public schools endpoint yet → login is email + password only.
  AuthConfig.requireInstitution = false;
  AuthConfig.institutionsLoader = null;
  // No backend for forgot/OTP/reset yet → show a graceful message.
  AuthConfig.passwordResetEnabled = false;
  AuthConfig.homeRoute = AppRoutes.home;
  // Route the signed-in user to their module shell based on role.
  AuthConfig.homeRouteResolver = _homeForRoles;

  runApp(const SchoolPortalApp());
}

/// Maps the signed-in user's role codes (from `/auth/me`) to the module shell
/// they should land on. Falls back to [AppRoutes.home] (headmaster) when no
/// known role matches.
String _homeForRoles(List<String> roleCodes) {
  if (roleCodes.contains('headmaster')) return AppRoutes.headmaster;
  if (roleCodes.contains('teacher')) return AppRoutes.teacher;
  if (roleCodes.contains('student')) return AppRoutes.student;
  if (roleCodes.contains('guardian')) return AppRoutes.guardian;
  return AppRoutes.home;
}

class SchoolPortalApp extends StatelessWidget {
  const SchoolPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    return GetMaterialApp(
      title: '${AppStrings.appName} — School Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Restored session → role-based home, else login.
      initialRoute: auth.isLoggedIn.value
          ? _homeForRoles(auth.roleCodes)
          : AuthRoutes.login,
      getPages: [
        ...AuthRoutes.pages,
        ...AppPages.pages,
      ],
    );
  }
}
