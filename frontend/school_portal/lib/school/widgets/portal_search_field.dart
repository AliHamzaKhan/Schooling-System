import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Rounded search pill used at the top of list screens.
///
/// The search icon lives *inside* the input as a [InputDecoration.prefixIcon]
/// (with an optional [suffixIcon]) so the field reads as one control, and the
/// fill defaults to the surrounding container colour rather than pure white.
class PortalSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  /// Fill colour — defaults to the page container so the field blends with the
  /// surface it sits on. Pass [Colors.transparent] inside a [GlassSurface].
  final Color? fillColor;

  /// Optional trailing affordance rendered inside the field (e.g. a clear
  /// button).
  final Widget? suffixIcon;

  const PortalSearchField({
    super.key,
    this.hint = 'Search…',
    this.onChanged,
    this.controller,
    this.fillColor,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
      borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyLg.copyWith(color: AppColors.outline),
        filled: true,
        fillColor: fillColor ?? AppColors.surfaceContainerLow,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon:
            const Icon(Icons.search_rounded, size: 20, color: AppColors.outline),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 44),
        suffixIcon: suffixIcon,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
