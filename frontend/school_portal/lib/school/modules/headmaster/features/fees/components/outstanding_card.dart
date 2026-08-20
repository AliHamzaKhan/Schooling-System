import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/fees_data.dart';

/// "Outstanding" card: amber warning header, big red amount, student-count
/// caption, and a "Remind All" ghost-style action.
class OutstandingCard extends StatelessWidget {
  final FeesData data;
  final VoidCallback? onRemindAll;
  const OutstandingCard({super.key, required this.data, this.onRemindAll});

  static const _amber = Color(0xFFE8A317);

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
              decoration: const BoxDecoration(
                color: _amber,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(AppIcons.warningAmberRounded, color: _amber, size: 18),
                        SizedBox(width: 6),
                        Text('Outstanding',
                            style: TextStyle(
                                fontFamily: 'packages/shared/Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    Text(data.outstandingAmount,
                        style: AppTypography.displayLg
                            .copyWith(color: AppColors.error, fontSize: 40)),
                    const SizedBox(height: 4),
                    Text('from ${data.outstandingCount} students',
                        style: AppTypography.bodyLg),
                    const SizedBox(height: AppSpacing.stackLg),
                    GhostButton(
                      label: 'Remind All',
                      leadingIcon: AppIcons.mailOutlineRounded,
                      expanded: true,
                      onPressed: onRemindAll,
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
