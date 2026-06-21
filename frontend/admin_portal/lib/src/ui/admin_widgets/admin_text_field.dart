import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Labeled, fully-bordered input used on admin forms (Create/Edit School).
///
/// Differs from `shared`'s underline-style [GlassInput]: a persistent label
/// sits above a rounded outlined box. Supports multi-line via [maxLines].
class AdminTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool required;
  final int maxLines;
  final TextInputType keyboardType;
  final bool filled;

  const AdminTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, required: required),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyLg.copyWith(color: AppColors.outline),
            filled: true,
            fillColor: filled
                ? AppColors.surfaceContainerLow
                : AppColors.surfaceContainerLowest,
            isDense: true,
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

  OutlineInputBorder _border(Color color, {double width = 1}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(color: color, width: width),
      );
}

/// Bordered dropdown field with the same label/box styling as [AdminTextField].
class AdminDropdownField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final bool required;

  const AdminDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.value,
    this.hint = 'Select…',
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, required: required),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.onSurfaceVariant),
          hint: Text(hint, style: AppTypography.bodyLg.copyWith(color: AppColors.outline)),
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

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, required this.required});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
        children: [
          if (required)
            const TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
        ],
      ),
    );
  }
}
