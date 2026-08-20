import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Labeled, fully-bordered input used across teacher forms (Create Homework,
/// Create Exam). Supports multi-line via [maxLines] and a passive [filled]
/// look for read-only-feeling fields.
class PortalFormField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final int maxLines;
  final TextInputType keyboardType;
  final bool filled;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  const PortalFormField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.filled = false,
    this.suffix,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyLg.copyWith(color: AppColors.outline),
            filled: true,
            fillColor: filled
                ? AppColors.surfaceContainerHigh
                : AppColors.surfaceContainerLowest,
            isDense: true,
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.stackMd, vertical: 14),
            enabledBorder: _border(AppColors.outlineVariant),
            focusedBorder: _border(AppColors.primary, width: 1.5),
            border: _border(AppColors.outlineVariant),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(color: color, width: width),
      );
}

/// Bordered dropdown with the same shell as [PortalFormField].
class PortalDropdownField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  const PortalDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.value,
    this.hint = 'Select…',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(AppIcons.keyboardArrowDownRounded,
              color: AppColors.onSurfaceVariant),
          hint: Text(hint,
              style: AppTypography.bodyLg.copyWith(color: AppColors.outline)),
          style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.stackMd, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
          ),
          items: [
            for (final it in items)
              DropdownMenuItem<T>(value: it, child: Text(labelOf(it))),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
