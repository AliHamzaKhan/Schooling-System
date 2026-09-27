import 'auth_config.dart';
import 'auth_routes.dart';

/// Only registered in-app paths can survive a login/restore round trip.
class SessionNavigation {
  static Set<String> routes = {};
  static String? safeTarget(String? value) {
    if (value == null || !value.startsWith('/') || value.startsWith('//') || value.contains('\\')) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.hasScheme || uri.hasAuthority || uri.hasFragment || !routes.contains(uri.path)) return null;
    if (AuthRoutes.pages.any((page) => page.name == uri.path)) return null;
    return uri.toString();
  }
  static String loginFor(String? target) => _withTarget(AuthRoutes.login, target);
  static String restoreFor(String? target) => _withTarget(AuthRoutes.restore, target);
  static String _withTarget(String route, String? target) {
    final safe = safeTarget(target);
    return safe == null ? route : Uri(path: route, queryParameters: {'returnTo': safe}).toString();
  }
  static String destination(List<String> roles, String? target) => safeTarget(target) ??
      AuthConfig.homeRouteResolver?.call(roles) ?? AuthConfig.homeRoute;
}
