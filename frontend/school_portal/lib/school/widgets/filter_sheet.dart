import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

/// One group of chip options shown inside [showFilterSheet].
class FilterSection {
  final String key;
  final String title;
  final List<String> options;

  /// When false only one option can be selected at a time within the section.
  final bool multiSelect;

  /// Values selected when the sheet opens.
  final Set<String> initial;

  const FilterSection({
    required this.key,
    required this.title,
    required this.options,
    this.multiSelect = true,
    this.initial = const {},
  });
}

/// A modal bottom-sheet of chip filters shared across the portal rosters.
///
/// Returns a map of `section.key -> selected values` when the user taps Apply
/// (Reset returns empty sets for every section), or `null` when the sheet is
/// dismissed without applying. Selection state lives in the sheet, so callers
/// only read the result and update their own filter state.
Future<Map<String, Set<String>>?> showFilterSheet({
  required String title,
  required List<FilterSection> sections,
}) {
  return Get.bottomSheet<Map<String, Set<String>>>(
    _FilterSheet(title: title, sections: sections),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _FilterSheet extends StatefulWidget {
  final String title;
  final List<FilterSection> sections;
  const _FilterSheet({required this.title, required this.sections});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Map<String, Set<String>> _selected = {
    for (final s in widget.sections) s.key: {...s.initial},
  };

  void _toggle(FilterSection section, String option) {
    final set = _selected[section.key]!;
    setState(() {
      if (section.multiSelect) {
        set.contains(option) ? set.remove(option) : set.add(option);
      } else if (set.contains(option)) {
        set.clear();
      } else {
        set
          ..clear()
          ..add(option);
      }
    });
  }

  void _reset() => Get.back<Map<String, Set<String>>>(
        result: {for (final s in widget.sections) s.key: <String>{}},
      );

  void _apply() => Get.back<Map<String, Set<String>>>(result: _selected);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackLg,
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackLg + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(widget.title,
                      style: AppTypography.displayLg.copyWith(fontSize: 24)),
                ),
                TextButton(
                  onPressed: _reset,
                  child: Text('Reset',
                      style: AppTypography.labelMd
                          .copyWith(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackSm),
            for (final section in widget.sections) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(section.title.toUpperCase(),
                    style: AppTypography.labelCaps
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Wrap(
                spacing: AppSpacing.stackSm,
                runSpacing: AppSpacing.stackSm,
                children: [
                  for (final option in section.options)
                    _FilterChip(
                      label: option,
                      selected: _selected[section.key]!.contains(option),
                      onTap: () => _toggle(section, option),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackLg),
            ],
            PrimaryButton(label: 'Apply Filters', onPressed: _apply),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(label,
            style: AppTypography.labelMd.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            )),
      ),
    );
  }
}
