import 'package:get/get.dart';

import '../modules/splash/binding/splash_binding.dart';
import '../modules/splash/view/splash_view.dart';
import 'accountant_pages.dart';
import 'app_routes.dart';
import 'driver_pages.dart';
import 'guardian_pages.dart';
import 'headmaster_pages.dart';
import 'student_pages.dart';
import 'teacher_pages.dart';

/// Aggregates every module's `GetPage` list into one collection consumed by
/// `GetMaterialApp.getPages`.
///
/// Adding a new role module is a one-line change here — drop in its `Pages`
/// class:
/// ```dart
/// static final pages = <GetPage>[
///   ...HeadmasterPages.pages,
///   ...TeacherPages.pages,
///   ...StaffPages.pages,
///   ...StudentPages.pages,
/// ];
/// ```
class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    ...HeadmasterPages.pages,
    ...TeacherPages.pages,
    ...StudentPages.pages,
    ...GuardianPages.pages,
    ...DriverPages.pages,
    ...AccountantPages.pages,
    // ...StaffPages.pages,
  ];
}
