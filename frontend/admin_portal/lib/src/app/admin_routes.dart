import 'package:get/get.dart';

import '../features/headmasters/binding/headmasters_binding.dart';
import '../features/headmasters/view/headmasters_view.dart';
import '../features/feature_access/binding/feature_access_binding.dart';
import '../features/feature_access/view/feature_access_view.dart';
import '../features/permission_matrix/binding/matrix_binding.dart';
import '../features/permission_matrix/view/matrix_view.dart';
import '../features/permissions/role_policy/binding/role_policy_binding.dart';
import '../features/permissions/role_policy/view/role_policy_view.dart';
import '../features/roles/binding/roles_binding.dart';
import '../features/roles/view/roles_view.dart';
import '../features/school_settings/binding/school_settings_binding.dart';
import '../features/school_settings/view/school_settings_view.dart';
import '../features/subscription_settings/binding/subscription_settings_binding.dart';
import '../features/subscription_settings/view/subscription_settings_view.dart';
import '../features/permissions/school_permissions/binding/school_permissions_binding.dart';
import '../features/permissions/school_permissions/view/school_permissions_view.dart';
import '../features/schools/create/binding/create_school_binding.dart';
import '../features/schools/create/view/create_school_view.dart';
import '../features/subscriptions/binding/subscriptions_binding.dart';
import '../features/subscriptions/view/subscriptions_view.dart';
import 'admin_shell.dart';

/// Route names + GetPages for the admin portal's authenticated area.
///
/// Spread [AdminRoutes.pages] into `GetMaterialApp.getPages` alongside
/// `AuthRoutes.pages`. [home] is the shell that hosts the bottom-nav tabs;
/// drill-in screens (permissions, plan editor, …) get their own routes.
class AdminRoutes {
  AdminRoutes._();

  static const home = '/home';
  static const createSchool = '/schools/create';
  static const subscriptions = '/subscriptions';
  static const headmasters = '/headmasters';
  static const rolePolicy = '/permissions/role';
  static const schoolPermissions = '/permissions/schools';
  static const roles = '/permissions/roles';
  static const permissionMatrix = '/permissions/matrix';
  static const featureAccess = '/permissions/features';
  static const schoolSettings = '/settings/school';
  static const subscriptionSettings = '/settings/subscription';

  static final pages = <GetPage>[
    GetPage(name: home, page: () => const AdminShell()),
    GetPage(
      name: createSchool,
      page: () => const CreateSchoolView(),
      binding: CreateSchoolBinding(),
      fullscreenDialog: true,
    ),
    GetPage(
      name: subscriptions,
      page: () => const SubscriptionsView(),
      binding: SubscriptionsBinding(),
    ),
    GetPage(
      name: headmasters,
      page: () => const HeadmastersView(),
      binding: HeadmastersBinding(),
    ),
    GetPage(
      name: rolePolicy,
      page: () => const RolePolicyView(),
      binding: RolePolicyBinding(),
    ),
    GetPage(
      name: schoolPermissions,
      page: () => const SchoolPermissionsView(),
      binding: SchoolPermissionsBinding(),
    ),
    GetPage(
      name: roles,
      page: () => const RolesView(),
      binding: RolesBinding(),
    ),
    GetPage(
      name: permissionMatrix,
      page: () => const MatrixView(),
      binding: MatrixBinding(),
    ),
    GetPage(
      name: featureAccess,
      page: () => const FeatureAccessView(),
      binding: FeatureAccessBinding(),
    ),
    GetPage(
      name: schoolSettings,
      page: () => const SchoolSettingsView(),
      binding: SchoolSettingsBinding(),
    ),
    GetPage(
      name: subscriptionSettings,
      page: () => const SubscriptionSettingsView(),
      binding: SubscriptionSettingsBinding(),
    ),
  ];
}
