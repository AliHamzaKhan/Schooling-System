import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/performance_data.dart';

/// One Recent Grade & Feedback row: subject icon, title + date + quote, big
/// letter grade on the right colored by the subject's tint.
class RecentGradeRow extends StatelessWidget {
  final GradeFeedback grade;
  const RecentGradeRow({super.key, required this.grade});

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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: grade.iconColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(grade.icon, color: grade.iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(grade.title,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${grade.dateLine} • ${grade.quote}',
                    style: AppTypography.bodyMd),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Text(grade.grade,
              style: AppTypography.displayLg
                  .copyWith(fontSize: 24, color: grade.iconColor)),
        ],
      ),
    );
  }
}
