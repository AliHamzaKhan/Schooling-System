import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/exam.dart';

/// Navy hero card for the next exam: a "NEXT EXAM" pill, the exam title and
/// date, then a DAYS : HRS : MINS countdown.
class CountdownCard extends StatelessWidget {
  final ExamCountdown next;

  /// Tapping the card opens the exam detail, when wired.
  final VoidCallback? onTap;
  const CountdownCard({super.key, required this.next, this.onTap});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get _prettyDate {
    final d = DateTime.tryParse(next.date);
    if (d == null) return next.date;
    return '${_months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.defaultR),
          boxShadow: const [
            BoxShadow(
                color: Color(0x330F172A), blurRadius: 24, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.defaultR),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(AppIcons.timerOutlined,
                      size: 14, color: AppColors.onPrimary),
                  const SizedBox(width: 6),
                  Text('NEXT EXAM',
                      style: AppTypography.labelCaps.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Text(next.title.isEmpty ? 'Upcoming Exam' : next.title,
                style: AppTypography.displayLg
                    .copyWith(fontSize: 26, color: AppColors.onPrimary)),
            if (next.date.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_prettyDate,
                  style: AppTypography.bodyLg.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.85))),
            ],
            const SizedBox(height: AppSpacing.stackLg),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.stackSm, vertical: AppSpacing.stackMd),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.defaultR),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TimeBlock(value: next.days, label: 'DAYS'),
                  const _Sep(),
                  _TimeBlock(value: next.hours, label: 'HRS'),
                  const _Sep(),
                  _TimeBlock(value: next.minutes, label: 'MINS'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  final int value;
  final String label;
  const _TimeBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value.toString().padLeft(2, '0'),
            style: AppTypography.displayLg
                .copyWith(fontSize: 40, color: AppColors.onPrimary)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTypography.labelCaps.copyWith(
                color: AppColors.onPrimary.withValues(alpha: 0.75),
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(':',
          style: AppTypography.displayLg.copyWith(
              fontSize: 34,
              color: AppColors.onPrimary.withValues(alpha: 0.5))),
    );
  }
}
