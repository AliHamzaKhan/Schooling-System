import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Row with a section title on the left and an optional trailing link
/// ("View All", "Filter") on the right.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: AppTypography.titleLg),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (actionIcon != null) ...[
                  Icon(actionIcon, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                ],
                Text(
                  actionLabel!,
                  style: AppTypography.labelMd.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
