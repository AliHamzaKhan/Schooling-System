import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../controller/timetable_controller.dart';
import '../models/timetable_data.dart';
import '../../../../../widgets/skeletons.dart';

/// Student Timetable — a weekday selector and that day's periods.
class TimetableView extends GetView<StudentTimetableController> {
  const TimetableView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('My Timetable')),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonCardList(count: 6, height: 72));
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        if (controller.days.isEmpty) {
          return Center(
              child: Text('No timetable published for your class yet.',
                  style: AppTypography.bodyLg));
        }
        final day = controller.selectedDay;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.stackMd),
            // Weekday selector.
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.containerPaddingMobile),
                itemCount: controller.days.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.stackSm),
                itemBuilder: (context, i) {
                  final d = controller.days[i];
                  final selected = i == controller.selectedIndex.value;
                  return _DayChip(
                    label: d.label,
                    isToday: d.isToday,
                    selected: selected,
                    onTap: () => controller.selectDay(i),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Expanded(
              child: (day == null || day.periods.isEmpty)
                  ? Center(
                      child: Text('No classes on this day.',
                          style: AppTypography.bodyLg))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.containerPaddingMobile,
                          0,
                          AppSpacing.containerPaddingMobile,
                          AppSpacing.stackXl),
                      itemCount: day.periods.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.stackSm),
                      itemBuilder: (context, i) =>
                          _PeriodTile(period: day.periods[i]),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool isToday;
  final bool selected;
  final VoidCallback onTap;
  const _DayChip({
    required this.label,
    required this.isToday,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibleTap(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.defaultR),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isToday ? AppColors.primary : AppColors.outlineVariant),
            width: 1,
          ),
        ),
        child: Text(
          isToday ? '$label •' : label,
          style: AppTypography.labelMd.copyWith(
            color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PeriodTile extends StatelessWidget {
  final TimetablePeriod period;
  const _PeriodTile({required this.period});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(period.start,
                  style: AppTypography.titleMd
                      .copyWith(fontWeight: FontWeight.w800)),
              Text(period.end,
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Container(width: 3, height: 40, color: AppColors.primary),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(period.subject,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  [
                    if ((period.teacher ?? '').isNotEmpty) period.teacher,
                    if ((period.room ?? '').isNotEmpty) period.room,
                  ].whereType<String>().join('  •  '),
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
