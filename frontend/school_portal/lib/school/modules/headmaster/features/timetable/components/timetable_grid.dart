import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/timetable_data.dart';

/// Two-axis schedule: fixed time column on the left, horizontally-scrollable
/// day columns. Day headers sit in soft navy pills; break rows render as a
/// muted full-width band; lessons show subject / class / teacher in the
/// subject's tint color.
class TimetableGrid extends StatelessWidget {
  final TimetableData data;

  /// Column width per day.
  final double dayColumnWidth;
  final double timeColumnWidth;

  const TimetableGrid({
    super.key,
    required this.data,
    this.dayColumnWidth = 130,
    this.timeColumnWidth = 84,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header row.
            Row(
              children: [
                SizedBox(width: timeColumnWidth),
                for (final d in data.days)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: Container(
                      width: dayColumnWidth - 12,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(d,
                          style: AppTypography.titleMd.copyWith(
                              color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            for (final slot in data.slots) _SlotRow(
              slot: slot,
              days: data.days,
              dayColumnWidth: dayColumnWidth,
              timeColumnWidth: timeColumnWidth,
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final TimeSlot slot;
  final List<String> days;
  final double dayColumnWidth;
  final double timeColumnWidth;

  const _SlotRow({
    required this.slot,
    required this.days,
    required this.dayColumnWidth,
    required this.timeColumnWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (slot.isBreak) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          children: [
            SizedBox(
              width: timeColumnWidth,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(slot.label,
                    style: AppTypography.labelMd
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ),
            ),
            const Spacer(),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: timeColumnWidth,
          child: Padding(
            padding: const EdgeInsets.only(top: 14, left: 12),
            child: Text(slot.label, style: AppTypography.bodyMd),
          ),
        ),
        for (final day in days)
          SizedBox(
            width: dayColumnWidth,
            child: _LessonCell(lesson: slot.lessons[day]),
          ),
      ],
    );
  }
}

class _LessonCell extends StatelessWidget {
  final Lesson? lesson;
  const _LessonCell({this.lesson});

  @override
  Widget build(BuildContext context) {
    if (lesson == null) {
      return const SizedBox(height: 72);
    }
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lesson!.subject,
              style: AppTypography.titleMd.copyWith(
                  color: lesson!.color, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
          Row(
            children: [
              Text(lesson!.classLabel,
                  style: AppTypography.bodyMd.copyWith(color: lesson!.color)),
              const SizedBox(width: 4),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: lesson!.color, shape: BoxShape.circle),
              ),
            ],
          ),
          Text(lesson!.teacher,
              style: AppTypography.bodyMd.copyWith(color: lesson!.color),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
