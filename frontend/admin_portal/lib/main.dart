import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import 'src/app/admin_routes.dart';
import 'src/ui/admin_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvConfig.bootstrap(Environment.debug);
  await initSharedServices();

  // Admin portal: super-admin controls every school — no institution picker.
  AuthConfig.appName = 'Meri Taleem';
  AuthConfig.requireInstitution = false;
  AuthConfig.institutionsLoader = null;
  // No backend for forgot/OTP/reset yet → show a graceful message.
  AuthConfig.passwordResetEnabled = false;
  AuthConfig.homeRoute = AdminRoutes.home;

  runApp(const AdminPortalApp());
}

class AdminPortalApp extends StatelessWidget {
  const AdminPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    return GetMaterialApp(
      title: 'Meri Taleem — Admin Portal',
      debugShowCheckedModeBanner: false,
      theme: adminTheme(),
      initialRoute: auth.isLoggedIn.value ? AdminRoutes.home : AuthRoutes.login,
      getPages: [
        ...AuthRoutes.pages,
        ...AdminRoutes.pages,
      ],
    );
  }
}
