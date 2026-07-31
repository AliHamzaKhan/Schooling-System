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
  static String schoolUsers(String id) => '/schools/$id/users';
  static String schoolHeadmaster(String id) => '/schools/$id/headmaster';

  // ── Platform metrics (Super Admin dashboard + revenue) ──────
  static const adminDashboard = '/admin/dashboard';
  static const adminRevenue = '/admin/revenue';
  static const adminBilling = '/admin/billing';
  static const adminMetrics = '/admin/metrics';

  // ── Subscription plans (editable products) ──────────────────
  static const subscriptionPlans = '/subscription-plans';
  static String subscriptionPlan(String id) => '/subscription-plans/$id';

  // ── Subscription instances (per-school) ─────────────────────
  static const subscriptions = '/subscriptions';
  static String subscriptionRenew(String id) => '/subscriptions/$id/renew';
  static String subscriptionCancel(String id) => '/subscriptions/$id/cancel';
}
