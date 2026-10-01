import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../config/image_constant.dart';

/// Single compact header shown on every module tab screen — avatar (tap for the
/// account menu, incl. **Log out**), the module wordmark, optional screen
/// actions, then a bell (announcements) with an unread dot and a **Log out**
/// icon on the right.
///
/// This is the only top bar: the module shell no longer stacks a Material
/// [AppBar] above it, so the account/logout affordance lives here.
class PortalTopBar extends StatelessWidget {
  final String title;
  final bool showAvatar;
  final bool hasUnread;
  final VoidCallback? onBell;
  final List<Widget> actions;

  const PortalTopBar({
    super.key,
    this.title = 'Meri Taleem Island',
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
        AppSpacing.stackSm,
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackSm,
      ),
      child: Row(
        children: [
          if (showAvatar) ...[
            InkWell(
              onTap: () => _showAccountMenu(context),
              // customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.surface,
                // ClipOval because the app icon is a full-bleed square — its
                // corners would otherwise poke out of the avatar circle.
                child: ClipOval(
                  child: Image.asset(
                    ImageConstant.appIcon,
                    width: 25,
                    height: 25,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.stackSm),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleLg.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...actions,
          IconButton(
            tooltip: 'Notifications',
            onPressed: onBell,
            splashRadius: 22,
            visualDensity: VisualDensity.compact,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  AppIcons.notificationsNoneRounded,
                  color: AppColors.onSurface,
                  size: 24,
                ),
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
          IconButton(
            onPressed: _confirmLogout,
            splashRadius: 22,
            visualDensity: VisualDensity.compact,
            tooltip: 'Log out',
            icon: const Icon(
              AppIcons.logoutRounded,
              color: AppColors.onSurface,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  /// Account sheet reached by tapping the avatar. Currently carries **Log out**;
  /// a natural home for profile/settings entries later.
  Future<void> _showAccountMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.stackMd),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            ListTile(
              leading: const Icon(Icons.devices_outlined),
              title: const Text('Active sessions'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Get.to(
                  () => SessionsView(
                    auth: Get.find<AuthService>(),
                    onSignedOut: () => Get.offAllNamed(AuthRoutes.login),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                AppIcons.logoutRounded,
                color: AppColors.error,
              ),
              title: const Text('Log out'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmLogout();
              },
            ),
            const SizedBox(height: AppSpacing.stackSm),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showAppConfirm(
      icon: AppIcons.logoutRounded,
      title: 'Log out?',
      message: 'You will need to sign in again to continue.',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (!confirmed) return;
    await Get.find<AuthService>().logout();
    Get.offAllNamed(AuthRoutes.login);
  }
}
