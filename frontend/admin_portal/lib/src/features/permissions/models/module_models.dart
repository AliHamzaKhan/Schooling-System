import 'package:flutter/material.dart';
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
/// backend `Module` enum (21 modules); the AI group is what lets a school be
/// restricted from AI quizzes / AI insights.
class ModuleCatalog {
  ModuleCatalog._();

  static const groups = <ModuleGroup>[
    ModuleGroup('Academics', Icons.menu_book_outlined, AppColors.primary, [
      ModuleMeta('student_management', 'Student Management',
          'Enrollment, profiles and records', Icons.school_outlined),
      ModuleMeta('teacher_management', 'Teacher Management',
          'Staff profiles and assignments', Icons.co_present_outlined),
      ModuleMeta('guardian_management', 'Guardian Management',
          'Parent/guardian accounts and links', Icons.family_restroom_outlined),
      ModuleMeta('attendance', 'Attendance',
          'Daily and subject attendance', Icons.fact_check_outlined),
      ModuleMeta('homework', 'Homework',
          'Assign and track homework', Icons.assignment_outlined),
      ModuleMeta('exams', 'Exams',
          'Exam scheduling and grading', Icons.edit_note_outlined),
      ModuleMeta('results', 'Results',
          'Report cards and result publishing', Icons.grading_outlined),
      ModuleMeta('timetable', 'Timetable',
          'Class and period scheduling', Icons.calendar_view_week_outlined),
    ]),
    ModuleGroup('Operations', Icons.apartment_outlined, Color(0xFFE8A317), [
      ModuleMeta('fee_management', 'Fee Management',
          'Fee structures and collection', Icons.payments_outlined),
      ModuleMeta('hr_payroll', 'HR & Payroll',
          'Staff payroll and HR records', Icons.badge_outlined),
      ModuleMeta('inventory', 'Inventory',
          'Assets and stock tracking', Icons.inventory_2_outlined),
      ModuleMeta('library', 'Library',
          'Catalog and lending', Icons.local_library_outlined),
      ModuleMeta('transport', 'Transport',
          'Routes and vehicle tracking', Icons.directions_bus_outlined),
      ModuleMeta('hostel', 'Hostel',
          'Rooms and boarding', Icons.night_shelter_outlined),
    ]),
    ModuleGroup('Engagement', Icons.forum_outlined, AppColors.tertiary, [
      ModuleMeta('messaging', 'Messaging',
          'In-app announcements and chat', Icons.chat_outlined),
      ModuleMeta('online_classes', 'Online Classes',
          'Live and recorded classes', Icons.video_camera_front_outlined),
      ModuleMeta('meetings', 'Meetings',
          'Parent-teacher meetings', Icons.groups_outlined),
      ModuleMeta('leave_management', 'Leave Management',
          'Leave requests and approvals', Icons.event_busy_outlined),
      ModuleMeta('reports', 'Reports',
          'Analytics and exports', Icons.insights_outlined),
    ]),
    ModuleGroup('AI & Platform', Icons.auto_awesome_outlined, AppColors.aiAccent, [
      ModuleMeta('ai_features', 'AI Features',
          'AI quizzes, insights and summaries', Icons.smart_toy_outlined),
      ModuleMeta('mobile_app', 'Mobile App',
          'Access via mobile clients', Icons.phone_iphone_outlined),
      ModuleMeta('api_access', 'API Access',
          'Programmatic API tokens', Icons.api_outlined),
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
    return ModuleMeta(key, label, '', Icons.extension_outlined);
  }
}
