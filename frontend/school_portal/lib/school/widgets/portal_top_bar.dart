import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

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
        AppSpacing.stackSm,
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackSm,
      ),
      child: Row(
        children: [
          if (showAvatar) ...[
            InkWell(
              onTap: () => _showAccountMenu(context),
              customBorder: const CircleBorder(),
              child: const CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.tertiaryContainer,
                child: Icon(Icons.person, color: AppColors.onTertiary, size: 19),
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
            onPressed: onBell,
            splashRadius: 22,
            visualDensity: VisualDensity.compact,
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
          IconButton(
            onPressed: _confirmLogout,
            splashRadius: 22,
            visualDensity: VisualDensity.compact,
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.onSurface, size: 22),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
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
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
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
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Get.find<AuthService>().logout();
    Get.offAllNamed(AuthRoutes.login);
  }
}
