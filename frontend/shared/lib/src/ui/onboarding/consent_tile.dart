import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Single-row checkbox + label tile used on the Permissions step.
class ConsentTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final bool required;
  final ValueChanged<bool> onChanged;

  const ConsentTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: value ? AppColors.primary.withValues(alpha: 0.5) : AppColors.outlineVariant,
          ),
          color: value ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surfaceContainerLowest,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: value ? AppColors.primary : AppColors.outline,
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, color: AppColors.onPrimary, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(title,
                            style: AppTypography.bodyLg.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                      if (required) ...[
                        const SizedBox(width: 6),
                        Text('REQUIRED',
                            style: AppTypography.labelCaps.copyWith(color: AppColors.error)),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTypography.bodySm),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
