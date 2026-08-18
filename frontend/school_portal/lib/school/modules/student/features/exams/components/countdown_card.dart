import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/exam.dart';

/// Navy hero card with a "Next Exam In" pill, big D + HRS countdown, and a
/// glassy inset panel showing the next exam's title, date/time, and location.
class CountdownCard extends StatelessWidget {
  final ExamCountdown next;

  /// Tapping the card opens the exam detail, when wired.
  final VoidCallback? onTap;
  const CountdownCard({super.key, required this.next, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: const [
          BoxShadow(color: Color(0x330F172A), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 14, color: AppColors.onPrimary),
                    const SizedBox(width: 6),
                    Text('Next Exam In',
                        style: AppTypography.labelMd
                            .copyWith(color: AppColors.onPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(next.days.toString().padLeft(2, '0'),
                  style: AppTypography.displayLg
                      .copyWith(fontSize: 56, color: AppColors.onPrimary)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('DAYS',
                    style: AppTypography.labelCaps
                        .copyWith(color: AppColors.onPrimary)),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Text(next.hours.toString().padLeft(2, '0'),
                  style: AppTypography.displayLg
                      .copyWith(fontSize: 56, color: AppColors.onPrimary)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('HRS',
                    style: AppTypography.labelCaps
                        .copyWith(color: AppColors.onPrimary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Container(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(next.title,
                    style: AppTypography.titleLg
                        .copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.stackSm),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppColors.onPrimary),
                    const SizedBox(width: 6),
                    Text('${next.date}  •  ${next.time}',
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.onPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.onPrimary),
                    const SizedBox(width: 6),
                    Text(next.location,
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.onPrimary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
