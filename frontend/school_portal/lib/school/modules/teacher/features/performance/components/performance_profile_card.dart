import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/performance_data.dart';

/// Top profile card on Student Performance — avatar, grade/subject chips, name
/// + ID, Message Student / View Portfolio actions, then a divider and two
/// stats (Current GPA, Attendance).
class PerformanceProfileCard extends StatelessWidget {
  final StudentDetail student;

  const PerformanceProfileCard({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.surfaceContainerHigh,
            backgroundImage: student.avatarUrl != null
                ? schoolImage(student.avatarUrl!)
                : null,
            child: student.avatarUrl == null
                ? Text(student.name.characters.first,
                    style: AppTypography.displayLg.copyWith(fontSize: 28))
                : null,
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Chip(label: student.grade, color: AppColors.primary),
              const SizedBox(width: AppSpacing.stackSm),
              _Chip(label: student.subject, color: AppColors.tertiary),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text('Student ID: #${student.id}', style: AppTypography.bodyMd),
          const SizedBox(height: AppSpacing.stackLg),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              Expanded(child: Text('Attendance', style: AppTypography.bodyLg)),
              Text(student.attendancePercent,
                  style: AppTypography.displayLg
                      .copyWith(fontSize: 28, color: const Color(0xFFE8A317))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
      ],
    );
  }
}
