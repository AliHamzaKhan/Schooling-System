import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../modules/headmaster/features/announcements/binding/announcements_binding.dart';
import '../modules/headmaster/features/announcements/view/announcements_view.dart';
import '../modules/headmaster/features/attendance/view/teacher_attendance_roster_view.dart';
import '../modules/headmaster/features/attendance/view/teacher_attendance_view.dart';
import '../modules/headmaster/features/classes/binding/classes_binding.dart';
import '../modules/headmaster/features/classes/view/classes_view.dart';
import '../modules/headmaster/features/dashboard/view/approvals_view.dart';
import '../modules/headmaster/features/fees/view/fees_roster_view.dart';
import '../modules/headmaster/features/fees/view/overdue_payments_view.dart';
import '../modules/headmaster/features/fees/view/record_payment_view.dart';
import '../modules/headmaster/features/guardians/binding/guardians_binding.dart';
import '../modules/headmaster/features/guardians/view/guardians_view.dart';
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
      name: HeadmasterRoutes.recordPayment,
      page: () => const RecordPaymentView(),
    ),
    GetPage(
      name: HeadmasterRoutes.feesRoster,
      page: () => const FeesRosterView(),
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
