import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Row with a section title on the left and an optional trailing action
/// (e.g. "View All") on the right.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title, style: AppTypography.titleLg),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: AppTypography.labelMd.copyWith(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}
