import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/assignment.dart';

/// Top summary card: weekly progress (x of N) with percent, a navy progress
/// bar, and two stat cells (In Progress / To Do).
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Progress', style: AppTypography.headlineLg.copyWith(fontSize: 22)),
                    const SizedBox(height: 2),
                    Text('${summary.completed} of ${summary.total} tasks completed',
                        style: AppTypography.bodyMd),
                  ],
                ),
              ),
              Text('${summary.percent}%',
                  style: AppTypography.displayLg
                      .copyWith(fontSize: 28, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: summary.percent / 100,
              minHeight: 8,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerHigh,
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              _Stat(value: '${summary.inProgress}', label: 'IN\nPROGRESS', color: const Color(0xFFE8A317)),
              const SizedBox(width: AppSpacing.stackLg),
              _Stat(value: '${summary.toDo}', label: 'TO DO', color: AppColors.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Stat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTypography.displayLg.copyWith(fontSize: 28, color: color)),
        Text(label,
            style: AppTypography.labelCaps.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}
