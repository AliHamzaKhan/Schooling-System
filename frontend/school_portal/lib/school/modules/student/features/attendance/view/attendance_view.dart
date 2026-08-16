import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../components/monthly_average_card.dart';
import '../controller/attendance_controller.dart';
import '../models/attendance_data.dart';
import '../../../../../widgets/skeletons.dart';

/// My Attendance — used as the Profile tab content. Monthly average card,
/// Recent Absences (empty-state with smiley), Late Arrivals list.
class AttendanceView extends GetView<StudentAttendanceController> {
  final VoidCallback? onNotifications;
  const AttendanceView({super.key, this.onNotifications});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PortalTopBar(title: 'Meri Taleem', onBell: onNotifications),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const SkeletonPage(body: Column(children: [SkeletonStatGrid(count: 2), SizedBox(height: AppSpacing.stackLg), SkeletonCardList(count: 4, height: 76)]));
            }
            final data = controller.data.value;
            if (data == null) return const SizedBox.shrink();
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  0,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl),
              children: [
                Text('My Attendance', style: AppTypography.headlineLg),
                const SizedBox(height: AppSpacing.stackSm),
                Text('Track your presence and punctuality.',
                    style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackLg),
                MonthlyAverageCard(
                  percent: data.monthlyAverage,
                  delta: data.deltaPercent,
                  week: data.week,
                ),
                const SizedBox(height: AppSpacing.stackLg),
                _RecentAbsencesCard(absences: data.recentAbsences),
                const SizedBox(height: AppSpacing.stackLg),
                _LateArrivalsCard(marks: data.lateMarks),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _RecentAbsencesCard extends StatelessWidget {
  final List<String> absences;
  const _RecentAbsencesCard({required this.absences});

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
              decoration: const BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text('Recent Absences',
                                style: AppTypography.headlineLg.copyWith(fontSize: 22))),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.event_busy_outlined,
                              color: AppColors.error, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    if (absences.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.sentiment_satisfied_alt_outlined,
                                  size: 26, color: Color(0xFF064E3B)),
                            ),
                            const SizedBox(height: AppSpacing.stackSm),
                            Text('Perfect Streak!',
                                style: AppTypography.titleMd
                                    .copyWith(fontWeight: FontWeight.w800)),
                            Text('No absences recorded recently.',
                                style: AppTypography.bodyLg),
                          ],
                        ),
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

class _LateArrivalsCard extends StatelessWidget {
  final List<LateMark> marks;
  const _LateArrivalsCard({required this.marks});

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
              decoration: const BoxDecoration(
                color: Color(0xFFE8A317),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text('Late Arrivals',
                                style: AppTypography.headlineLg.copyWith(fontSize: 22))),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8A317).withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.schedule_rounded,
                              color: Color(0xFFE8A317), size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    for (final m in marks) ...[
                      _MarkRow(mark: m),
                      const SizedBox(height: AppSpacing.stackSm),
                    ],
                    _EmptyMarksRow(),
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

class _MarkRow extends StatelessWidget {
  final LateMark mark;
  const _MarkRow({required this.mark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mark.date,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(mark.period, style: AppTypography.bodyMd),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8A317).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text('${mark.minutes} mins',
                style: AppTypography.labelMd.copyWith(
                    color: const Color(0xFFE8A317), fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _EmptyMarksRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
            color: AppColors.outlineVariant, width: 1, style: BorderStyle.solid),
      ),
      alignment: Alignment.center,
      child: Text('No other late marks', style: AppTypography.bodyMd),
    );
  }
}
