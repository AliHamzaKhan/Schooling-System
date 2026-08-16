import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../admin_theme.dart';

/// Horizontal row of single-select pill filters (All / Active / Pending …).
///
/// The selected chip fills navy with white text; the rest are white with a
/// hairline border.
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
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: selected ? AdminPalette.ink : AdminPalette.card,
                borderRadius: BorderRadius.circular(AdminRadius.chip),
                border: Border.all(
                  color: selected ? AdminPalette.ink : AdminPalette.border,
                ),
                boxShadow: selected ? null : AdminPalette.cardShadow,
              ),
              child: Text(
                options[i],
                style: AdminType.label.copyWith(
                  color: selected ? Colors.white : AdminPalette.muted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
