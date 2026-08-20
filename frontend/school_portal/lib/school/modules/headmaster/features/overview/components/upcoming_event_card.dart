import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/overview_data.dart';

/// Horizontal carousel card for an upcoming event. Tinted hero panel up top
/// with a date chip in the corner; meta rows beneath.
class UpcomingEventCard extends StatelessWidget {
  final UpcomingEvent event;
  final VoidCallback? onTap;

  const UpcomingEventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.outlineVariant, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: event.tint.withValues(alpha: 0.18),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.card)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(event.icon, color: event.tint, size: 48),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Column(
                      children: [
                        Text(event.month,
                            style: AppTypography.labelCaps
                                .copyWith(color: AppColors.error)),
                        Text(event.day,
                            style: AppTypography.titleLg
                                .copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.stackMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: AppTypography.titleMd
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(AppIcons.accessTimeRounded,
                          size: 13, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('${event.time} · ${event.location}',
                            style: AppTypography.bodySm,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
