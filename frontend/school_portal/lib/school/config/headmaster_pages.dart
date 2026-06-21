import 'package:get/get.dart';

import '../modules/headmaster/features/announcements/binding/announcements_binding.dart';
import '../modules/headmaster/features/announcements/view/announcements_view.dart';
import '../modules/headmaster/features/guardians/binding/guardians_binding.dart';
import '../modules/headmaster/features/guardians/view/guardians_view.dart';
import '../modules/headmaster/features/overview/binding/overview_binding.dart';
import '../modules/headmaster/features/overview/view/overview_view.dart';
import '../modules/headmaster/features/reports/binding/reports_binding.dart';
import '../modules/headmaster/features/reports/view/reports_view.dart';
import '../modules/headmaster/features/students/binding/students_binding.dart';
import '../modules/headmaster/features/students/view/students_view.dart';
import '../modules/headmaster/features/teachers/binding/teachers_binding.dart';
import '../modules/headmaster/features/teachers/view/teachers_view.dart';
import '../modules/headmaster/features/timetable/binding/timetable_binding.dart';
import '../modules/headmaster/features/timetable/view/timetable_view.dart';
import '../modules/headmaster/headmaster_shell.dart';
import 'headmaster_routes.dart';

/// `GetPage` declarations for the Headmaster module.
///
/// [AppPages] spreads this list into the global router; the module owns nothing
/// outside `HeadmasterRoutes._base` so it can be removed or feature-flagged in
/// isolation.
class HeadmasterPages {
  HeadmasterPages._();

  static final pages = <GetPage>[
    GetPage(name: HeadmasterRoutes.shell, page: () => const HeadmasterShell()),
    GetPage(
      name: HeadmasterRoutes.schoolOverview,
      page: () => const OverviewView(),
      binding: OverviewBinding(),
    ),
    GetPage(
      name: HeadmasterRoutes.students,
      page: () => const StudentsView(),
      binding: StudentsBinding(),
    ),
    GetPage(
      name: HeadmasterRoutes.teachers,
      page: () => const TeachersView(),
      binding: TeachersBinding(),
    ),
    GetPage(
      name: HeadmasterRoutes.guardians,
      page: () => const GuardiansView(),
      binding: GuardiansBinding(),
    ),
    GetPage(
      name: HeadmasterRoutes.timetable,
      page: () => const TimetableView(),
      binding: TimetableBinding(),
    ),
    GetPage(
      name: HeadmasterRoutes.announcements,
      page: () => const AnnouncementsView(),
      binding: AnnouncementsBinding(),
    ),
    GetPage(
      name: HeadmasterRoutes.analytics,
      page: () => const ReportsView(),
      binding: ReportsBinding(),
    ),
  ];
}
