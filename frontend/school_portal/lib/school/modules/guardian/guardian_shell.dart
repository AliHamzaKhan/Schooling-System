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
    PortalTab(Icons.dashboard_rounded, 'Home'),
    PortalTab(Icons.insights_rounded, 'Academics'),
    PortalTab(Icons.event_available_rounded, 'Attendance'),
    PortalTab(Icons.assignment_outlined, 'Homework'),
    PortalTab(Icons.notifications_outlined, 'Alerts'),
  ];

  void _openAlerts() => _tabController.jumpToTab(_alertsTab);

  void _manageChildren() => Get.toNamed(GuardianRoutes.childSelection);
  void _openFees() => Get.toNamed(GuardianRoutes.fees);
  void _openExams() => Get.toNamed(GuardianRoutes.exams);
  void _openMeetings() => Get.toNamed(GuardianRoutes.meetings);

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

    return PortalTabScaffold(
      title: 'Guardian',
      tabs: _tabs,
      screens: tabs,
      controller: _tabController,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
