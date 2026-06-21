import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/attendance_data.dart';

/// Grade Level Breakdown row: numbered circle, name, percent, then a colored
/// progress bar underneath.
class GradeBreakdownRow extends StatelessWidget {
  final GradeAttendance grade;
  const GradeBreakdownRow({super.key, required this.grade});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: grade.color.withValues(alpha: 0.18),
              child: Text('${grade.grade}',
                  style: AppTypography.labelMd
                      .copyWith(color: grade.color, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(child: Text(grade.name, style: AppTypography.bodyLg)),
            Text('${grade.percent}%',
                style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: grade.percent / 100,
            minHeight: 5,
            color: grade.color,
            backgroundColor: AppColors.surfaceContainerHigh,
          ),
        ),
      ],
    );
  }
}
