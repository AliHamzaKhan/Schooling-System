import 'package:flutter/material.dart';

import '../../../ui/tokens/app_colors.dart';
import '../../../ui/tokens/app_radius.dart';

/// The rounded icon badge that crowns the forgot / OTP / reset cards.
///
/// Rendered in the single navy scheme (soft primary tint fill + primary icon)
/// so every auth screen stays visually consistent.
class AuthIconBadge extends StatelessWidget {
  final IconData icon;
  final double size;

  const AuthIconBadge({super.key, required this.icon, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: AppColors.primary, size: size * 0.46),
    );
  }
}
