import 'package:flutter/material.dart';

import '../admin_theme.dart';

/// Horizontal page gutter used by every admin screen.
const double kAdminGutter = 20;

/// Root wrapper for a tab screen: paints the admin canvas behind the content.
///
/// The tab screens live inside `PersistentTabView`, which owns the Scaffold, so
/// each screen paints its own background rather than relying on
/// `scaffoldBackgroundColor`.
class AdminScreen extends StatelessWidget {
  final Widget child;
  const AdminScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AdminPalette.canvas,
        child: SafeArea(bottom: false, child: child),
      );
}

/// The one card shape in the admin portal: white fill, hairline border, soft
/// shadow, 18px corners. Pass [filled] for the inverted navy hero treatment.
class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool filled;
  final Color? color;
  final double radius;

  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.filled = false,
    this.color,
    this.radius = AdminRadius.card,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    final fill = color ?? (filled ? AdminPalette.ink : AdminPalette.card);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: br,
        border: filled ? null : Border.all(color: AdminPalette.border),
        boxShadow:
            filled ? AdminPalette.raisedShadow : AdminPalette.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: br,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          splashColor: filled
              ? Colors.white.withValues(alpha: 0.08)
              : AdminPalette.ink.withValues(alpha: 0.05),
          highlightColor: Colors.transparent,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Rounded icon chip that fronts most rows and cards. Defaults to the lavender
/// tint with navy glyph; pass [background]/[foreground] for accented variants.
class AdminIconTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? background;
  final Color? foreground;

  const AdminIconTile({
    super.key,
    required this.icon,
    this.size = 44,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? AdminPalette.tint,
          borderRadius: BorderRadius.circular(size <= 40 ? 10 : AdminRadius.tile),
        ),
        alignment: Alignment.center,
        child: Icon(icon,
            size: size * 0.48, color: foreground ?? AdminPalette.ink),
      );
}

/// Screen title + optional supporting line, at the top of a page's scroll.
class AdminPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry padding;

  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.padding = const EdgeInsets.only(bottom: 20),
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AdminType.screenTitle),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: AdminType.screenSubtitle),
            ],
          ],
        ),
      );
}

/// Uppercase group label that introduces a stack of cards.
class AdminGroupLabel extends StatelessWidget {
  final String text;
  const AdminGroupLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text.toUpperCase(), style: AdminType.overline),
      );
}

/// Icon + text metadata line used inside cards (location, students, plan).
class AdminMetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? tint;

  const AdminMetaRow({
    super.key,
    required this.icon,
    required this.text,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final color = tint ?? AdminPalette.muted;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: AdminType.meta.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

/// Navigation row: icon chip, title, optional subtitle, trailing chevron.
class AdminNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconBackground;
  final Color? iconForeground;

  const AdminNavTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconBackground,
    this.iconForeground,
  });

  @override
  Widget build(BuildContext context) => AdminCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            AdminIconTile(
              icon: icon,
              size: 42,
              background: iconBackground,
              foreground: iconForeground,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AdminType.rowTitle),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!, style: AdminType.meta),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 22, color: AdminPalette.faint),
          ],
        ),
      );
}

/// Soft-filled status chip — a colored dot plus a label (Active, Pending…).
class AdminStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const AdminStatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AdminRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: AdminType.meta.copyWith(
                    color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      );
}

/// Right-aligned inline action ("Manage →", "View All").
class AdminInlineAction extends StatelessWidget {
  final String label;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  const AdminInlineAction({
    super.key,
    required this.label,
    this.trailingIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        // Self-contained so the action can sit on any surface, not just inside
        // a card that already provides a Material ancestor.
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style:
                        AdminType.label.copyWith(fontWeight: FontWeight.w700)),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 6),
                  Icon(trailingIcon, size: 17, color: AdminPalette.ink),
                ],
              ],
            ),
          ),
        ),
      );
}
