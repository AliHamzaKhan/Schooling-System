import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Horizontal row of single-select pill filters (All / Active / Pending …).
///
/// The selected chip fills navy with light text; the rest are outlined.
class FilterChips extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const FilterChips({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.stackSm),
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.outlineVariant,
                  width: 1,
                ),
              ),
              child: Text(
                options[i],
                style: AppTypography.labelMd.copyWith(
                  color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
