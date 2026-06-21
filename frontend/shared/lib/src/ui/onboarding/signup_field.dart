import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared/shared.dart';

/// Outlined rounded-rect input used across all 5 onboarding steps.
class SignupField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool optional;
  final int minLines;
  final int maxLines;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool obscureText;

  const SignupField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.optional = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.suffix,
    this.readOnly = false,
    this.onTap,
    this.obscureText = false,
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
              child: Text(
                label,
                style: AppTypography.labelCaps.copyWith(color: AppColors.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              Text(
                '· OPTIONAL',
                style: AppTypography.labelCaps.copyWith(color: AppColors.outline),
              ),
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  minLines: obscureText ? 1 : minLines,
                  maxLines: obscureText ? 1 : maxLines,
                  obscureText: obscureText,
                  readOnly: readOnly,
                  onTap: onTap,
                  style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: AppTypography.bodyLg.copyWith(color: AppColors.outline),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              ?suffix,
            ],
          ),
        ),
      ],
    );
  }
}
