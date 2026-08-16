import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../admin_theme.dart';

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
        Icon(icon, size: 20, color: AdminPalette.muted),
        const SizedBox(width: AppSpacing.stackMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AdminType.rowTitle
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: AdminType.body),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.stackMd),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AdminPalette.ink,
          inactiveThumbColor: AdminPalette.muted,
          inactiveTrackColor: AdminPalette.tint,
        ),
      ],
    );
  }
}
