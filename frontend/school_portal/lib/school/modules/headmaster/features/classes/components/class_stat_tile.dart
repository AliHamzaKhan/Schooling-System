import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/classes_data.dart';

/// Compact 2-up KPI tile for the Class Directory header (Total Students,
/// Active Classes, …). White card, navy label, big value, decorative icon.
class ClassStatTile extends StatelessWidget {
  final ClassStat stat;
  const ClassStatTile({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stat.label,
              style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(stat.value,
                    style: AppTypography.displayLg
                        .copyWith(fontSize: 28, color: AppColors.primary)),
              ),
              Icon(stat.icon, color: stat.color.withValues(alpha: 0.55), size: 22),
            ],
          ),
        ],
      ),
    );
  }
}
