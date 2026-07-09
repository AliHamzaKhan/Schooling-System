import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_search_field.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../components/exam_schedule_row.dart';
import '../components/exam_stat_card.dart';
import '../components/grade_distribution_chart.dart';
import '../controller/exams_controller.dart';
import '../models/exams_data.dart';

/// Exams & Results — manage assessments and review performance.
class ExamsView extends GetView<ExamsController> {
  final VoidCallback? onTimetable;
  const ExamsView({super.key, this.onTimetable});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalTopBar(showAvatar: true),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator());
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
                Text('Exams & Results', style: AppTypography.headlineLg),
                const SizedBox(height: AppSpacing.stackSm),
                Text('Manage upcoming assessments and review performance.',
                    style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackLg),
                Row(
                  children: [
                    Expanded(
                      child: ExamStatCard(
                        label: 'Active Exams',
                        value: '${data.activeExams}',
                        accent: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackMd),
                    Expanded(
                      child: ExamStatCard(
                        label: 'Upcoming',
                        value: '${data.upcomingExams}',
                        accent: const Color(0xFFE8A317),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Row(
                  children: [
                    Expanded(
                      child: ExamStatCard(
                        label: 'Pending Results',
                        value: '${data.pendingResults}',
                        accent: AppColors.tertiary,
                        trailing: Obx(() => PrimaryButton(
                              label: 'Publish All',
                              trailingIcon: null,
                              isLoading: controller.publishing.value,
                              onPressed: controller.publishing.value
                                  ? null
                                  : controller.publishAll,
                            )),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                GhostButton(
                  label: 'Open Timetable Management',
                  leadingIcon: Icons.grid_view_rounded,
                  trailingIcon: Icons.chevron_right_rounded,
                  expanded: true,
                  onPressed: onTimetable,
                ),
                const SizedBox(height: AppSpacing.stackLg),

                // Exam schedule card.
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => SectionHeader(
                            title: 'Exam Schedule',
                            actionLabel: controller.activeFilterCount > 0
                                ? 'Filter (${controller.activeFilterCount})'
                                : 'Filter',
                            actionIcon: Icons.filter_list_rounded,
                            onAction: controller.openScheduleFilter,
                          )),
                      const SizedBox(height: AppSpacing.stackMd),
                      Obx(() {
                        final schedule = controller.visibleSchedule;
                        if (schedule.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.stackMd),
                            child: Text('No exams match your filters.',
                                style: AppTypography.bodyMd),
                          );
                        }
                        return Column(
                          children: [
                            for (var i = 0; i < schedule.length; i++) ...[
                              ExamScheduleRow(item: schedule[i]),
                              if (i != schedule.length - 1)
                                const SizedBox(height: AppSpacing.stackSm),
                            ],
                          ],
                        );
                      }),
                      const SizedBox(height: AppSpacing.stackMd),
                      Center(
                        child: TextButton(
                          onPressed: onTimetable,
                          child: Text('View Full Schedule',
                              style: AppTypography.labelMd
                                  .copyWith(color: AppColors.primary)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                // Student results card.
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Student Results', style: AppTypography.titleLg),
                      const SizedBox(height: AppSpacing.stackMd),
                      PortalSearchField(
                        hint: 'Search by name or ID…',
                        onChanged: controller.onSearch,
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      Text('RECENT VIEWED',
                          style: AppTypography.labelCaps
                              .copyWith(color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: AppSpacing.stackSm),
                      for (final r in data.recent) ...[
                        _RecentRow(student: r),
                        if (r != data.recent.last) const SizedBox(height: 6),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                // Grade distribution card.
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Grade Distribution', style: AppTypography.titleLg),
                      const SizedBox(height: 2),
                      Text('Recent Midterms Overview', style: AppTypography.bodySm),
                      const SizedBox(height: AppSpacing.stackLg),
                      GradeDistributionChart(distribution: data.gradeDistribution),
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

class _RecentRow extends StatelessWidget {
  final RecentStudent student;
  const _RecentRow({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: student.accent.withValues(alpha: 0.18),
            backgroundImage: student.avatarUrl != null ? NetworkImage(student.avatarUrl!) : null,
            child: student.avatarUrl == null
                ? Text(student.name.characters.first,
                    style: AppTypography.titleMd.copyWith(color: student.accent))
                : null,
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w600)),
                Text('ID: ${student.id}', style: AppTypography.bodySm),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}
