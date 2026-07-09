import 'package:get/get.dart';

import '../modules/headmaster/features/announcements/binding/announcements_binding.dart';
import '../modules/headmaster/features/announcements/view/announcements_view.dart';
import '../modules/headmaster/features/dashboard/view/approvals_view.dart';
import '../modules/headmaster/features/fees/view/overdue_payments_view.dart';
import '../modules/headmaster/features/guardians/binding/guardians_binding.dart';
import '../modules/headmaster/features/guardians/view/guardians_view.dart';
import '../modules/headmaster/features/overview/binding/overview_binding.dart';
import '../modules/headmaster/features/overview/view/overview_view.dart';
import '../modules/headmaster/features/overview/view/upcoming_events_view.dart';
import '../modules/headmaster/features/reports/binding/reports_binding.dart';
import '../modules/headmaster/features/reports/view/reports_view.dart';
import '../modules/headmaster/features/salary/binding/salary_binding.dart';
import '../modules/headmaster/features/salary/view/salary_view.dart';
import '../modules/headmaster/features/settings/binding/settings_binding.dart';
import '../modules/headmaster/features/settings/view/settings_view.dart';
import '../modules/headmaster/features/student_report/binding/student_report_binding.dart';
import '../modules/headmaster/features/student_report/view/class_students_view.dart';
import '../modules/headmaster/features/student_report/view/message_history_view.dart';
import '../modules/headmaster/features/student_report/view/section_students_view.dart';
import '../modules/headmaster/features/student_report/view/student_report_view.dart';
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
    // Drill-in list screens — stateless, fed the already-loaded list via
    // Get.arguments (no binding of their own).
    GetPage(
      name: HeadmasterRoutes.approvals,
      page: () => const ApprovalsView(),
    ),
    GetPage(
      name: HeadmasterRoutes.overduePayments,
      page: () => const OverduePaymentsView(),
    ),
    GetPage(
      name: HeadmasterRoutes.upcomingEvents,
      page: () => const UpcomingEventsView(),
    ),
    GetPage(
      name: HeadmasterRoutes.students,
      page: () => const StudentsView(),
      binding: StudentsBinding(),
    ),
    // Shared staff drill-down (Teacher module navigates here too).
    GetPage(
      name: HeadmasterRoutes.studentReport,
      page: () => const StudentReportView(),
      binding: StudentReportBinding(),
    ),
    GetPage(
      name: HeadmasterRoutes.messageHistory,
      page: () => const MessageHistoryView(),
    ),
    GetPage(
      name: HeadmasterRoutes.sectionStudents,
      page: () => const SectionStudentsView(),
    ),
    GetPage(
      name: HeadmasterRoutes.classStudents,
      page: () => const ClassStudentsView(),
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
    GetPage(
      name: HeadmasterRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: HeadmasterRoutes.salary,
      page: () => const SalaryView(),
      binding: SalaryBinding(),
    ),
  ];
}
