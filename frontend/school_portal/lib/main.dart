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

  // School portal: users pick their institution and land on the school home.
  AuthConfig.appName = AppStrings.appName;
  AuthConfig.requireInstitution = true;
  AuthConfig.homeRoute = AppRoutes.home;

  runApp(const SchoolPortalApp());
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
      initialRoute: auth.isLoggedIn.value ? AppRoutes.home : AuthRoutes.login,
      getPages: [
        ...AuthRoutes.pages,
        ...AppPages.pages,
      ],
    );
  }
}
