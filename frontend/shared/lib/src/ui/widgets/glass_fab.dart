import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_elevation.dart';

/// Circular, high-elevation Floating Action Button per DESIGN.md.
///
/// Use for "New Appointment", "AI Analysis", etc.
class GlassFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool aiAccent;

  const GlassFab({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.aiAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = aiAccent ? AppColors.aiAccent : AppColors.onPrimary;
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: aiAccent ? AppElevation.aiGlow : AppElevation.solarGlow,
        ),
        child: Material(
          color: aiAccent ? AppColors.surfaceContainerLowest : AppColors.primary,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(icon, color: iconColor, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
