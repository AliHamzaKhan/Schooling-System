import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../modules/headmaster/binding/headmaster_route_binding.dart';
import '../modules/headmaster/features/announcements/binding/announcements_binding.dart';
import '../modules/headmaster/features/announcements/view/announcements_view.dart';
import '../modules/headmaster/features/attendance/view/teacher_attendance_roster_view.dart';
import '../modules/headmaster/features/attendance/view/teacher_attendance_view.dart';
import '../modules/headmaster/features/classes/binding/classes_binding.dart';
import '../modules/headmaster/features/classes/view/classes_view.dart';
import '../modules/headmaster/features/dashboard/view/approvals_view.dart';
import '../modules/headmaster/features/dashboard/binding/approvals_binding.dart';
import '../modules/headmaster/features/fees/view/fees_roster_view.dart';
import '../modules/headmaster/features/fees/view/financial_adjustments_view.dart';
import '../modules/headmaster/features/fees/view/overdue_payments_view.dart';
import '../modules/headmaster/features/fees/view/record_payment_view.dart';
import '../modules/headmaster/features/guardians/binding/guardians_binding.dart';
import '../modules/headmaster/features/guardians/view/guardians_view.dart';
import '../modules/headmaster/features/overview/binding/upcoming_events_binding.dart';
import '../modules/headmaster/features/overview/view/upcoming_events_view.dart';
import '../modules/headmaster/features/reports/binding/reports_binding.dart';
import '../modules/headmaster/features/reports/view/reports_view.dart';
import '../modules/headmaster/features/salary/binding/salary_binding.dart';
import '../modules/headmaster/features/salary/view/generate_payslip_view.dart';
import '../modules/headmaster/features/salary/view/salary_view.dart';
import '../modules/headmaster/features/courses/binding/courses_admin_binding.dart';
import '../modules/headmaster/features/courses/view/book_admin_view.dart';
import '../modules/headmaster/features/courses/view/course_content_view.dart';
import '../modules/headmaster/features/courses/view/courses_admin_view.dart';
import '../modules/headmaster/features/leave/binding/leave_review_binding.dart';
import '../modules/headmaster/features/leave/view/leave_review_view.dart';
import '../modules/headmaster/features/exams/binding/exam_categories_binding.dart';
import '../modules/headmaster/features/exams/binding/exam_timetable_binding.dart';
import '../modules/headmaster/features/exams/view/exam_categories_view.dart';
import '../modules/headmaster/features/exams/view/exam_timetable_view.dart';
import '../modules/headmaster/features/promotion/binding/promotion_binding.dart';
import '../modules/headmaster/features/promotion/view/promotion_view.dart';
import '../modules/headmaster/features/schoolinfo/binding/school_info_edit_binding.dart';
import '../modules/headmaster/features/schoolinfo/view/school_info_edit_view.dart';
import '../modules/headmaster/features/settings/binding/settings_binding.dart';
import '../modules/headmaster/features/settings/view/settings_view.dart';
import '../modules/headmaster/features/student_report/binding/student_report_binding.dart';
import '../modules/headmaster/features/student_report/view/class_students_view.dart';
import '../modules/headmaster/features/student_report/view/message_history_view.dart';
import '../modules/headmaster/features/student_report/view/section_students_view.dart';
import '../modules/headmaster/features/student_report/view/student_report_view.dart';
import '../modules/headmaster/features/students/binding/students_binding.dart';
import '../modules/headmaster/features/students/view/student_registration_view.dart';
import '../modules/headmaster/features/students/view/students_view.dart';
import '../modules/headmaster/features/teachers/binding/teachers_binding.dart';
import '../modules/headmaster/features/teachers/view/teacher_registration_view.dart';
import '../modules/headmaster/features/teachers/view/teachers_view.dart';
import '../modules/headmaster/features/timetable/view/timetable_editor_view.dart';
import '../modules/headmaster/features/transport/binding/transport_binding.dart';
import '../modules/headmaster/features/transport/view/transport_view.dart';
import '../modules/headmaster/headmaster_shell.dart';
import '../modules/headmaster/routing/headmaster_capability_middleware.dart';
import 'headmaster_routes.dart';

/// `GetPage` declarations for the Headmaster module.
///
/// [AppPages] spreads this list into the global router; the module owns nothing
/// outside `HeadmasterRoutes._base` so it can be removed or feature-flagged in
/// isolation.
class HeadmasterPages {
  HeadmasterPages._();

  /// Fee and payroll screens finance staff (Accountant) also use.
  static const _financeRoutes = <String>{
    HeadmasterRoutes.overduePayments,
    HeadmasterRoutes.recordPayment,
    HeadmasterRoutes.feesRoster,
    HeadmasterRoutes.financialAdjustments,
    HeadmasterRoutes.salary,
    HeadmasterRoutes.generatePayslip,
  };

  static const _capabilitiesByRoute = <String, Set<String>>{
    HeadmasterRoutes.approvals: {'leave_management'},
    HeadmasterRoutes.overduePayments: {'fee_management'},
    HeadmasterRoutes.recordPayment: {'fee_management'},
    HeadmasterRoutes.feesRoster: {'fee_management'},
    HeadmasterRoutes.financialAdjustments: {'fee_management'},
    HeadmasterRoutes.teacherAttendance: {'attendance'},
    HeadmasterRoutes.teacherAttendanceRoster: {'attendance'},
    HeadmasterRoutes.students: {'student_management'},
    HeadmasterRoutes.studentRegistration: {'student_management'},
    HeadmasterRoutes.studentReport: {'student_management'},
    HeadmasterRoutes.messageHistory: {'student_management'},
    HeadmasterRoutes.sectionStudents: {'student_management'},
    HeadmasterRoutes.classStudents: {'student_management'},
    HeadmasterRoutes.classes: {'student_management'},
    HeadmasterRoutes.teacherRegistration: {'teacher_management'},
    HeadmasterRoutes.teachers: {'teacher_management'},
    HeadmasterRoutes.guardians: {'guardian_management'},
    HeadmasterRoutes.timetable: {'timetable'},
    HeadmasterRoutes.announcements: {'messaging'},
    HeadmasterRoutes.analytics: {'reports'},
    HeadmasterRoutes.salary: {'hr_payroll'},
    HeadmasterRoutes.generatePayslip: {'hr_payroll'},
    HeadmasterRoutes.transport: {'transport'},
    HeadmasterRoutes.leaveReview: {'leave_management'},
    HeadmasterRoutes.examCategories: {'exams'},
    HeadmasterRoutes.examTimetable: {'exams'},
    HeadmasterRoutes.promotion: {'exams'},
  };

  static final _pages = <GetPage>[
    GetPage(name: HeadmasterRoutes.shell, page: () => const HeadmasterShell()),
    // Drill-in list screens reconstruct their state from route identifiers or
    // route-local canonical reads so direct URLs do not require shell memory.
    GetPage(
      name: HeadmasterRoutes.approvals,
      page: () => const ApprovalsView(),
      binding: ApprovalsBinding(),
    ),
    GetPage(
      name: HeadmasterRoutes.overduePayments,
      page: () => const OverduePaymentsView(),
    ),
    GetPage(
      name: HeadmasterRoutes.recordPayment,
      page: () => const RecordPaymentView(),
    ),
    GetPage(
      name: HeadmasterRoutes.feesRoster,
      page: () => const FeesRosterView(),
    ),
    GetPage(
      name: HeadmasterRoutes.financialAdjustments,
      page: () => const FinancialAdjustmentsView(),
    ),
    GetPage(
      name: HeadmasterRoutes.teacherAttendance,
      page: () => const TeacherAttendanceView(),
    ),
    GetPage(
      name: HeadmasterRoutes.teacherAttendanceRoster,
      page: () => const TeacherAttendanceRosterView(),
    ),
    GetPage(
      name: HeadmasterRoutes.upcomingEvents,
      page: () => const UpcomingEventsView(),
      binding: UpcomingEventsBinding(),
    ),
    GetPage(
      name: HeadmasterRoutes.students,
      page: () => const StudentsView(),
      binding: StudentsBinding(),
    ),
    GetPage(
      name: HeadmasterRoutes.studentRegistration,
      page: () => const StudentRegistrationView(),
    ),
    GetPage(
      name: HeadmasterRoutes.teacherRegistration,
      page: () => const TeacherRegistrationView(),
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
      name: HeadmasterRoutes.classes,
      page: () => const _ClassesRoutePage(),
      binding: ClassesBinding(),
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
      page: () => const TimetableEditorView(),
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
    GetPage(
      name: HeadmasterRoutes.generatePayslip,
      page: () => const GeneratePayslipView(),
    ),
    GetPage(
      name: HeadmasterRoutes.transport,
      page: () => const TransportView(),
      binding: TransportBinding(),
    ),

    // Courses authoring.
    GetPage(
      name: HeadmasterRoutes.coursesAdmin,
      page: () => const CoursesAdminView(),
      binding: CoursesAdminBinding(),
    ),
    GetPage(
      name: HeadmasterRoutes.courseContent,
      page: () => const CourseContentView(),
      binding: CourseContentBinding(),
    ),
    GetPage(
      name: HeadmasterRoutes.bookAdmin,
      page: () => const BookAdminView(),
      binding: BookAdminBinding(),
    ),

    // School info authoring.
    GetPage(
      name: HeadmasterRoutes.schoolInfoEdit,
      page: () => const SchoolInfoEditView(),
      binding: SchoolInfoEditBinding(),
    ),

    // Leave review.
    GetPage(
      name: HeadmasterRoutes.leaveReview,
      page: () => const LeaveReviewView(),
      binding: LeaveReviewBinding(),
    ),

    // Examination: categories + student promotion.
    GetPage(
      name: HeadmasterRoutes.examCategories,
      page: () => const ExamCategoriesView(),
      binding: ExamCategoriesBinding(),
    ),
    GetPage(
      name: HeadmasterRoutes.examTimetable,
      page: () => const ExamTimetableView(),
      binding: ExamTimetableBinding(),
    ),
    GetPage(
      name: HeadmasterRoutes.promotion,
      page: () => const PromotionView(),
      binding: PromotionBinding(),
    ),
  ];

  /// Every headmaster route carries the same client-side role boundary. This
  /// matters on web where a user can paste a deep link directly into the URL.
  /// API permissions remain the final authority for every operation.
  static List<GetPage> get pages => _pages
      .map((page) {
        final capabilities = _capabilitiesByRoute[page.name];
        return page.copy(
          bindings: [HeadmasterRouteBinding(), ...page.bindings],
          middlewares: [
            ...?page.middlewares,
            RoleRouteGuard(
              _financeRoutes.contains(page.name)
                  ? {'headmaster', 'accountant'}
                  : {'headmaster'},
            ),
            if (capabilities != null)
              HeadmasterCapabilityMiddleware(capabilities),
          ],
        );
      })
      .toList(growable: false);
}

/// Wraps [ClassesView] with an app-bar (title + back arrow) when it is opened
/// as a standalone route from the dashboard. In the tab shell, [ClassesView]
/// is embedded directly and this wrapper is not used.
class _ClassesRoutePage extends StatelessWidget {
  const _ClassesRoutePage();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Classes & Sections'),
        backgroundColor: AppColors.surface,
      ),
      body: const ClassesView(),
    );
  }
}
