import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/exam.dart';

/// One row in the Upcoming Timeline: a day/month date circle on a vertical
/// connector, then a clean card with the exam title, date, time, and location.
class TimelineCard extends StatelessWidget {
  final UpcomingExam exam;
  final bool isLast;
  final VoidCallback? onTap;
  const TimelineCard(
      {super.key, required this.exam, this.isLast = false, this.onTap});

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', //
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(exam.date.isNotEmpty ? exam.date : exam.dateShort);
    final day = d?.day.toString() ?? '--';
    final month = d != null ? _months[d.month - 1] : '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(color: exam.accent.withValues(alpha: 0.4), width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(day,
                        style: AppTypography.titleLg.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            height: 1.0)),
                    Text(month,
                        style: AppTypography.labelCaps.copyWith(
                            fontSize: 10,
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.outlineVariant),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
              child: GlassSurface(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(exam.title,
                              style: AppTypography.headlineLg
                                  .copyWith(fontSize: 20)),
                        ),
                        const Icon(AppIcons.chevronRightRounded,
                            size: 20, color: AppColors.onSurfaceVariant),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    _MetaRow(
                      icon: AppIcons.calendarTodayOutlined,
                      text: exam.dateShort.isEmpty ? exam.date : exam.dateShort,
                    ),
                    if (exam.time.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _MetaRow(
                          icon: AppIcons.accessTimeRounded, text: exam.time),
                    ],
                    if (exam.location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _MetaRow(
                          icon: AppIcons.meetingRoomOutlined,
                          text: exam.location),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ),
      ],
    );
  }
}
