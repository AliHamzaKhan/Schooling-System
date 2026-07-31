import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/teacher_routes.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../controller/dashboard_controller.dart';
import '../../calendar/models/timetable_slot.dart';
import '../models/dashboard_data.dart';
import '../../../../../widgets/skeletons.dart';

/// Teacher Dashboard — greeting, quick action stack, today's schedule,
/// to-do list with urgent count badge, and a "Recent Activity" section.
class DashboardView extends GetView<TeacherDashboardController> {
  final VoidCallback? onChat;
  final VoidCallback? onMarkAttendance;
  final VoidCallback? onAddAssignment;
  final VoidCallback? onAnnounce;
  final VoidCallback? onViewCalendar;
  final VoidCallback? onViewAllTasks;

  const DashboardView({
    super.key,
    this.onChat,
    this.onMarkAttendance,
    this.onAddAssignment,
    this.onAnnounce,
    this.onViewCalendar,
    this.onViewAllTasks,
  });

  /// Maps a data-driven quick action to its destination by label so the mock/
  /// backend controls copy while routing stays in the shell.
  VoidCallback? _actionTap(QuickAction action) {
    final label = action.label.toLowerCase();
    if (label.contains('attendance')) return onMarkAttendance;
    if (label.contains('assignment')) return onAddAssignment;
    if (label.contains('announce')) return onAnnounce;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PortalTopBar(
          title: 'Teacher Portal',
          onBell: onChat,
        ),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const SkeletonPage(body: Column(children: [SkeletonStatGrid(count: 2), SizedBox(height: AppSpacing.stackLg), SkeletonCardList(count: 3)]));
            }
            final data = controller.data.value;
            if (data == null) {
              return Center(
                  child: Text(controller.error.value ?? 'No data',
                      style: AppTypography.bodyLg));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  0,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl),
              children: [
                Text(data.greeting, style: AppTypography.headlineLg),
                const SizedBox(height: AppSpacing.stackSm),
                Text(data.summary, style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackLg),

                // Quick actions stack.
                GlassSurface(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.stackLg,
                      vertical: AppSpacing.stackMd),
                  child: Column(
                    children: [
                      for (var i = 0; i < _quickActions.length; i++) ...[
                        _QuickActionRow(
                          action: _quickActions[i],
                          onTap: _actionTap(_quickActions[i]),
                        ),
                        if (i != _quickActions.length - 1)
                          const SizedBox(height: AppSpacing.stackSm),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                // Leave requests from this teacher's section students.
                GlassSurface(
                  onTap: () => Get.toNamed(TeacherRoutes.leaveReview),
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available_outlined,
                          color: AppColors.primary),
                      const SizedBox(width: AppSpacing.stackMd),
                      Expanded(
                        child: Text('Leave Requests',
                            style: AppTypography.titleMd
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.onSurfaceVariant),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                // Today's schedule.
                SectionHeader(
                  title: "Today's Schedule",
                  actionLabel: 'View Calendar',
                  onAction: onViewCalendar,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                for (final s in data.schedule) ...[
                  _ScheduleRow(item: s),
                  const SizedBox(height: AppSpacing.stackSm),
                ],
                const SizedBox(height: AppSpacing.stackMd),

                // To-Do List.
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text('To-Do List',
                                  style: AppTypography.titleLg)),
                          if (data.urgentCount > 0) _UrgentBadge(count: data.urgentCount),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      if (data.todos.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.stackMd),
                          child: Text('Nothing outstanding — you\u2019re all caught up.',
                              style: AppTypography.bodyMd),
                        )
                      else
                        for (final t in data.todos) ...[
                          _TodoRow(
                            todo: t,
                            onTap: t.kind == 'grading'
                                ? onViewAllTasks
                                : onViewAllTasks,
                          ),
                          const SizedBox(height: AppSpacing.stackMd),
                        ],
                      GhostButton(
                        label: 'View All Tasks',
                        expanded: true,
                        onPressed: onViewAllTasks,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                // Recent Activity.
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Activity', style: AppTypography.titleLg),
                      const SizedBox(height: AppSpacing.stackMd),
                      Row(
                        children: [
                          Expanded(
                            child: _ActivityStat(
                                value: '${data.pendingGrades}',
                                label: 'Pending Grades',
                                color: AppColors.aiAccent),
                          ),
                          const SizedBox(width: AppSpacing.stackMd),
                          Expanded(
                            child: _ActivityStat(
                                value: '${data.newSubmissions}',
                                label: 'New Submissions',
                                color: AppColors.tertiary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      Text('Latest Activity',
                          style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: AppSpacing.stackSm),
                      if (data.recentActivity.isEmpty)
                        Text('Nothing posted yet.', style: AppTypography.bodyMd)
                      else
                        for (final a in data.recentActivity)
                          _ActivityRow(activity: a),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

/// Navigation shortcuts. These are routes, not records — there is nothing for
/// the backend to return, so they live with the UI rather than being faked into
/// the dashboard payload.
const _quickActions = <QuickAction>[
  QuickAction(
    label: 'Mark Attendance',
    subtitle: 'Take today\u2019s register',
    icon: Icons.fact_check_outlined,
    color: AppColors.tertiary,
  ),
  QuickAction(
    label: 'Add Assignment',
    subtitle: 'Homework, exam or quiz',
    icon: Icons.assignment_outlined,
    color: AppColors.primary,
  ),
  QuickAction(
    label: 'Announce',
    subtitle: 'Send a class update',
    icon: Icons.campaign_outlined,
    color: AppColors.aiAccent,
  ),
];

class _QuickActionRow extends StatelessWidget {
  final QuickAction action;
  final VoidCallback? onTap;
  const _QuickActionRow({required this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: action.color, size: 20),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.label,
                        style: AppTypography.titleMd
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text(action.subtitle, style: AppTypography.bodySm),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final TeacherSlot item;
  const _ScheduleRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: item.isClassTeacher ? AppColors.primary : AppColors.tertiary,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.stackMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.timeRange.split(' – ').first,
                      style: AppTypography.titleLg
                          .copyWith(fontWeight: FontWeight.w800)),
                  Text('${item.className} ${item.sectionName}',
                      style: AppTypography.labelCaps
                          .copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.stackMd, horizontal: AppSpacing.stackSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: AppTypography.titleMd
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(item.room ?? '—', style: AppTypography.bodySm),
                        if (item.studentCount > 0) ...[
                          const SizedBox(width: AppSpacing.stackMd),
                          const Icon(Icons.people_alt_outlined,
                              size: 13, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('${item.studentCount} Students',
                              style: AppTypography.bodySm),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UrgentBadge extends StatelessWidget {
  final int count;
  const _UrgentBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text('$count Urgent',
          style: AppTypography.labelMd
              .copyWith(color: AppColors.error, fontWeight: FontWeight.w800)),
    );
  }
}

class _TodoRow extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback? onTap;
  const _TodoRow({required this.todo, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Derived work can't be "ticked off" — the icon reflects what kind of work
    // it is, and tapping takes you where it gets resolved.
    final icon = todo.kind == 'exam'
        ? Icons.event_note_rounded
        : Icons.grading_rounded;
    final tint = todo.urgent ? AppColors.error : AppColors.primary;
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20, color: tint),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(todo.title,
                    style: AppTypography.bodyLg
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(todo.dueLine,
                    style: AppTypography.bodySm.copyWith(
                      color: todo.urgent
                          ? AppColors.error
                          : AppColors.onSurfaceVariant,
                      fontWeight: todo.urgent ? FontWeight.w700 : null,
                    )),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _ActivityStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _ActivityStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppTypography.displayLg.copyWith(fontSize: 32, color: color)),
          Text(label, style: AppTypography.bodyMd),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final RecentActivity activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final icon = activity.kind == 'announcement'
        ? Icons.campaign_outlined
        : Icons.assignment_outlined;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(activity.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMd),
          ),
          Text(activity.relative, style: AppTypography.bodySm),
        ],
      ),
    );
  }
}
