import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_portal/school/config/headmaster_pages.dart';
import 'package:shared/shared.dart';

import 'src/app/admin_routes.dart';
import 'src/app/portal_access.dart';
import 'src/ui/admin_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvConfig.bootstrap();
  await initSharedServices(restoreSession: false);

  // This executable hosts both control planes: platform administration for a
  // super admin and school administration for a headmaster.
  AuthConfig.appName = 'Meri Taleem';
  AuthConfig.requireInstitution = false;
  AuthConfig.institutionsLoader = null;
  // The backend now exposes the complete forgot/OTP/reset flow.
  AuthConfig.passwordResetEnabled = true;
  AuthConfig.homeRoute = AdminRoutes.home;
  AuthConfig.homeRouteResolver = portalHomeForRoles;

  runApp(const AdminPortalApp());
}

class AdminPortalApp extends StatelessWidget {
  const AdminPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = [...AuthRoutes.pages, ...AdminRoutes.pages, ...HeadmasterPages.pages];
    SessionNavigation.routes = pages.map((page) => page.name).toSet();
    return GetMaterialApp(
      title: 'Meri Taleem — Admin Portal',
      debugShowCheckedModeBanner: false,
      theme: adminTheme(),
      initialRoute: SessionNavigation.restoreFor(Uri.base.fragment),
      getPages: [
        ...AuthRoutes.pages,
        ...AdminRoutes.pages,
        ...HeadmasterPages.pages,
      ],
    );
  }
}
