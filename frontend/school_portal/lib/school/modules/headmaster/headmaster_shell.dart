import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/portal_tab_scaffold.dart';
import 'controller/headmaster_workspace_controller.dart';
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
  @override
  void initState() {
    super.initState();
    // Module-wide data gateway shared by every Headmaster controller. Registered
    // before the feature bindings so their controllers can `Get.find` it.
    if (!Get.isRegistered<HeadmasterRepository>()) {
      Get.put<HeadmasterRepository>(HeadmasterRepository(), permanent: true);
    }
    if (!Get.isRegistered<HeadmasterWorkspaceController>()) {
      Get.put<HeadmasterWorkspaceController>(HeadmasterWorkspaceController());
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
    final workspace = Get.find<HeadmasterWorkspaceController>();
    return Obx(() {
      if (workspace.loading.value) {
        return const AppScaffold(
          body: AppStateView.loading(
            title: 'Loading school workspace',
            message: 'Checking your modules and active academic session.',
          ),
        );
      }
      final workspaceContext = workspace.context.value;
      if (workspaceContext == null) {
        return AppScaffold(
          body: AppStateView.error(
            title: 'Could not open school workspace',
            message:
                workspace.error.value ?? 'Workspace access is unavailable.',
            actionLabel: 'Try again',
            onAction: workspace.load,
          ),
        );
      }

      final modules = workspaceContext.enabledModules;
      final specs = <_HeadmasterTabSpec>[
        _HeadmasterTabSpec(
          const PortalTab(AppIcons.dashboardRounded, 'Dashboard'),
          DashboardView(
            enabledModules: modules,
            onAnnouncements: () => Get.toNamed(HeadmasterRoutes.announcements),
            onSettings: () => Get.toNamed(HeadmasterRoutes.settings),
            onSalary: () => Get.toNamed(HeadmasterRoutes.salary),
          ),
        ),
        const _HeadmasterTabSpec(
          PortalTab(AppIcons.groupsRounded, 'People'),
          ClassesView(),
          requiredAny: {
            'student_management',
            'teacher_management',
            'guardian_management',
          },
        ),
        _HeadmasterTabSpec(
          const PortalTab(AppIcons.eventNoteRounded, 'Schedule'),
          ExamsView(onTimetable: () => Get.toNamed(HeadmasterRoutes.timetable)),
          requiredAny: const {'exams', 'timetable'},
        ),
        const _HeadmasterTabSpec(
          PortalTab(AppIcons.paymentsOutlined, 'Finance'),
          FeesView(),
          requiredAny: {'fee_management'},
        ),
        _HeadmasterTabSpec(
          const PortalTab(AppIcons.insightsRounded, 'Reports'),
          AttendanceView(
            onAnalytics: () => Get.toNamed(HeadmasterRoutes.analytics),
          ),
          requiredAny: const {'attendance', 'reports'},
        ),
      ].where((spec) => spec.isEnabled(modules)).toList();

      return PortalTabScaffold(
        key: ValueKey((modules.toList()..sort()).join('|')),
        title: 'Headmaster',
        tabs: [for (final spec in specs) spec.tab],
        screens: [for (final spec in specs) spec.screen],
        schoolName: workspaceContext.schoolName,
        sessionName: workspaceContext.activeSession,
      );
    });
  }
}

class _HeadmasterTabSpec {
  final PortalTab tab;
  final Widget screen;
  final Set<String> requiredAny;

  const _HeadmasterTabSpec(
    this.tab,
    this.screen, {
    this.requiredAny = const {},
  });

  bool isEnabled(Set<String> modules) =>
      requiredAny.isEmpty || requiredAny.any(modules.contains);
}
