import 'package:get/get.dart';

import '../features/headmasters/binding/headmasters_binding.dart';
import '../features/headmasters/view/headmasters_view.dart';
import '../features/permissions/school_modules/binding/school_modules_binding.dart';
import '../features/permissions/school_modules/view/school_modules_view.dart';
import '../features/permissions/school_permissions/binding/school_permissions_binding.dart';
import '../features/permissions/school_permissions/view/school_permissions_view.dart';
import '../features/schools/create/binding/create_school_binding.dart';
import '../features/schools/create/view/create_school_view.dart';
import '../features/schools/detail/binding/school_detail_binding.dart';
import '../features/schools/detail/view/school_detail_view.dart';
import '../features/subscriptions/binding/subscriptions_binding.dart';
import '../features/subscriptions/create/view/plan_form_view.dart';
import '../features/subscriptions/view/subscriptions_view.dart';
import '../features/subscription_management/binding/subscription_management_binding.dart';
import '../features/subscription_management/view/subscription_management_view.dart';
import '../features/revenue/binding/revenue_binding.dart';
import '../features/revenue/view/revenue_view.dart';
import '../features/transactions/binding/transactions_binding.dart';
import '../features/transactions/view/transactions_view.dart';
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
  static const schoolDetail = '/schools/detail';
  static const subscriptions = '/subscriptions';
  static const planForm = '/subscriptions/plan-form';
  static const subscriptionManagement = '/subscriptions/manage';
  static const revenue = '/revenue';
  static const transactions = '/transactions';
  static const headmasters = '/headmasters';
  static const schoolPermissions = '/permissions/schools';
  static const schoolModules = '/permissions/schools/modules';

  static final pages = <GetPage>[
    GetPage(name: home, page: () => const AdminShell()),
    GetPage(
      name: createSchool,
      page: () => const CreateSchoolView(),
      binding: CreateSchoolBinding(),
      fullscreenDialog: true,
    ),
    GetPage(
      name: schoolDetail,
      page: () => const SchoolDetailView(),
      binding: SchoolDetailBinding(),
    ),
    GetPage(
      name: subscriptions,
      page: () => const SubscriptionsView(),
      binding: SubscriptionsBinding(),
    ),
    GetPage(
      // Reuses the SubscriptionsController already alive under the plans list;
      // no binding so navigating here never replaces that shared instance.
      name: planForm,
      page: () => const PlanFormView(),
      fullscreenDialog: true,
    ),
    GetPage(
      name: subscriptionManagement,
      page: () => const SubscriptionManagementView(),
      binding: SubscriptionManagementBinding(),
    ),
    GetPage(
      name: revenue,
      page: () => const RevenueView(),
      binding: RevenueBinding(),
    ),
    GetPage(
      name: transactions,
      page: () => const TransactionsView(),
      binding: TransactionsBinding(),
    ),
    GetPage(
      name: headmasters,
      page: () => const HeadmastersView(),
      binding: HeadmastersBinding(),
    ),
    GetPage(
      name: schoolPermissions,
      page: () => const SchoolPermissionsView(),
      binding: SchoolPermissionsBinding(),
    ),
    GetPage(
      name: schoolModules,
      page: () => const SchoolModulesEditorView(),
      binding: SchoolModulesBinding(),
    ),
  ];
}
