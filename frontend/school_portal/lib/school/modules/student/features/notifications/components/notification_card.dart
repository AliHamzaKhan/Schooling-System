import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/notification_item.dart';

/// One row in the Notifications Center: colored icon badge, title (with time
/// stamp on the right colored blue for unread items), and a body excerpt.
/// Status-colored left rail.
class NotificationCard extends StatelessWidget {
  final NotificationItem item;
  const NotificationCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: item.kind.color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.kind.color.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.kind.icon, color: item.kind.color, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.stackMd),
                    Expanded(
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
                              Text(item.timeAgo,
                                  style: AppTypography.bodySm.copyWith(
                                    color: item.unread
                                        ? AppColors.primary
                                        : AppColors.onSurfaceVariant,
                                    fontWeight: item.unread
                                        ? FontWeight.w800
                                        : FontWeight.w400,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(item.body, style: AppTypography.bodyLg),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
