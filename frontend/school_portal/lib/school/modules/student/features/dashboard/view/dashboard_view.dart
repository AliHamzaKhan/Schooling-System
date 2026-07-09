import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/student_routes.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../../assignments/components/assignment_card.dart';
import '../../assignments/models/assignment.dart';
import '../../attendance/components/monthly_average_card.dart';
import '../../exams/components/countdown_card.dart';
import '../controller/dashboard_controller.dart';

/// Student Dashboard — a live at-a-glance summary: attendance, assignments due
/// soon, and the next exam. Aggregates the student's own live data.
/// The bell on the top bar opens the Notifications Center.
class DashboardView extends GetView<DashboardController> {
  final VoidCallback? onNotifications;
  final ValueChanged<StudentAssignment>? onOpenAssignment;
  final VoidCallback? onOpenQuizzes;
  const DashboardView({
    super.key,
    this.onNotifications,
    this.onOpenAssignment,
    this.onOpenQuizzes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PortalTopBar(title: 'EduMaster', onBell: onNotifications),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.error.value != null) {
              return Center(
                child: Text(controller.error.value!, style: AppTypography.bodyLg),
              );
            }
            final nextExam = controller.nextExam;
            final dueSoon = controller.dueSoon;
            final attendance = controller.attendance.value;
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  Text('Hi, ${controller.firstName} 👋',
                      style: AppTypography.headlineLg),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text("Here's your day at a glance.",
                      style: AppTypography.bodyLg),
                  const SizedBox(height: AppSpacing.stackLg),

                  // Quick stats.
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.event_available_rounded,
                          value: '${controller.attendancePercent}%',
                          label: 'Attendance',
                          accent: AppColors.tertiary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.stackMd),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.assignment_outlined,
                          value: '${controller.toDoCount}',
                          label: 'To-Do',
                          accent: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.stackMd),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.fact_check_outlined,
                          value: '${controller.examsThisMonth}',
                          label: 'Exams',
                          accent: const Color(0xFFE8A317),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackLg),

                  GhostButton(
                    label: 'Quizzes',
                    leadingIcon: Icons.quiz_outlined,
                    trailingIcon: Icons.chevron_right_rounded,
                    expanded: true,
                    onPressed: onOpenQuizzes,
                  ),
                  const SizedBox(height: AppSpacing.stackLg),

                  // Academic results (exams + quizzes).
                  GhostButton(
                    label: 'My Results',
                    leadingIcon: Icons.grading_rounded,
                    trailingIcon: Icons.chevron_right_rounded,
                    expanded: true,
                    onPressed: () => Get.toNamed(StudentRoutes.results),
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  GhostButton(
                    label: 'My Timetable',
                    leadingIcon: Icons.calendar_view_week_rounded,
                    trailingIcon: Icons.chevron_right_rounded,
                    expanded: true,
                    onPressed: () => Get.toNamed(StudentRoutes.timetable),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),

                  // Next exam countdown.
                  if (nextExam != null) ...[
                    CountdownCard(
                      next: nextExam,
                      onTap: controller.nextExamEntry == null
                          ? null
                          : () => Get.toNamed(StudentRoutes.examDetail,
                              arguments: controller.nextExamEntry),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                  ],

                  // Assignments due soon.
                  const SectionHeader(title: 'Due Soon'),
                  const SizedBox(height: AppSpacing.stackMd),
                  if (dueSoon.isEmpty)
                    _EmptyHint(text: "You're all caught up — nothing due.")
                  else
                    for (final a in dueSoon) ...[
                      AssignmentCard(
                        assignment: a,
                        onTap: () => onOpenAssignment?.call(a),
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                    ],
                  const SizedBox(height: AppSpacing.stackSm),

                  // Attendance detail.
                  if (attendance != null)
                    MonthlyAverageCard(
                      percent: attendance.monthlyAverage,
                      delta: attendance.deltaPercent,
                      week: attendance.week,
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(height: AppSpacing.stackSm),
          Text(value,
              style: AppTypography.titleLg.copyWith(fontWeight: FontWeight.w700)),
          Text(label,
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.tertiary, size: 20),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(child: Text(text, style: AppTypography.bodyMd)),
        ],
      ),
    );
  }
}
