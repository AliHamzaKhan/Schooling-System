import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import 'auth_routes.dart';

/// Client-side route boundary for role-specific portal surfaces.
///
/// Backend permissions remain authoritative. This guard prevents users from
/// opening another role's navigation and forms through a copied web URL.
class RoleRouteGuard extends GetMiddleware {
  final Set<String> allowedRoles;

  RoleRouteGuard(this.allowedRoles, {super.priority = -10});

  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AuthService>()) {
      return const RouteSettings(name: AuthRoutes.login);
    }

    final auth = Get.find<AuthService>();
    if (!auth.isLoggedIn.value) {
      return const RouteSettings(name: AuthRoutes.login);
    }

    if (auth.roleCodes.any(allowedRoles.contains)) return null;
    return const RouteSettings(name: AuthRoutes.accessDenied);
  }
}
