/// The shared dashboard layout, extracted from the guardian home screen so the
/// other three modules are the *same* screen with different numbers in it
/// rather than four screens that happen to look similar.
///
/// The shape, in order: who you are looking at, four numbers, the one action
/// that matters most, then the shortcuts. It reads top-down as "who / how are
/// they doing / what do I do now / where else can I go", which is why the
/// identity card comes first even on a module where the identity is the
/// signed-in user and never changes.
library;

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'profile_avatar.dart';


/// One metric in the 2×2 grid.
class DashboardStat {
  final IconData icon;
  final Color accent;

  /// The number, large. Kept a [String] because these are not all numbers —
  /// "Paid" sits in the same grid as "0%", and formatting a fee status as a
  /// figure would be worse than leaving the caller to say what it is.
  final String value;
  final String label;

  /// The line under the label, in the accent colour — "This month", "All
  /// clear". Optional, but a number without a period or a qualifier usually
  /// leaves the reader guessing.
  final String? sub;
  final VoidCallback? onTap;

  const DashboardStat({
    required this.icon,
    required this.accent,
    required this.value,
    required this.label,
    this.sub,
    this.onTap,
  });
}

/// One shortcut tile in the quick-links block.
class DashboardLink {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const DashboardLink({required this.icon, required this.label, this.onTap});
}

/// Whose dashboard this is: their photo, a name, and a line of context.
///
/// The photo is optional and initials are derived rather than stored — every
/// module knows a name, and two letters tell the reader more than a grey
/// placeholder would.
class DashboardIdentityCard extends StatelessWidget {
  final String title;
  final String subtitle;

  /// The user's profile photo. Absolute or host-relative; falls back to the
  /// initials block when null, empty, or unloadable.
  final String? avatarUrl;

  /// Replaces the initials/photo block when the module has something better to
  /// show (the guardian module passes a child's avatar).
  final Widget? leading;
  final VoidCallback? onTap;

  const DashboardIdentityCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.avatarUrl,
    this.leading,
    this.onTap,
  });

  /// First letters of the first two words: "Test High Student" → "TH".
  static String initialsOf(String name) => ProfileAvatar.initialsOf(name);

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          leading ??
              ProfileAvatar(
                name: title,
                url: avatarUrl,
                size: 56,
                cornerRadius: AppRadius.defaultR,
              ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLg.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// The four headline numbers.
///
/// Two per row on a phone (two rows of two fill the width at a readable size on
/// the narrowest phone this ships to); the count steps up with width so the row
/// doesn't stretch on larger screens — three on a tablet, four on the web.
class DashboardStatGrid extends StatelessWidget {
  final List<DashboardStat> stats;
  const DashboardStatGrid({super.key, required this.stats});

  /// Columns for the current width: 2 on phones, 3 on tablets, 4 on wide/web.
  static int columnsFor(double width) {
    if (width >= 1024) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: columnsFor(constraints.maxWidth),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.stackMd,
          crossAxisSpacing: AppSpacing.stackMd,
          childAspectRatio: 1,
          children: [for (final stat in stats) DashboardStatCard(stat: stat)],
        );
      },
    );
  }
}

/// A single metric card. Public because the guardian grid and the headmaster
/// KPI strip both build one directly.
class DashboardStatCard extends StatelessWidget {
  final DashboardStat stat;
  const DashboardStatCard({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      onTap: stat.onTap,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: stat.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm + 2),
            ),
            child: Icon(stat.icon, size: 18, color: stat.accent),
          ),
          // A fixed gap rather than a Spacer: the card is also used outside the
          // grid, where its height is unbounded and a flex child would throw.
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headlineLg.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMd,
          ),
          if (stat.sub != null) ...[
            const SizedBox(height: 2),
            Text(
              stat.sub!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMd.copyWith(color: stat.accent),
            ),
          ],
        ],
      ),
    );
  }
}

/// The one full-width action a module wants to put in front of everything else.
class DashboardPrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label;

  /// A second line, when the action needs explaining. Most do not.
  final String? subtitle;
  final VoidCallback? onTap;

  const DashboardPrimaryAction({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// The shortcut tiles, three to a row.
///
/// Three per row rather than a flexible fit: the labels are short but not
/// uniformly short ("Report Card" against "Exams"), and a row that reflows by
/// width puts them in different places on different phones.
class DashboardQuickLinks extends StatelessWidget {
  final List<DashboardLink> links;
  const DashboardQuickLinks({super.key, required this.links});

  static const int _perRow = 3;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < links.length; start += _perRow) {
      final slice = links.skip(start).take(_perRow).toList();
      rows.add(Row(
        children: [
          for (var i = 0; i < _perRow; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.stackSm),
            // The last row is padded with empty slots so its tiles keep the
            // width of the rows above rather than stretching to fill.
            Expanded(
              child: i < slice.length
                  ? _LinkTile(link: slice[i])
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ));
      if (start + _perRow < links.length) {
        rows.add(const SizedBox(height: AppSpacing.stackSm));
      }
    }
    return Column(children: rows);
  }
}

class _LinkTile extends StatelessWidget {
  final DashboardLink link;
  const _LinkTile({required this.link});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: link.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(link.icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              link.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMd,
            ),
          ],
        ),
      ),
    );
  }
}
