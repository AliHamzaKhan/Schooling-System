import 'package:get/get.dart';
import 'role_page_bindings.dart';
import 'package:shared/shared.dart';

import '../modules/student/features/courses/binding/courses_binding.dart';
import '../modules/student/features/courses/view/book_chapters_view.dart';
import '../modules/student/features/courses/view/course_detail_view.dart';
import '../modules/student/features/courses/view/courses_view.dart';
import '../modules/student/features/courses/view/notes_list_view.dart';
import '../modules/student/features/courses/view/reader_view.dart';
import '../modules/student/features/exams/view/exam_detail_view.dart';
import '../modules/student/features/leave/binding/leave_binding.dart';
import '../modules/student/features/leave/view/leave_view.dart';
import '../modules/student/features/transport/binding/transport_binding.dart';
import '../modules/student/features/transport/view/transport_view.dart';
import '../modules/student/features/school_info/binding/school_info_binding.dart';
import '../modules/student/features/school_info/view/school_info_view.dart';
import '../modules/student/features/notifications/binding/notifications_binding.dart';
import '../modules/student/features/notifications/view/notifications_view.dart';
import '../modules/student/features/quiz/binding/quiz_binding.dart';
import '../modules/student/features/quiz/view/quizzes_view.dart';
import '../modules/student/features/quiz/view/take_quiz_view.dart';
import '../modules/student/features/results/binding/results_binding.dart';
import '../modules/student/features/results/view/report_card_view.dart';
import '../modules/student/features/results/view/results_view.dart';
import '../modules/student/features/submission/binding/submission_binding.dart';
import '../modules/student/features/timetable/binding/timetable_binding.dart';
import '../modules/student/features/timetable/view/timetable_view.dart';
import '../modules/student/features/submission/view/submission_view.dart';
import '../modules/student/student_shell.dart';
import 'student_routes.dart';
import '../modules/student/features/courses/models/course_models.dart';
import '../modules/student/features/courses/controller/reader_controller.dart';

/// `GetPage` declarations for the Student module.
class StudentPages {
  StudentPages._();

  static final _pages = <GetPage>[
    GetPage(name: StudentRoutes.shell, page: () => const StudentShell()),
    GetPage(
      name: StudentRoutes.messages,
      page: () => const InboxView(title: 'Messages'),
    ),
    GetPage(
      name: StudentRoutes.assignmentDetail,
      page: () => const SubmissionView(),
      binding: SubmissionBinding(),
    ),
    GetPage(
      name: StudentRoutes.examDetail,
      page: () => const ExamDetailView(),
    ),
    GetPage(
      name: StudentRoutes.quizzes,
      page: () => const QuizzesView(),
      binding: QuizzesBinding(),
    ),
    GetPage(
      name: StudentRoutes.takeQuiz,
      page: () => const TakeQuizView(),
      binding: TakeQuizBinding(),
    ),
    GetPage(
      name: StudentRoutes.results,
      page: () => const ResultsView(),
      binding: ResultsBinding(),
    ),
    GetPage(
      name: StudentRoutes.reportCard,
      page: () => const ReportCardView(),
    ),
    GetPage(
      name: StudentRoutes.timetable,
      page: () => const TimetableView(),
      binding: TimetableBinding(),
    ),
    GetPage(
      name: StudentRoutes.notifications,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
    ),

    // ── Courses ──
    GetPage(
      name: StudentRoutes.courses,
      page: () => const CoursesView(),
      binding: CoursesBinding(),
    ),
    GetPage(
      name: StudentRoutes.courseDetail,
      page: () => Get.arguments is Course ? const CourseDetailView() : const RouteContextMissingView(returnRoute: StudentRoutes.courses),
    ),
    GetPage(
      name: StudentRoutes.courseBook,
      page: () => Get.arguments is Course ? const BookChaptersView() : const RouteContextMissingView(returnRoute: StudentRoutes.courses),
      binding: BookChaptersBinding(),
    ),
    GetPage(
      name: StudentRoutes.courseNotes,
      page: () => Get.arguments is Course ? const NotesListView() : const RouteContextMissingView(returnRoute: StudentRoutes.courses),
      binding: NotesBinding(),
    ),
    GetPage(
      name: StudentRoutes.courseReader,
      page: () => Get.arguments is ReaderArgs ? const ReaderView() : const RouteContextMissingView(returnRoute: StudentRoutes.courses),
      binding: ReaderBinding(),
    ),

    // ── Leave ──
    GetPage(
      name: StudentRoutes.leave,
      page: () => const LeaveView(),
      binding: LeaveBinding(),
    ),

    // ── Transport ──
    GetPage(
      name: StudentRoutes.transport,
      page: () => const StudentTransportView(),
      binding: StudentTransportBinding(),
    ),

    // ── School info ──
    GetPage(
      name: StudentRoutes.schoolInfo,
      page: () => const SchoolInfoView(),
      binding: SchoolInfoBinding(),
    ),
  ];
  static List<GetPage> get pages => _pages.map((page) => page.copy(
    middlewares: [...?page.middlewares, RoleRouteGuard({'student'})],
    bindings: [StudentRouteBinding(), ...page.bindings],
  )).toList();
}
