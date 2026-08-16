import 'package:flutter/material.dart';

import '../../../ui/admin_theme.dart';
import '../../../ui/admin_widgets/admin_surface.dart';

/// Hero call-to-action on the admin home — a filled navy panel with a stacked
/// icon chip, title and supporting line, plus a large watermark glyph.
class QuickActionCard extends StatelessWidget {
  final String label;
  final String? description;
  final IconData leadingIcon;
  final IconData watermarkIcon;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.label,
    required this.leadingIcon,
    required this.watermarkIcon,
    required this.onTap,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      filled: true,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -18,
            child: Icon(watermarkIcon,
                size: 118, color: Colors.white.withValues(alpha: 0.07)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AdminRadius.tile),
                  ),
                  alignment: Alignment.center,
                  child: Icon(leadingIcon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: AdminType.sectionTitle.copyWith(color: Colors.white),
                ),
                if (description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    description!,
                    style: AdminType.body
                        .copyWith(color: Colors.white.withValues(alpha: 0.72)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
