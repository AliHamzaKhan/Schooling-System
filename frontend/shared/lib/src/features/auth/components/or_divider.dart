import 'package:flutter/material.dart';

import '../../../ui/tokens/app_colors.dart';
import '../../../ui/tokens/app_typography.dart';

/// Horizontal rule with a centered "OR" label.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR',
              style: AppTypography.labelCaps.copyWith(color: AppColors.outline)),
        ),
        const Expanded(child: Divider(color: AppColors.outlineVariant)),
      ],
    );
  }
}
