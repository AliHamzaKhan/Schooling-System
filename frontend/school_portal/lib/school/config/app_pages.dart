import 'package:get/get.dart';

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
    ...HeadmasterPages.pages,
    ...TeacherPages.pages,
    ...StudentPages.pages,
    ...GuardianPages.pages,
    // ...StaffPages.pages,
  ];
}
