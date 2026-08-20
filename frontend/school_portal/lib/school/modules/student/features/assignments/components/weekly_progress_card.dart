import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/assignment.dart';

const _inProgress = Color(0xFFE8A317);
const _completed = Color(0xFF059669);

/// Top summary card: a prominent progress ring beside the weekly headline, a
/// full-width progress bar, then a row of Completed / In Progress / To Do stat
/// chips — the counts repositioned into their own row for clearer visibility.
class WeeklyProgressCard extends StatelessWidget {
  final AssignmentsSummary summary;
  const WeeklyProgressCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Progress',
                        style: AppTypography.headlineLg.copyWith(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text('${summary.completed} of ${summary.total} tasks completed',
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              _ProgressRing(percent: summary.percent),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: summary.percent / 100,
              minHeight: 10,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerHigh,
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Row(
            children: [
              _StatChip(
                  value: summary.completed,
                  label: 'Completed',
                  color: _completed),
              const SizedBox(width: AppSpacing.stackSm),
              _StatChip(
                  value: summary.inProgress,
                  label: 'In Progress',
                  color: _inProgress),
              const SizedBox(width: AppSpacing.stackSm),
              _StatChip(
                  value: summary.toDo,
                  label: 'To Do',
                  color: AppColors.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final int percent;
  const _ProgressRing({required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: CircularProgressIndicator(
              value: percent / 100,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerHigh,
            ),
          ),
          Text('$percent%',
              style: AppTypography.titleMd.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _StatChip({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.stackSm, vertical: AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          children: [
            Text('$value',
                style: AppTypography.displayLg.copyWith(fontSize: 24, color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: AppTypography.labelMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
