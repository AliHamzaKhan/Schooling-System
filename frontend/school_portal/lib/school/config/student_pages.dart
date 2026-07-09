import 'package:get/get.dart';

import '../modules/student/features/exams/view/exam_detail_view.dart';
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

/// `GetPage` declarations for the Student module.
class StudentPages {
  StudentPages._();

  static final pages = <GetPage>[
    GetPage(name: StudentRoutes.shell, page: () => const StudentShell()),
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
  ];
}
