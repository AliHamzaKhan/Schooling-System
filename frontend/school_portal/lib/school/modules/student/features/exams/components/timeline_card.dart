import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/exam.dart';

/// One row in the Upcoming Timeline: small accent dot on a vertical line, then
/// a glass card with date short, title, time pill, divider, and location row.
class TimelineCard extends StatelessWidget {
  final UpcomingExam exam;
  final bool isLast;
  const TimelineCard({super.key, required this.exam, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: exam.accent, shape: BoxShape.circle)),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : AppColors.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
              child: GlassSurface(
                padding: EdgeInsets.zero,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 5,
                        decoration: BoxDecoration(
                          color: exam.accent,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(AppRadius.card),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.stackMd),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(exam.dateShort,
                                      style: AppTypography.labelCaps
                                          .copyWith(color: exam.accent, fontWeight: FontWeight.w800)),
                                  const Spacer(),
                                  _TimePill(time: exam.time),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(exam.title,
                                  style: AppTypography.headlineLg
                                      .copyWith(fontSize: 22)),
                              const SizedBox(height: AppSpacing.stackMd),
                              const Divider(height: 1, color: AppColors.outlineVariant),
                              const SizedBox(height: AppSpacing.stackSm),
                              Row(
                                children: [
                                  const Icon(Icons.meeting_room_outlined,
                                      size: 14, color: AppColors.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(exam.location,
                                      style: AppTypography.bodyMd),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  final String time;
  const _TimePill({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded,
              size: 12, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(time,
              style: AppTypography.bodySm.copyWith(color: AppColors.onSurface)),
        ],
      ),
    );
  }
}
