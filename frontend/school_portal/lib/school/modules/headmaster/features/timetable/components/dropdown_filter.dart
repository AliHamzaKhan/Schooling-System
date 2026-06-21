import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Inline dropdown filter that looks like a navy text link with an icon and a
/// trailing chevron. Tapping opens a [PopupMenuButton] of options.
class DropdownFilter extends StatelessWidget {
  final IconData icon;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const DropdownFilter({
    super.key,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final o in options)
          PopupMenuItem<String>(value: o, child: Text(o)),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(value,
              style: AppTypography.titleMd
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          const Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: AppColors.primary),
        ],
      ),
    );
  }
}
