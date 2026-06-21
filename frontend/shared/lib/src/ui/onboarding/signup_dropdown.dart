import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Outlined dropdown that mirrors [SignupField] visually.
class SignupDropdown extends StatelessWidget {
  final String label;
  final String? hint;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool optional;

  const SignupDropdown({
    super.key,
    required this.label,
    this.hint,
    required this.options,
    required this.value,
    required this.onChanged,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(label,
                  style: AppTypography.labelCaps.copyWith(color: AppColors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              Text('· OPTIONAL',
                  style: AppTypography.labelCaps.copyWith(color: AppColors.outline)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.outlineVariant, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint ?? 'Select',
                  style: AppTypography.bodyLg.copyWith(color: AppColors.outline)),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.onSurfaceVariant),
              style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
              borderRadius: BorderRadius.circular(AppRadius.md),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
