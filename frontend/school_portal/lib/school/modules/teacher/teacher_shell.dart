import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../config/teacher_routes.dart';
import '../../widgets/portal_app_bar.dart';
import '../../widgets/portal_bottom_nav.dart';
import 'data/teacher_repository.dart';
import 'features/assignments/binding/assignments_binding.dart';
import 'features/assignments/view/assignments_view.dart';
import 'features/attendance/binding/attendance_binding.dart';
import 'features/attendance/view/attendance_classes_view.dart';
import 'features/classes/binding/classes_binding.dart';
import 'features/classes/view/classes_view.dart';
import 'features/dashboard/binding/dashboard_binding.dart';
import 'features/dashboard/view/dashboard_view.dart';
import 'features/performance/binding/performance_binding.dart';
import 'features/performance/view/performance_view.dart';

/// Teacher module shell — hosts the 5 tabs (Home / Classes / Attendance /
/// Tasks / Performance) behind a persistent dark bottom nav. Drill-in screens
/// (attendance marking, create homework / exam, chat, gradebook, student
/// performance detail) are routed pages that overlay the shell.
class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _index = 0;

  static const _items = [
    PortalNavItem(icon: Icons.dashboard_rounded, label: 'Home'),
    PortalNavItem(icon: Icons.groups_rounded, label: 'Classes'),
    PortalNavItem(icon: Icons.fact_check_outlined, label: 'Attendance'),
    PortalNavItem(icon: Icons.assignment_outlined, label: 'Tasks'),
    PortalNavItem(icon: Icons.insights_rounded, label: 'Performance'),
  ];

  void _goTo(int i) => setState(() => _index = i);

  @override
  void initState() {
    super.initState();
    // Module-wide data gateway shared by every Teacher controller. Registered
    // before the feature bindings so their controllers can `Get.find` it.
    if (!Get.isRegistered<TeacherRepository>()) {
      Get.put<TeacherRepository>(TeacherRepository(), permanent: true);
    }
    DashboardBinding().dependencies();
    ClassesBinding().dependencies();
    AttendanceBinding().dependencies();
    AssignmentsBinding().dependencies();
    PerformanceBinding().dependencies();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      DashboardView(
        onChat: () => Get.toNamed(TeacherRoutes.chat),
      ),
      const ClassesView(),
      const AttendanceClassesView(),
      AssignmentsView(
        onCreateHomework: () => Get.toNamed(TeacherRoutes.createHomework),
        onCreateExam: () => Get.toNamed(TeacherRoutes.createExam),
        onOpenGradebook: () => Get.toNamed(TeacherRoutes.gradebook),
      ),
      const StudentPerformanceView(),
    ];

    return AppScaffold(
      appBar: const PortalAppBar(title: 'Teacher'),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: PortalBottomNav(
        currentIndex: _index,
        onTap: _goTo,
        items: _items,
      ),
    );
  }
}
