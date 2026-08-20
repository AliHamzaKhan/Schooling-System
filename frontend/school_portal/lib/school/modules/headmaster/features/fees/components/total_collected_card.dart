import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/fees_data.dart';

/// Top "Total Collected" card: term pill, big collected number, trend hint,
/// progress-to-target row and a filled progress bar.
class TotalCollectedCard extends StatelessWidget {
  final FeesData data;
  const TotalCollectedCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.accountBalanceOutlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Total Collected',
                  style: AppTypography.titleMd
                      .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.outlineVariant, width: 1),
                ),
                child: Text(data.term, style: AppTypography.labelMd),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text(data.totalCollected,
              style: AppTypography.displayLg
                  .copyWith(color: AppColors.primary, fontSize: 44)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(AppIcons.trendingUpRounded, size: 14, color: AppColors.tertiary),
              const SizedBox(width: 4),
              Text('+${data.trendPercent.toStringAsFixed(0)}% vs last term',
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.tertiary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress to Target', style: AppTypography.bodyMd),
              Text(data.targetLabel,
                  style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: data.progressPercent,
              minHeight: 8,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerHigh,
            ),
          ),
        ],
      ),
    );
  }
}
