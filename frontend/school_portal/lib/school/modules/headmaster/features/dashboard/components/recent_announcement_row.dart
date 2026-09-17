import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/dashboard_data.dart';

/// One announcement preview on the dashboard: a clean card with title, time
/// stamp, and a clipped body excerpt.
class RecentAnnouncementRow extends StatelessWidget {
  final RecentAnnouncementSummary item;
  final VoidCallback? onTap;
  const RecentAnnouncementRow({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
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
                Expanded(
                  child: Text(item.title,
                      style: AppTypography.titleMd
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Text(item.timeAgo, style: AppTypography.bodySm),
              ],
            ),
            const SizedBox(height: 4),
            Text(item.preview, style: AppTypography.bodyMd),
          ],
        ),
      ),
    );
  }
}
