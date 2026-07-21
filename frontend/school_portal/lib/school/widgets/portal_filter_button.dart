import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Square filter icon button that sits to the right of a [PortalSearchField]
/// and opens a filter bottom sheet.
///
/// [count] is the number of active filters; when non-zero the button picks up
/// the primary accent and shows a small badge.
class PortalFilterButton extends StatelessWidget {
  final VoidCallback onTap;
  final int count;

  const PortalFilterButton({super.key, required this.onTap, this.count = 0});

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Material(
      color: active ? AppColors.primary : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.outlineVariant,
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.tune_rounded,
                  size: 20,
                  color: active ? AppColors.onPrimary : AppColors.primary),
              if (active)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.onPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Text('$count',
                        style: AppTypography.labelMd.copyWith(
                          fontSize: 10,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        )),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
