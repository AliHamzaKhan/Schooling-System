import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/activity_item.dart';

/// Timeline-based activity feed — a vertical rail with coloured nodes per
/// [ActivityItem], the connecting line drawn between consecutive entries.
class ActivityTimeline extends StatelessWidget {
  final List<ActivityItem> items;
  const ActivityTimeline({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return GlassSurface(
        child: Row(
          children: [
            const Icon(AppIcons.historyToggleOffRounded,
                color: AppColors.outline),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: Text('No recent activity for this child.',
                  style: AppTypography.bodyMd),
            ),
          ],
        ),
      );
    }
    return GlassSurface(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _TimelineRow(item: items[i], isLast: i == items.length - 1),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final ActivityItem item;
  final bool isLast;
  const _TimelineRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.kind.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.kind.icon, size: 16, color: item.kind.color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.stackLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.title,
                            style: AppTypography.titleMd
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                      Text(item.timeAgo,
                          style: AppTypography.labelMd
                              .copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(item.detail, style: AppTypography.bodyMd),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
