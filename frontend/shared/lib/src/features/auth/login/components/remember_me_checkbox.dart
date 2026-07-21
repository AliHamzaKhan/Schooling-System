import 'package:flutter/material.dart';

import '../../../../ui/tokens/app_colors.dart';
import '../../../../ui/tokens/app_typography.dart';

/// "Remember me on this device" checkbox row.
class RememberMeCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  /// False on web, where the password can't be stored securely.
  final bool canStorePassword;

  const RememberMeCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.canStorePassword = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Remember me on this device',
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.onSurface)),
                  // The web build can't store the password safely, so say so
                  // rather than silently doing something different.
                  if (value && !canStorePassword)
                    Text('Email only in a browser — password is not saved here.',
                        style: AppTypography.bodySm
                            .copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
