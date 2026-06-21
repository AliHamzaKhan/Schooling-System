import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../config/guardian_routes.dart';
import '../../widgets/portal_bottom_nav.dart';
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
  int _index = 0;

  static const _alertsTab = 4;

  static const _items = [
    PortalNavItem(icon: Icons.dashboard_rounded, label: 'Home'),
    PortalNavItem(icon: Icons.insights_rounded, label: 'Academics'),
    PortalNavItem(icon: Icons.event_available_rounded, label: 'Attendance'),
    PortalNavItem(icon: Icons.assignment_outlined, label: 'Homework'),
    PortalNavItem(icon: Icons.notifications_outlined, label: 'Alerts'),
  ];

  void _goTo(int i) => setState(() => _index = i);
  void _openAlerts() => _goTo(_alertsTab);

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

    return AppScaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: PortalBottomNav(
        currentIndex: _index,
        onTap: _goTo,
        items: _items,
      ),
    );
  }
}
