import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../admin_theme.dart';

/// Wrapping group of single-select pills (e.g. Public / Private / Charter /
/// Other). Two per row on narrow widths. Selected pill is tinted with [accent].
class SegmentedPills extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final Color accent;

  const SegmentedPills({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.accent = AdminPalette.info,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final width = (c.maxWidth - AppSpacing.stackMd) / 2;
      return Wrap(
        spacing: AppSpacing.stackMd,
        runSpacing: AppSpacing.stackMd,
        children: [
          for (final o in options)
            SizedBox(
              width: width,
              child: _Pill(
                label: o,
                selected: o == selected,
                accent: accent,
                onTap: () => onSelected(o),
              ),
            ),
        ],
      );
    });
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.18) : AdminPalette.card,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: selected ? accent : AdminPalette.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AdminType.rowTitle.copyWith(
            color: selected ? accent : AdminPalette.ink,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
