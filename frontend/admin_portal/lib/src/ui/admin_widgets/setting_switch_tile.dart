import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// A labelled enable/disable switch row used across settings screens.
class SettingSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.stackMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTypography.titleMd
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.bodyMd),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.stackMd),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.onPrimary,
          activeTrackColor: const Color(0xFF3B82F6),
          inactiveThumbColor: AppColors.onSurfaceVariant,
          inactiveTrackColor: AppColors.surfaceContainerHighest,
        ),
      ],
    );
  }
}
