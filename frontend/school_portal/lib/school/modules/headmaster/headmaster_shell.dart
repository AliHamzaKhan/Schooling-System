import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/portal_tab_scaffold.dart';
import 'data/headmaster_repository.dart';
import 'features/attendance/view/attendance_view.dart';
import 'features/classes/binding/classes_binding.dart';
import 'features/classes/view/classes_view.dart';
import 'features/dashboard/binding/dashboard_binding.dart';
import 'features/dashboard/view/dashboard_view.dart';
import 'features/exams/binding/exams_binding.dart';
import 'features/exams/view/exams_view.dart';
import 'features/fees/binding/fees_binding.dart';
import 'features/fees/view/fees_view.dart';
import '../../config/headmaster_routes.dart';
import 'package:shared/shared.dart';

/// Headmaster module shell — hosts the 5 tabs (Dashboard / People / Schedule /
/// Finance / Reports) behind a persistent dark bottom nav. Drill-in screens
/// (School Overview, Students, Guardians, Announcements, Analytics) are routed
/// pages that overlay the shell.
class HeadmasterShell extends StatefulWidget {
  const HeadmasterShell({super.key});

  @override
  State<HeadmasterShell> createState() => _HeadmasterShellState();
}

class _HeadmasterShellState extends State<HeadmasterShell> {
  static const _tabs = [
    PortalTab(AppIcons.dashboardRounded, 'Dashboard'),
    PortalTab(AppIcons.groupsRounded, 'People'),
    PortalTab(AppIcons.eventNoteRounded, 'Schedule'),
    PortalTab(AppIcons.paymentsOutlined, 'Finance'),
    PortalTab(AppIcons.insightsRounded, 'Reports'),
  ];

  @override
  void initState() {
    super.initState();
    // Module-wide data gateway shared by every Headmaster controller. Registered
    // before the feature bindings so their controllers can `Get.find` it.
    if (!Get.isRegistered<HeadmasterRepository>()) {
      Get.put<HeadmasterRepository>(HeadmasterRepository(), permanent: true);
    }
    DashboardBinding().dependencies();
    ClassesBinding().dependencies();
    ExamsBinding().dependencies();
    FeesBinding().dependencies();
    // AttendanceView is self-contained (it reads teacher attendance straight
    // from the repository), so it needs no binding of its own.
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      DashboardView(
        onAnnouncements: () => Get.toNamed(HeadmasterRoutes.announcements),
        onSettings: () => Get.toNamed(HeadmasterRoutes.settings),
        onSalary: () => Get.toNamed(HeadmasterRoutes.salary),
      ),
      const ClassesView(),
      ExamsView(
        onTimetable: () => Get.toNamed(HeadmasterRoutes.timetable),
      ),
      const FeesView(),
      AttendanceView(
        onAnalytics: () => Get.toNamed(HeadmasterRoutes.analytics),
      ),
    ];

    return PortalTabScaffold(title: 'Headmaster', tabs: _tabs, screens: tabs);
  }
}
