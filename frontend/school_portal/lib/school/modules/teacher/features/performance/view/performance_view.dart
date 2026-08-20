import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/multi_line_chart.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../components/attendance_week_chart.dart';
import '../components/performance_profile_card.dart';
import '../components/recent_grade_row.dart';
import '../controller/performance_controller.dart';
import '../../../../../widgets/skeletons.dart';

/// Student Performance — profile card, performance trend line chart, weekly
/// attendance bars, and recent grades & feedback. Reused as both the
/// Performance tab content and a drill-in from the Gradebook (Marks Entry).
/// When [showBack] is true, the screen renders the "Back to Gradebook" row.
class StudentPerformanceView extends GetView<TeacherPerformanceController> {
  final bool showBack;
  const StudentPerformanceView({super.key, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (!showBack) const PortalTopBar(title: 'Teacher Portal'),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const SkeletonPage(body: Column(children: [SkeletonCardList(count: 1, height: 150), SizedBox(height: AppSpacing.stackLg), SkeletonCardList(count: 2, height: 180)]));
              }
              final s = controller.student.value;
              if (s == null) {
                return Center(
                    child: Text(
                        controller.error.value ??
                            'Pick a student to view performance.',
                        style: AppTypography.bodyLg));
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  if (showBack) ...[
                    const SizedBox(height: AppSpacing.stackMd),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Student Performance',
                              style: AppTypography.headlineLg
                                  .copyWith(color: AppColors.primary)),
                        ),
                        const Icon(AppIcons.notificationsNoneRounded,
                            color: AppColors.onSurface),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    GestureDetector(
                      onTap: () => Get.back<void>(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(AppIcons.arrowBackRounded,
                              size: 16, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('Back to Gradebook',
                              style: AppTypography.labelMd
                                  .copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                  ] else ...[
                    Text('Student Performance',
                        style: AppTypography.headlineLg
                            .copyWith(color: AppColors.primary)),
                    const SizedBox(height: AppSpacing.stackLg),
                  ],
                  PerformanceProfileCard(student: s),
                  const SizedBox(height: AppSpacing.stackLg),

                  // Performance trend.
                  GlassSurface(
                    padding: const EdgeInsets.all(AppSpacing.stackLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(AppIcons.trendingUpRounded,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text('Performance Trend',
                                style: AppTypography.titleLg),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                        PortalMultiLineChart(
                          xLabels: s.trendLabels,
                          series: [
                            LineSeries(
                                points: s.trendScores,
                                color: AppColors.primary,
                                label: 'Score'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),

                  // Attendance record.
                  GlassSurface(
                    padding: const EdgeInsets.all(AppSpacing.stackLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(AppIcons.eventAvailableOutlined,
                                size: 18, color: Color(0xFFE8A317)),
                            const SizedBox(width: 6),
                            Text('Attendance Record',
                                style: AppTypography.titleLg),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                        AttendanceWeekChart(week: s.week),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),

                  // Recent grades.
                  GlassSurface(
                    padding: const EdgeInsets.all(AppSpacing.stackLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent Grades & Feedback',
                            style: AppTypography.titleLg),
                        const SizedBox(height: AppSpacing.stackMd),
                        for (var i = 0; i < s.recent.length; i++) ...[
                          RecentGradeRow(grade: s.recent[i]),
                          if (i != s.recent.length - 1)
                            const SizedBox(height: AppSpacing.stackSm),
                        ],
                        const SizedBox(height: AppSpacing.stackMd),
                        GhostButton(
                          label: 'View Full History',
                          expanded: true,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
