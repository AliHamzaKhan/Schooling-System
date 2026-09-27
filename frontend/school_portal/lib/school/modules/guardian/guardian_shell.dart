import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../config/guardian_routes.dart';
import '../../widgets/portal_tab_scaffold.dart';
import 'features/attendance/binding/attendance_binding.dart';
import 'features/attendance/view/attendance_view.dart';
import 'features/dashboard/binding/dashboard_binding.dart';
import 'features/dashboard/view/dashboard_view.dart';
import 'features/homework/binding/homework_binding.dart';
import 'features/homework/view/homework_view.dart';
import 'features/notifications/binding/notification_binding.dart';
import 'features/notifications/view/notification_view.dart';
import 'features/performance/binding/performance_binding.dart';
import 'features/performance/view/performance_view.dart';
import 'shared/controller/guardian_session_controller.dart';
import 'package:shared/shared.dart';

/// Guardian (parent) module shell — 5-tab nav: Home (Dashboard) / Academics
/// (Performance) / Attendance / Homework / Alerts (Notifications Center).
///
/// Drill-in routes reached from these tabs: Child Selection, Fee Status,
/// Exam Updates, Meeting Schedule. The shared [GuardianSessionController] (and
/// thus the active-child selection) is registered by [GuardianSessionBinding]
/// on this route and persists across every tab and drill-in.
class GuardianShell extends StatefulWidget {
  const GuardianShell({super.key});

  @override
  State<GuardianShell> createState() => _GuardianShellState();
}

class _GuardianShellState extends State<GuardianShell> {
  static const _alertsTab = 4;

  final _tabController = PersistentTabController(initialIndex: 0);

  static const _tabs = [
    PortalTab(AppIcons.dashboardRounded, 'Home'),
    PortalTab(AppIcons.insightsRounded, 'Academics'),
    PortalTab(AppIcons.eventAvailableRounded, 'Attendance'),
    PortalTab(AppIcons.assignmentOutlined, 'Homework'),
    PortalTab(AppIcons.notificationsOutlined, 'Alerts'),
  ];

  void _openAlerts() => _tabController.jumpToTab(_alertsTab);

  void _manageChildren() => Get.toNamed(GuardianRoutes.childSelection);
  void _openFees() => Get.toNamed(GuardianRoutes.fees);
  void _openExams() => Get.toNamed(GuardianRoutes.exams);
  void _openMeetings() => Get.toNamed(GuardianRoutes.meetings);
  void _openReportCard() => Get.toNamed(GuardianRoutes.reportCard);
  void _openTimetable() => Get.toNamed(GuardianRoutes.timetable);
  void _openMessages() => Get.toNamed(GuardianRoutes.messages);

  @override
  void initState() {
    super.initState();
    // Register the tab feature controllers up-front; drill-in features bind
    // lazily through their own routes.
    GuardianDashboardBinding().dependencies();
    PerformanceBinding().dependencies();
    GuardianAttendanceBinding().dependencies();
    HomeworkBinding().dependencies();
    NotificationBinding().dependencies();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      GuardianDashboardView(
        onNotifications: _openAlerts,
        onManageChildren: _manageChildren,
        onOpenFees: _openFees,
        onOpenExams: _openExams,
        onOpenMeetings: _openMeetings,
        onOpenReportCard: _openReportCard,
        onOpenTimetable: _openTimetable,
        onOpenMessages: _openMessages,
      ),
      PerformanceView(
        onNotifications: _openAlerts,
        onManageChildren: _manageChildren,
      ),
      GuardianAttendanceView(
        onNotifications: _openAlerts,
        onManageChildren: _manageChildren,
      ),
      HomeworkView(
        onNotifications: _openAlerts,
        onManageChildren: _manageChildren,
      ),
      const NotificationView(),
    ];

    final session = Get.find<GuardianSessionController>();
    return Obx(() {
      if (session.loading.value) {
        return const AppScaffold(
          body: AppStateView.loading(
            title: 'Loading linked children',
            message: 'Checking your current family access.',
          ),
        );
      }
      final error = session.error.value;
      if (error != null) {
        return AppScaffold(
          body: AppStateView.error(
            title: 'Family access is unavailable',
            message: error,
            actionLabel: 'Try again',
            onAction: session.load,
          ),
        );
      }
      return PortalTabScaffold(
        title: 'Guardian',
        tabs: _tabs,
        screens: tabs,
        controller: _tabController,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
