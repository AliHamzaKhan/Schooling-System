import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../config/student_routes.dart';
import '../../widgets/portal_bottom_nav.dart';
import 'data/student_repository.dart';
import 'features/assignments/binding/assignments_binding.dart';
import 'features/assignments/view/assignments_view.dart';
import 'features/attendance/binding/attendance_binding.dart';
import 'features/attendance/view/attendance_view.dart';
import 'features/dashboard/view/dashboard_view.dart';
import 'features/exams/binding/exams_binding.dart';
import 'features/exams/view/exams_view.dart';

/// Student module shell — 4-tab nav (Home / Schedule=Exam Schedule /
/// Assignments / Profile=My Attendance). Drill-in routes: assignment detail
/// (Submission flow) and Notifications Center.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  static const _items = [
    PortalNavItem(icon: Icons.dashboard_rounded, label: 'Home'),
    PortalNavItem(icon: Icons.event_note_rounded, label: 'Schedule'),
    PortalNavItem(icon: Icons.assignment_outlined, label: 'Assignments'),
    PortalNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  void _goTo(int i) => setState(() => _index = i);
  void _openNotifications() => Get.toNamed(StudentRoutes.notifications);

  @override
  void initState() {
    super.initState();
    // Module-wide data gateway shared by every Student controller. Registered
    // before the feature bindings so their controllers can `Get.find` it.
    if (!Get.isRegistered<StudentRepository>()) {
      Get.put<StudentRepository>(StudentRepository(), permanent: true);
    }
    ExamsBinding().dependencies();
    AssignmentsBinding().dependencies();
    AttendanceBinding().dependencies();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      DashboardView(onNotifications: _openNotifications),
      ExamsView(onNotifications: _openNotifications),
      AssignmentsView(
        onNotifications: _openNotifications,
        onOpenAssignment: (id) => Get.toNamed(
          StudentRoutes.assignmentDetail,
          arguments: id,
        ),
      ),
      AttendanceView(onNotifications: _openNotifications),
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
