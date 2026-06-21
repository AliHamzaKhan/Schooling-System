import 'package:get/get.dart';

import '../modules/teacher/features/attendance/binding/attendance_binding.dart';
import '../modules/teacher/features/attendance/view/attendance_mark_view.dart';
import '../modules/teacher/features/communication/binding/communication_binding.dart';
import '../modules/teacher/features/communication/view/communication_view.dart';
import '../modules/teacher/features/exams/binding/create_exam_binding.dart';
import '../modules/teacher/features/exams/view/create_exam_view.dart';
import '../modules/teacher/features/gradebook/binding/gradebook_binding.dart';
import '../modules/teacher/features/gradebook/view/gradebook_view.dart';
import '../modules/teacher/features/homework/binding/create_homework_binding.dart';
import '../modules/teacher/features/homework/view/create_homework_view.dart';
import '../modules/teacher/features/performance/binding/performance_binding.dart';
import '../modules/teacher/features/performance/view/performance_view.dart';
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
      name: TeacherRoutes.gradebook,
      page: () => const GradebookView(),
      binding: GradebookBinding(),
    ),
    GetPage(
      name: TeacherRoutes.studentPerformance,
      page: () => const StudentPerformanceView(showBack: true),
      binding: PerformanceBinding(),
    ),
  ];
}
