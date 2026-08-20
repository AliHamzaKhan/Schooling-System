import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../admin_theme.dart';
import 'admin_surface.dart';
import 'package:shared/shared.dart';

/// Slim brand header above the page title on admin tab screens.
///
/// Left: an optional back arrow (for drill-in screens), an optional avatar chip,
/// and the "Meri Taleem Admin" wordmark. Right: a bordered bell button with an
/// optional unread dot, plus any extra [actions].
class AdminTopBar extends StatelessWidget {
  final String title;
  final bool showAvatar;
  final bool showBack;
  final VoidCallback? onBack;
  final bool hasUnread;
  final VoidCallback? onBell;
  final List<Widget> actions;

  const AdminTopBar({
    super.key,
    this.title = 'Meri Taleem Admin',
    this.showAvatar = false,
    this.showBack = false,
    this.onBack,
    this.hasUnread = true,
    this.onBell,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kAdminGutter, 12, kAdminGutter, 12),
      child: Row(
        children: [
          if (showBack) ...[
            _BackButton(onTap: onBack ?? () => Get.back<void>()),
            const SizedBox(width: 10),
          ],
          if (showAvatar) ...[
            const AdminIconTile(icon: AppIcons.shieldMoonOutlined, size: 32),
            const SizedBox(width: 10),
          ],
          Text(
            title,
            style: AdminType.label.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          const Spacer(),
          ...actions,
          _BellButton(hasUnread: hasUnread, onTap: onBell),
        ],
      ),
    );
  }
}

/// Bordered back button matching the bell button's look.
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminPalette.card,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AdminPalette.border),
          ),
          child: const Icon(AppIcons.arrowBackRounded,
              color: AdminPalette.ink, size: 20),
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  final bool hasUnread;
  final VoidCallback? onTap;
  const _BellButton({required this.hasUnread, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminPalette.card,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AdminPalette.border),
          ),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(AppIcons.notificationsNoneRounded,
                  color: AdminPalette.ink, size: 20),
              if (hasUnread)
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AdminPalette.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: AdminPalette.card, width: 1.2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
