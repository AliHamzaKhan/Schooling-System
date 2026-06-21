import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Brand header used across school_portal tab screens — avatar on the left,
/// the "EduMaster Island" wordmark, and a bell with an unread dot on the right.
class PortalTopBar extends StatelessWidget {
  final String title;
  final bool showAvatar;
  final bool hasUnread;
  final VoidCallback? onBell;
  final List<Widget> actions;

  const PortalTopBar({
    super.key,
    this.title = 'EduMaster Island',
    this.showAvatar = true,
    this.hasUnread = true,
    this.onBell,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackMd,
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackSm,
      ),
      child: Row(
        children: [
          if (showAvatar) ...[
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.tertiaryContainer,
              child: Icon(Icons.person, color: AppColors.onTertiary, size: 20),
            ),
            const SizedBox(width: AppSpacing.stackSm),
          ],
          Text(
            title,
            style: AppTypography.titleLg.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          ...actions,
          IconButton(
            onPressed: onBell,
            splashRadius: 22,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded,
                    color: AppColors.onSurface, size: 24),
                if (hasUnread)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
