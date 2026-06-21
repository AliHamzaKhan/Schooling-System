import 'package:flutter/material.dart';

import '../../../../ui/tokens/app_colors.dart';
import '../../../../ui/tokens/app_typography.dart';
import '../../models/password_strength.dart';

/// 4-segment strength meter + label, mirroring the mockup.
class PasswordStrengthBar extends StatelessWidget {
  final PasswordStrength strength;

  const PasswordStrengthBar({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 3 ? 0 : 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 5,
                    decoration: BoxDecoration(
                      color: i < strength.score
                          ? strength.color
                          : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (strength.label.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Password strength: ${strength.label}',
              style: AppTypography.labelMd.copyWith(color: strength.color)),
        ] else ...[
          const SizedBox(height: 8),
          Text('Password strength',
              style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ],
    );
  }
}
