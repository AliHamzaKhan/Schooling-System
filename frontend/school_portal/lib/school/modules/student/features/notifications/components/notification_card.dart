import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/notification_item.dart';

/// One row in the Notifications Center: colored icon badge, title (with time
/// stamp on the right colored blue for unread items), and a body excerpt.
/// Unread items sit in a soft tint with a small dot; there is no side rail.
class NotificationCard extends StatelessWidget {
  final NotificationItem item;
  const NotificationCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      fill: item.unread ? item.kind.color.withValues(alpha: 0.06) : null,
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
                    if (item.unread) ...[
                      Container(
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: item.kind.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Expanded(
                      child: Text(item.title,
                          style: AppTypography.titleMd.copyWith(
                              fontWeight: item.unread
                                  ? FontWeight.w800
                                  : FontWeight.w700)),
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
    );
  }
}
