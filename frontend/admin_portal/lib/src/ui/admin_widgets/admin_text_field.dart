import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../admin_theme.dart';

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
          style: AdminType.body.copyWith(color: AdminPalette.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AdminType.body.copyWith(color: AdminPalette.faint),
            filled: true,
            fillColor: filled
                ? AdminPalette.tint
                : AdminPalette.card,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.stackMd, vertical: 14),
            enabledBorder: _border(AdminPalette.border),
            focusedBorder: _border(AdminPalette.ink, width: 1.5),
            border: _border(AdminPalette.border),
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
          icon: const Icon(AppIcons.keyboardArrowDownRounded,
              color: AdminPalette.muted),
          hint: Text(hint, style: AdminType.body.copyWith(color: AdminPalette.faint)),
          style: AdminType.body.copyWith(color: AdminPalette.ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: AdminPalette.card,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.stackMd, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: const BorderSide(color: AdminPalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: const BorderSide(color: AdminPalette.ink, width: 1.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: const BorderSide(color: AdminPalette.border),
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
        style: AdminType.label.copyWith(color: AdminPalette.ink),
        children: [
          if (required)
            const TextSpan(text: ' *', style: TextStyle(color: AdminPalette.danger)),
        ],
      ),
    );
  }
}
