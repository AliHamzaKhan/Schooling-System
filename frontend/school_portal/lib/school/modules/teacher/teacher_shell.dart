import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/teacher_routes.dart';
import '../../widgets/portal_tab_scaffold.dart';
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
  static const _tabs = [
    PortalTab(Icons.dashboard_rounded, 'Home'),
    PortalTab(Icons.groups_rounded, 'Classes'),
    PortalTab(Icons.fact_check_outlined, 'Attendance'),
    PortalTab(Icons.assignment_outlined, 'Tasks'),
    PortalTab(Icons.insights_rounded, 'Performance'),
  ];

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

    return PortalTabScaffold(title: 'Teacher', tabs: _tabs, screens: tabs);
  }
}
