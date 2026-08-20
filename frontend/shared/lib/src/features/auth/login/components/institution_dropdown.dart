import 'package:flutter/material.dart';

import '../../../../ui/tokens/app_colors.dart';
import '../../../../ui/tokens/app_radius.dart';
import '../../../../ui/tokens/app_typography.dart';
import '../../models/institution.dart';
import 'package:shared/shared.dart';

/// Pill-style institution picker matching the login mockup
/// ("Select your institution" + chevron).
class InstitutionDropdown extends StatelessWidget {
  final List<Institution> items;
  final Institution? value;
  final ValueChanged<Institution?> onChanged;
  final bool loading;

  const InstitutionDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Institution / School',
            style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Institution>(
              isExpanded: true,
              value: value,
              borderRadius: BorderRadius.circular(AppRadius.defaultR),
              icon: loading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(AppIcons.keyboardArrowDown, color: AppColors.onSurfaceVariant),
              hint: Text('Select your institution',
                  style: AppTypography.bodyLg.copyWith(color: AppColors.outline)),
              style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
              padding: const EdgeInsets.symmetric(vertical: 14),
              items: [
                for (final i in items)
                  DropdownMenuItem(value: i, child: Text(i.name)),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
