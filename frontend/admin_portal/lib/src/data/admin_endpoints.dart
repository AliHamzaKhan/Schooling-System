/// Centralized backend paths for the admin (super-admin) portal. Never hardcode
/// endpoint strings in services — add them here.
///
/// All school routes are gated to Super Admin on the backend.
class AdminEndpoints {
  AdminEndpoints._();

  static const schools = '/schools';
  static String school(String id) => '/schools/$id';
  static String schoolStatus(String id) => '/schools/$id/status';
  static String schoolSubscription(String id) => '/schools/$id/subscription';
  static String schoolModules(String id) => '/schools/$id/modules';
}
