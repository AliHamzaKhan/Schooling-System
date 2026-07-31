import 'package:get/get.dart';

import '../modules/teacher/features/attendance/binding/attendance_binding.dart';
import '../modules/teacher/features/attendance/view/attendance_mark_view.dart';
import '../modules/teacher/features/calendar/view/calendar_view.dart';
import '../modules/teacher/features/classes/view/class_detail_view.dart';
import '../modules/teacher/features/communication/binding/communication_binding.dart';
import '../modules/teacher/features/communication/binding/create_announcement_binding.dart';
import '../modules/teacher/features/communication/view/communication_view.dart';
import '../modules/teacher/features/communication/view/create_announcement_view.dart';
import '../modules/teacher/features/exams/binding/create_exam_binding.dart';
import '../modules/teacher/features/exams/view/create_exam_view.dart';
import '../modules/teacher/features/gradebook/binding/gradebook_binding.dart';
import '../modules/teacher/features/gradebook/view/gradebook_view.dart';
import '../modules/teacher/features/homework/binding/create_homework_binding.dart';
import '../modules/teacher/features/homework/view/create_homework_view.dart';
import '../modules/teacher/features/performance/binding/performance_binding.dart';
import '../modules/teacher/features/performance/view/performance_view.dart';
import '../modules/teacher/features/quiz/binding/quiz_binding.dart';
import '../modules/teacher/features/grading/binding/grading_binding.dart';
import '../modules/teacher/features/grading/view/grading_view.dart';
import '../modules/teacher/features/leave/binding/leave_review_binding.dart';
import '../modules/teacher/features/leave/view/leave_review_view.dart';
import '../modules/teacher/features/quiz/view/create_quiz_view.dart';
import '../modules/teacher/features/quiz/view/quiz_performance_view.dart';
import '../modules/teacher/features/quiz/view/quizzes_view.dart';
import '../modules/teacher/teacher_shell.dart';
import 'teacher_routes.dart';

/// `GetPage` declarations for the Teacher module.
class TeacherPages {
  TeacherPages._();

  static final pages = <GetPage>[
    GetPage(name: TeacherRoutes.shell, page: () => const TeacherShell()),
    GetPage(
      name: TeacherRoutes.attendanceMark,
      page: () => const AttendanceMarkView(),
      binding: AttendanceMarkBinding(),
    ),
    GetPage(
      name: TeacherRoutes.createHomework,
      page: () => const CreateHomeworkView(),
      binding: CreateHomeworkBinding(),
      fullscreenDialog: true,
    ),
    GetPage(
      name: TeacherRoutes.createExam,
      page: () => const CreateExamView(),
      binding: CreateExamBinding(),
      fullscreenDialog: true,
    ),
    GetPage(
      name: TeacherRoutes.chat,
      page: () => const CommunicationView(),
      binding: CommunicationBinding(),
    ),
    GetPage(
      name: TeacherRoutes.createAnnouncement,
      page: () => const CreateAnnouncementView(),
      binding: CreateAnnouncementBinding(),
      fullscreenDialog: true,
    ),
    GetPage(
      name: TeacherRoutes.gradebook,
      page: () => const GradebookView(),
      binding: GradebookBinding(),
    ),
    GetPage(
      name: TeacherRoutes.studentPerformance,
      page: () => const StudentPerformanceView(showBack: true),
      binding: PerformanceBinding(),
    ),
    GetPage(
      name: TeacherRoutes.calendar,
      page: () => const CalendarView(),
    ),
    GetPage(
      name: TeacherRoutes.classDetail,
      page: () => const ClassDetailView(),
    ),
    GetPage(
      name: TeacherRoutes.quizzes,
      page: () => const QuizzesView(),
      binding: QuizzesBinding(),
    ),
    GetPage(
      name: TeacherRoutes.createQuiz,
      page: () => const CreateQuizView(),
      binding: CreateQuizBinding(),
      fullscreenDialog: true,
    ),
    GetPage(
      name: TeacherRoutes.quizPerformance,
      page: () => const QuizPerformanceView(),
      binding: QuizPerformanceBinding(),
    ),
    GetPage(
      name: TeacherRoutes.leaveReview,
      page: () => const TeacherLeaveReviewView(),
      binding: TeacherLeaveReviewBinding(),
    ),
    GetPage(
      name: TeacherRoutes.grading,
      page: () => const GradingView(),
      binding: GradingBinding(),
    ),
  ];
}
