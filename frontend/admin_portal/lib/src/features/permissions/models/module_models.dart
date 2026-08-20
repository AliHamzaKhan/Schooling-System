import 'package:flutter/material.dart';
import '../../../ui/admin_theme.dart';
import 'package:shared/shared.dart';

/// Per-module access status for a school, mirroring the backend `ModuleStatus`.
///
/// [inPlan] — the module is unlocked by the school's subscription plan.
/// [toggleEnabled] — the Super Admin's explicit on/off (defaults on when no row
/// exists). [effective] = [inPlan] AND [toggleEnabled] — what the school can
/// actually use. A module that is not [inPlan] cannot be turned on here; the
/// school must be moved to a plan that includes it first.
class ModuleStatus {
  final String module;
  final bool inPlan;
  final bool toggleEnabled;
  final bool effective;

  const ModuleStatus({
    required this.module,
    required this.inPlan,
    required this.toggleEnabled,
    required this.effective,
  });

  ModuleStatus copyWith({bool? toggleEnabled}) => ModuleStatus(
        module: module,
        inPlan: inPlan,
        toggleEnabled: toggleEnabled ?? this.toggleEnabled,
        // Keep [effective] consistent locally so the UI reflects edits before
        // the server round-trip returns the authoritative view.
        effective: inPlan && (toggleEnabled ?? this.toggleEnabled),
      );

  factory ModuleStatus.fromJson(Map<String, dynamic> j) => ModuleStatus(
        module: j['module'] as String? ?? '',
        inPlan: j['in_plan'] as bool? ?? false,
        toggleEnabled: j['toggle_enabled'] as bool? ?? true,
        effective: j['effective'] as bool? ?? false,
      );
}

/// The Super Admin's view of one school's module access — the backend
/// `SchoolModulesView` (plan ∩ toggles).
class SchoolModulesView {
  final String schoolId;
  final String? planCode;
  final List<String> effectiveModules;
  final List<ModuleStatus> modules;

  const SchoolModulesView({
    required this.schoolId,
    required this.planCode,
    required this.effectiveModules,
    required this.modules,
  });

  int get activeCount => modules.where((m) => m.effective).length;
  int get totalCount => modules.length;

  factory SchoolModulesView.fromJson(Map<String, dynamic> j) => SchoolModulesView(
        schoolId: j['school_id']?.toString() ?? '',
        planCode: j['plan_code'] as String?,
        effectiveModules:
            (j['effective_modules'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        modules: (j['modules'] as List?)
                ?.map((e) => ModuleStatus.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

/// A single module on/off instruction sent to the backend (`ModuleToggle`).
class ModuleToggle {
  final String module;
  final bool enabled;
  const ModuleToggle({required this.module, required this.enabled});

  Map<String, dynamic> toJson() => {'module': module, 'enabled': enabled};
}

/// Display metadata for a module key: a human label, an icon, and the section
/// it belongs to on the editor. Keys are the backend `Module` enum values.
class ModuleMeta {
  final String key;
  final String label;
  final String subtitle;
  final IconData icon;
  const ModuleMeta(this.key, this.label, this.subtitle, this.icon);
}

/// A titled group of modules on the per-school editor.
class ModuleGroup {
  final String title;
  final IconData icon;
  final Color color;
  final List<ModuleMeta> modules;
  const ModuleGroup(this.title, this.icon, this.color, this.modules);
}

/// Static catalog of every toggleable module, grouped for display. Mirrors the
/// backend `Module` enum (17 modules); the AI group is what lets a school be
/// restricted from AI quiz & exam generation.
class ModuleCatalog {
  ModuleCatalog._();

  static const groups = <ModuleGroup>[
    ModuleGroup('Academics', AppIcons.menuBookOutlined, AdminPalette.ink, [
      ModuleMeta('student_management', 'Student Management',
          'Enrollment, profiles and records', AppIcons.schoolOutlined),
      ModuleMeta('teacher_management', 'Teacher Management',
          'Staff profiles and assignments', AppIcons.coPresentOutlined),
      ModuleMeta('guardian_management', 'Guardian Management',
          'Parent/guardian accounts and links', AppIcons.familyRestroomOutlined),
      ModuleMeta('attendance', 'Attendance',
          'Daily and subject attendance', AppIcons.factCheckOutlined),
      ModuleMeta('homework', 'Homework',
          'Assign and track homework', AppIcons.assignmentOutlined),
      ModuleMeta('exams', 'Exams',
          'Exam scheduling and grading', AppIcons.editNoteOutlined),
      ModuleMeta('results', 'Results',
          'Report cards and result publishing', AppIcons.gradingOutlined),
      ModuleMeta('timetable', 'Timetable',
          'Class and period scheduling', AppIcons.calendarViewWeekOutlined),
    ]),
    ModuleGroup('Operations', AppIcons.apartmentOutlined, AdminPalette.warning, [
      ModuleMeta('fee_management', 'Fee Management',
          'Fee structures and collection', AppIcons.paymentsOutlined),
      ModuleMeta('hr_payroll', 'HR & Payroll',
          'Staff payroll and HR records', AppIcons.badgeOutlined),
      ModuleMeta('inventory', 'Inventory',
          'Assets and stock tracking', AppIcons.inventory2Outlined),
      ModuleMeta('transport', 'Transport',
          'Routes and vehicle tracking', AppIcons.directionsBusOutlined),
    ]),
    ModuleGroup('Engagement', AppIcons.forumOutlined, AdminPalette.positive, [
      ModuleMeta('messaging', 'Messaging',
          'In-app announcements and chat', AppIcons.chatOutlined),
      ModuleMeta('meetings', 'Meetings',
          'Parent-teacher meetings', AppIcons.groupsOutlined),
      ModuleMeta('leave_management', 'Leave Management',
          'Leave requests and approvals', AppIcons.eventBusyOutlined),
      ModuleMeta('reports', 'Reports',
          'Analytics and exports', AppIcons.insightsOutlined),
    ]),
    ModuleGroup('AI', AppIcons.autoAwesomeOutlined, AdminPalette.info, [
      ModuleMeta('ai_features', 'AI Features',
          'AI quiz & exam generation', AppIcons.smartToyOutlined),
    ]),
  ];

  /// Looks up display metadata for a module key, falling back to a titleized
  /// label so unknown/future backend modules still render.
  static ModuleMeta metaFor(String key) {
    for (final g in groups) {
      for (final m in g.modules) {
        if (m.key == key) return m;
      }
    }
    final label = key
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    return ModuleMeta(key, label, '', AppIcons.extensionOutlined);
  }
}
