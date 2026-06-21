import 'package:get/get.dart';

import '../modules/student/features/notifications/binding/notifications_binding.dart';
import '../modules/student/features/notifications/view/notifications_view.dart';
import '../modules/student/features/submission/binding/submission_binding.dart';
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
      name: StudentRoutes.notifications,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
    ),
  ];
}
