import 'package:flutter/material.dart';

import '../admin_theme.dart';
import 'admin_surface.dart';

/// Slim brand header above the page title on admin tab screens.
///
/// Left: optional avatar chip + the "Meri Taleem Admin" wordmark. Right: a
/// bordered bell button with an optional unread dot, plus any extra [actions].
class AdminTopBar extends StatelessWidget {
  final String title;
  final bool showAvatar;
  final bool hasUnread;
  final VoidCallback? onBell;
  final List<Widget> actions;

  const AdminTopBar({
    super.key,
    this.title = 'Meri Taleem Admin',
    this.showAvatar = false,
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
          if (showAvatar) ...[
            const AdminIconTile(icon: Icons.shield_moon_outlined, size: 32),
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
              const Icon(Icons.notifications_none_rounded,
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
