import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';

/// A single, grouped directory of the headmaster's management modules.
///
/// Several of these screens used to exist only as named routes, which made
/// them effectively invisible unless another screen happened to link to them.
/// The directory keeps mobile cards compact and becomes a multi-column control
/// panel on tablet/web.
class HeadmasterModuleDirectory extends StatefulWidget {
  final Set<String>? enabledModules;

  const HeadmasterModuleDirectory({super.key, this.enabledModules});

  static const _groups = <_ModuleGroup>[
    _ModuleGroup('People', [
      _ModuleItem(
        'Students',
        'Admissions and student records',
        AppIcons.schoolRounded,
        HeadmasterRoutes.students,
        requiredAny: {'student_management'},
      ),
      _ModuleItem(
        'Teachers',
        'Staff profiles and assignments',
        AppIcons.personOutlineRounded,
        HeadmasterRoutes.teachers,
        requiredAny: {'teacher_management'},
      ),
      _ModuleItem(
        'Guardians',
        'Family links and contacts',
        AppIcons.groupsRounded,
        HeadmasterRoutes.guardians,
        requiredAny: {'guardian_management'},
      ),
    ]),
    _ModuleGroup('Academics', [
      _ModuleItem(
        'Classes & sections',
        'Structure, rooms and homerooms',
        AppIcons.classOutlined,
        HeadmasterRoutes.classes,
        requiredAny: {'student_management'},
      ),
      _ModuleItem(
        'Timetable',
        'Weekly teaching schedule',
        AppIcons.gridViewRounded,
        HeadmasterRoutes.timetable,
        requiredAny: {'timetable'},
      ),
      _ModuleItem(
        'Courses',
        'Subjects, books and learning content',
        AppIcons.menuBookRounded,
        HeadmasterRoutes.coursesAdmin,
      ),
      _ModuleItem(
        'Exam setup',
        'Categories, dates and papers',
        AppIcons.eventNoteRounded,
        HeadmasterRoutes.examCategories,
        requiredAny: {'exams'},
      ),
      _ModuleItem(
        'Promotion',
        'Advance students by session',
        AppIcons.trendingUpRounded,
        HeadmasterRoutes.promotion,
        requiredAny: {'exams', 'results'},
      ),
    ]),
    _ModuleGroup('Operations', [
      _ModuleItem(
        'Announcements',
        'Campus-wide communication',
        AppIcons.campaignOutlined,
        HeadmasterRoutes.announcements,
        requiredAny: {'messaging'},
      ),
      _ModuleItem(
        'Leave requests',
        'Review pending applications',
        AppIcons.eventAvailableOutlined,
        HeadmasterRoutes.leaveReview,
        requiredAny: {'leave_management'},
      ),
      _ModuleItem(
        'Transport',
        'Fleet, routes and drivers',
        AppIcons.directionsBusOutlined,
        HeadmasterRoutes.transport,
        requiredAny: {'transport'},
      ),
      _ModuleItem(
        'School profile',
        'Branding and public information',
        AppIcons.apartmentRounded,
        HeadmasterRoutes.schoolInfoEdit,
      ),
      _ModuleItem(
        'Events',
        'Upcoming campus calendar',
        AppIcons.calendarMonthOutlined,
        HeadmasterRoutes.upcomingEvents,
      ),
    ]),
    _ModuleGroup('Finance & insight', [
      _ModuleItem(
        'Payroll',
        'Salaries and payslips',
        AppIcons.paymentsOutlined,
        HeadmasterRoutes.salary,
        requiredAny: {'hr_payroll'},
      ),
      _ModuleItem(
        'Teacher attendance',
        'Daily roster and history',
        AppIcons.factCheckOutlined,
        HeadmasterRoutes.teacherAttendance,
        requiredAny: {'attendance'},
      ),
      _ModuleItem(
        'Reports',
        'Attendance and performance trends',
        AppIcons.insightsRounded,
        HeadmasterRoutes.analytics,
        requiredAny: {'reports'},
      ),
      _ModuleItem(
        'Settings',
        'Session and school preferences',
        AppIcons.settingsOutlined,
        HeadmasterRoutes.settings,
      ),
    ]),
  ];

  @override
  State<HeadmasterModuleDirectory> createState() =>
      _HeadmasterModuleDirectoryState();
}

class _HeadmasterModuleDirectoryState extends State<HeadmasterModuleDirectory> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ModuleGroup> get _visibleGroups {
    final query = _query.trim().toLowerCase();
    return [
      for (final group in HeadmasterModuleDirectory._groups)
        if (group.items.any(
          (item) =>
              item.isEnabled(widget.enabledModules) &&
              item.matches(query, group.label),
        ))
          _ModuleGroup(
            group.label,
            group.items
                .where(
                  (item) =>
                      item.isEnabled(widget.enabledModules) &&
                      item.matches(query, group.label),
                )
                .toList(),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final groups = _visibleGroups;
        final columns = constraints.maxWidth >= 1080
            ? 3
            : constraints.maxWidth >= 680
            ? 2
            : 1;
        const gap = AppSpacing.stackMd;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage your school', style: AppTypography.titleLg),
            const SizedBox(height: 4),
            Text(
              'Everything is grouped by the work you need to do.',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            AppTextField(
              controller: _searchController,
              label: 'Search modules',
              hintText: 'Students, timetable, payroll…',
              prefixIcon: const Icon(AppIcons.searchRounded),
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            if (groups.isEmpty)
              AppStateView.empty(
                title: 'No modules found',
                message: 'Try a different name or type of school work.',
                actionLabel: 'Clear search',
                onAction: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
            for (final group in groups) ...[
              Text(
                group.label.toUpperCase(),
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in group.items)
                    SizedBox(
                      width: width,
                      child: _ModuleCard(item: item),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackLg),
            ],
          ],
        );
      },
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _ModuleItem item;
  const _ModuleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      semanticLabel: 'Open ${item.label}. ${item.description}',
      onTap: () => Get.toNamed(item.route),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Icon(item.icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: AppTypography.titleMd),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              AppIcons.chevronRightRounded,
              color: AppColors.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleGroup {
  final String label;
  final List<_ModuleItem> items;
  const _ModuleGroup(this.label, this.items);
}

class _ModuleItem {
  final String label;
  final String description;
  final IconData icon;
  final String route;
  final Set<String> requiredAny;
  const _ModuleItem(
    this.label,
    this.description,
    this.icon,
    this.route, {
    this.requiredAny = const {},
  });

  bool isEnabled(Set<String>? enabledModules) {
    if (enabledModules == null || requiredAny.isEmpty) return true;
    return requiredAny.any(enabledModules.contains);
  }

  bool matches(String query, String group) {
    return label.toLowerCase().contains(query) ||
        description.toLowerCase().contains(query) ||
        group.toLowerCase().contains(query);
  }
}
