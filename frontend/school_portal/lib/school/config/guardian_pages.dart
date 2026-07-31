import 'package:get/get.dart';

import '../modules/guardian/features/child_selection/view/child_selection_view.dart';
import '../modules/guardian/features/exams/binding/exam_binding.dart';
import '../modules/guardian/features/exams/view/exam_view.dart';
import '../modules/guardian/features/fees/binding/fee_binding.dart';
import '../modules/guardian/features/fees/view/fee_view.dart';
import '../modules/guardian/features/meetings/binding/meeting_binding.dart';
import '../modules/guardian/features/meetings/view/meeting_view.dart';
import '../modules/guardian/features/notifications/binding/notification_binding.dart';
import '../modules/guardian/features/notifications/view/notification_view.dart';
import '../modules/guardian/features/leave/binding/guardian_leave_binding.dart';
import '../modules/guardian/features/leave/view/guardian_leave_view.dart';
import '../modules/guardian/features/report_card/binding/report_card_binding.dart';
import '../modules/guardian/features/report_card/view/report_card_view.dart';
import '../modules/guardian/features/timetable/binding/timetable_binding.dart';
import '../modules/guardian/features/timetable/view/timetable_view.dart';
import '../modules/guardian/guardian_shell.dart';
import '../modules/guardian/shared/binding/guardian_session_binding.dart';
import 'guardian_routes.dart';

/// `GetPage` declarations for the Guardian (parent) module.
class GuardianPages {
  GuardianPages._();

  static final pages = <GetPage>[
    GetPage(
      name: GuardianRoutes.shell,
      page: () => const GuardianShell(),
      binding: GuardianSessionBinding(),
    ),
    GetPage(
      name: GuardianRoutes.childSelection,
      page: () => const ChildSelectionView(),
    ),
    GetPage(
      name: GuardianRoutes.fees,
      page: () => const FeeView(),
      binding: FeeBinding(),
    ),
    GetPage(
      name: GuardianRoutes.exams,
      page: () => const ExamView(),
      binding: ExamBinding(),
    ),
    GetPage(
      name: GuardianRoutes.meetings,
      page: () => const MeetingView(),
      binding: MeetingBinding(),
    ),
    GetPage(
      name: GuardianRoutes.reportCard,
      page: () => const ReportCardView(),
      binding: ReportCardBinding(),
    ),
    GetPage(
      name: GuardianRoutes.timetable,
      page: () => const TimetableView(),
      binding: TimetableBinding(),
    ),
    GetPage(
      name: GuardianRoutes.notifications,
      page: () => const NotificationView(standalone: true),
      binding: NotificationBinding(),
    ),
    GetPage(
      name: GuardianRoutes.leave,
      page: () => const GuardianLeaveView(),
      binding: GuardianLeaveBinding(),
    ),
  ];
}
