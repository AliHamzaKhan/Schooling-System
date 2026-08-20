import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../../../shared/widgets/child_switcher.dart';
import '../controller/timetable_controller.dart';
import '../models/timetable_data.dart';
import '../../../../../widgets/skeletons.dart';

/// Timetable — drill-in screen showing the active child's weekly schedule: a
/// horizontal day selector and the selected day's periods as a timeline of
/// class cards (with the in-session period highlighted).
class TimetableView extends GetView<GuardianTimetableController> {
  const TimetableView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          const PortalTopBar(title: 'My Schedule', showAvatar: false),
          const ChildSwitcher(),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const SkeletonPage(body: SkeletonCardList(count: 6, height: 72));
              }
              final d = controller.data.value;
              if (d == null || d.days.isEmpty) {
                return const SizedBox.shrink();
              }
              final dayIndex =
                  controller.selectedDay.value.clamp(0, d.days.length - 1);
              final day = d.days[dayIndex];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.containerPaddingMobile),
                    child: Text(d.weekLabel, style: AppTypography.bodyMd),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  _DaySelector(
                    days: d.days,
                    selected: dayIndex,
                    onSelect: controller.selectDay,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  Expanded(
                    child: day.entries.isEmpty
                        ? const _Empty(text: 'No classes scheduled.')
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.containerPaddingMobile,
                                0,
                                AppSpacing.containerPaddingMobile,
                                AppSpacing.stackXl),
                            itemCount: day.entries.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.stackSm),
                            itemBuilder: (_, i) =>
                                _EntryCard(entry: day.entries[i]),
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

class _DaySelector extends StatelessWidget {
  final List<TimetableDay> days;
  final int selected;
  final ValueChanged<int> onSelect;
  const _DaySelector(
      {required this.days, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerPaddingMobile),
        itemCount: days.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.stackSm),
        itemBuilder: (_, i) {
          final d = days[i];
          final active = i == selected;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              width: 58,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(
                    color:
                        active ? AppColors.primary : AppColors.outlineVariant),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(d.weekday,
                      style: AppTypography.labelMd.copyWith(
                          color: active
                              ? Colors.white
                              : AppColors.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(d.dayNum,
                      style: AppTypography.titleLg.copyWith(
                          color:
                              active ? Colors.white : AppColors.onSurface)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final TimetableEntry entry;
  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry.isBreak) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
              color: AppColors.outlineVariant,
              style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.restaurantRounded,
                size: 16, color: AppColors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.stackSm),
            Text(entry.subject, style: AppTypography.labelMd),
          ],
        ),
      );
    }

    final highlighted = entry.isNow;
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(entry.subject,
                    style: AppTypography.titleLg.copyWith(
                        color: highlighted ? AppColors.primary : null)),
              ),
              if (highlighted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text('NOW',
                      style: AppTypography.labelMd.copyWith(fontSize: 11, fontWeight: FontWeight.w700)
                          .copyWith(color: AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(AppIcons.scheduleRounded,
                  size: 15, color: AppColors.primary),
              const SizedBox(width: 4),
              Text('${entry.startTime} - ${entry.endTime}',
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.primary)),
            ],
          ),
          if (entry.note != null) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Text(entry.note!, style: AppTypography.bodyMd),
          ],
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              if (entry.teacher != null)
                _Meta(icon: AppIcons.personOutline, text: entry.teacher!),
              if (entry.teacher != null && entry.room != null)
                const SizedBox(width: AppSpacing.stackMd),
              if (entry.room != null)
                _Meta(icon: AppIcons.meetingRoomOutlined, text: entry.room!),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: AppTypography.bodyMd),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.containerPaddingMobile),
        child: Text(text, style: AppTypography.bodyMd),
      ),
    );
  }
}
