import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/student_routes.dart';
import '../../widgets/portal_tab_scaffold.dart';
import 'data/student_repository.dart';
import 'features/assignments/binding/assignments_binding.dart';
import 'features/assignments/controller/assignments_controller.dart';
import 'features/assignments/models/assignment.dart';
import 'features/assignments/view/assignments_view.dart';
import 'features/attendance/binding/attendance_binding.dart';
import 'features/attendance/view/attendance_view.dart';
import 'features/dashboard/binding/dashboard_binding.dart';
import 'features/dashboard/controller/dashboard_controller.dart';
import 'features/dashboard/view/dashboard_view.dart';
import 'features/exams/binding/exams_binding.dart';
import 'features/exams/view/exams_view.dart';
import 'package:shared/shared.dart';

/// Student module shell — 4-tab nav (Home / Schedule=Exam Schedule /
/// Assignments / Profile=My Attendance). Drill-in routes: assignment detail
/// (Submission flow) and Notifications Center.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  static const _tabs = [
    PortalTab(AppIcons.dashboardRounded, 'Home'),
    PortalTab(AppIcons.eventNoteRounded, 'Exams'),
    PortalTab(AppIcons.assignmentOutlined, 'Assignments'),
    PortalTab(AppIcons.eventAvailableRounded, 'Attendance'),
  ];

  void _openNotifications() => Get.toNamed(StudentRoutes.notifications);

  /// Opens the assignment / submission screen. When the student turns work in
  /// (the screen pops with `true`), reload the dashboard and assignments list so
  /// the "Due Soon" and status pills reflect the fresh Submitted state instead
  /// of the stale "Not Started".
  Future<void> _openAssignment(StudentAssignment a) async {
    final submitted = await Get.toNamed(
      StudentRoutes.assignmentDetail,
      arguments: a,
    );
    if (submitted != true) return;
    if (Get.isRegistered<StudentDashboardController>()) {
      await Get.find<StudentDashboardController>().load();
    }
    if (Get.isRegistered<StudentAssignmentsController>()) {
      await Get.find<StudentAssignmentsController>().load();
    }
  }

  @override
  void initState() {
    super.initState();
    // Module-wide data gateway shared by every Student controller. Registered
    // before the feature bindings so their controllers can `Get.find` it.
    if (!Get.isRegistered<StudentRepository>()) {
      Get.put<StudentRepository>(StudentRepository(), permanent: true);
    }
    DashboardBinding().dependencies();
    ExamsBinding().dependencies();
    AssignmentsBinding().dependencies();
    AttendanceBinding().dependencies();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      DashboardView(
        onNotifications: _openNotifications,
        onOpenQuizzes: () => Get.toNamed(StudentRoutes.quizzes),
        onOpenAssignment: _openAssignment,
      ),
      ExamsView(onNotifications: _openNotifications),
      AssignmentsView(
        onNotifications: _openNotifications,
        onOpenAssignment: _openAssignment,
      ),
      AttendanceView(onNotifications: _openNotifications),
    ];

    return PortalTabScaffold(title: 'Student', tabs: _tabs, screens: tabs);
  }
}
