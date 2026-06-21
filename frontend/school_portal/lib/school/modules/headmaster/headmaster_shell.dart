import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../widgets/portal_bottom_nav.dart';
import 'data/headmaster_repository.dart';
import 'features/attendance/binding/attendance_binding.dart';
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
  int _index = 0;

  static const _items = [
    PortalNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    PortalNavItem(icon: Icons.groups_rounded, label: 'People'),
    PortalNavItem(icon: Icons.event_note_rounded, label: 'Schedule'),
    PortalNavItem(icon: Icons.payments_outlined, label: 'Finance'),
    PortalNavItem(icon: Icons.insights_rounded, label: 'Reports'),
  ];

  void _goTo(int i) => setState(() => _index = i);

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
    AttendanceBinding().dependencies();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      DashboardView(
        onAnnouncements: () => Get.toNamed(HeadmasterRoutes.announcements),
        onSchoolOverview: () => Get.toNamed(HeadmasterRoutes.schoolOverview),
      ),
      ClassesView(
        onManageStudents: () => Get.toNamed(HeadmasterRoutes.students),
        onManageGuardians: () => Get.toNamed(HeadmasterRoutes.guardians),
        onManageTeachers: () => Get.toNamed(HeadmasterRoutes.teachers),
      ),
      ExamsView(
        onTimetable: () => Get.toNamed(HeadmasterRoutes.timetable),
      ),
      const FeesView(),
      AttendanceView(
        onAnalytics: () => Get.toNamed(HeadmasterRoutes.analytics),
      ),
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
