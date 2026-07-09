import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

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

  // Tab indices, so dashboard quick actions can jump between tabs.
  static const _attendanceTab = 2;
  static const _tasksTab = 3;

  // Owned here (rather than by the scaffold) so the dashboard can switch tabs.
  final PersistentTabController _tabController =
      PersistentTabController(initialIndex: 0);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  void _goToTab(int index) => _tabController.jumpToTab(index);

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      DashboardView(
        onChat: () => Get.toNamed(TeacherRoutes.chat),
        onMarkAttendance: () => _goToTab(_attendanceTab),
        onAddAssignment: () => _goToTab(_tasksTab),
        onAnnounce: () => Get.toNamed(TeacherRoutes.chat),
        onViewCalendar: () => Get.toNamed(TeacherRoutes.calendar),
        onViewAllTasks: () => _goToTab(_tasksTab),
      ),
      ClassesView(
        onOpenClass: (c) =>
            Get.toNamed(TeacherRoutes.classDetail, arguments: c),
      ),
      const AttendanceClassesView(),
      AssignmentsView(
        onCreateHomework: () => Get.toNamed(TeacherRoutes.createHomework),
        onCreateExam: () => Get.toNamed(TeacherRoutes.createExam),
        onCreateQuiz: () => Get.toNamed(TeacherRoutes.createQuiz),
        onOpenGradebook: () => Get.toNamed(TeacherRoutes.gradebook),
        onOpenQuizzes: () => Get.toNamed(TeacherRoutes.quizzes),
      ),
      const StudentPerformanceView(),
    ];

    return PortalTabScaffold(
      title: 'Teacher',
      tabs: _tabs,
      screens: tabs,
      controller: _tabController,
    );
  }
}
