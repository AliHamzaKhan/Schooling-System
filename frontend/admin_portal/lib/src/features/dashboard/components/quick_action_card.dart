import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Large tappable call-to-action banner (Create School / Manage Headmasters).
///
/// [filled] cards use a solid navy background with light text; otherwise the
/// card is tinted with [background] and uses dark text. A big watermark [icon]
/// sits on the right.
class QuickActionCard extends StatelessWidget {
  final String label;
  final IconData leadingIcon;
  final IconData watermarkIcon;
  final Color background;
  final bool filled;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.label,
    required this.leadingIcon,
    required this.watermarkIcon,
    required this.background,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.onPrimary : AppColors.primary;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: SizedBox(
          height: 96,
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -8,
                child: Icon(watermarkIcon,
                    size: 96, color: fg.withValues(alpha: 0.12)),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(leadingIcon, color: fg, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.stackMd),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTypography.titleLg.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
