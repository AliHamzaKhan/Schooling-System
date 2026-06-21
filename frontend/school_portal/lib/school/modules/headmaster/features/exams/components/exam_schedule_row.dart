import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/exams_data.dart';

/// One row in the Exam Schedule list: round icon + title + schedule line, a
/// muted "Live" status pill underneath for in-progress exams, and the room
/// label on the bottom-left.
class ExamScheduleRow extends StatelessWidget {
  final ExamScheduleItem item;
  const ExamScheduleRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.subject,
                        style: AppTypography.titleMd
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${item.grade} • ${item.schedule}',
                        style: AppTypography.bodySm),
                  ],
                ),
              ),
            ],
          ),
          if (item.status == ExamStatus.live) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: AppColors.error, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('Live',
                      style: AppTypography.labelMd.copyWith(
                          color: AppColors.error, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
          if (item.location.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Text(item.location, style: AppTypography.bodySm),
          ],
        ],
      ),
    );
  }
}
