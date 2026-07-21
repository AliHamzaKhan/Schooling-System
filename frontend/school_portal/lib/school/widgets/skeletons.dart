/// Loading placeholders for the portal's listing screens.
///
/// Each variant mirrors the silhouette of the content it stands in for, so
/// swapping placeholder → real content doesn't shift the layout. All of them
/// wrap the shared [Shimmer] once at the top rather than per row, so a list
/// pulses in step instead of every row running its own clock.
///
/// Prefer these over a bare [CircularProgressIndicator] anywhere a list, roster
/// or dashboard is loading; a centred spinner gives no sense of what's coming
/// and collapses the layout to nothing while it spins.
library;

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';


/// Page heading placeholder — big title, subtitle, and an optional action bar.
class SkeletonHeader extends StatelessWidget {
  final bool withAction;
  const SkeletonHeader({super.key, this.withAction = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(width: 200, height: 26),
        const SizedBox(height: AppSpacing.stackSm),
        const SkeletonBox(width: 270, height: 13),
        if (withAction) ...[
          const SizedBox(height: AppSpacing.stackMd),
          const SkeletonBox(height: 46, radius: AppRadius.button),
        ],
      ],
    );
  }
}

/// Generic stack of card blocks — the default for "a list of cards".
class SkeletonCardList extends StatelessWidget {
  final int count;
  final double height;
  final double gap;

  const SkeletonCardList({
    super.key,
    this.count = 5,
    this.height = 92,
    this.gap = AppSpacing.stackMd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          SkeletonBox(height: height, radius: AppRadius.card),
          if (i != count - 1) SizedBox(height: gap),
        ],
      ],
    );
  }
}

/// Rows of people: avatar, name line, detail line, trailing chip. Used for
/// student / teacher / guardian rosters.
class SkeletonRosterList extends StatelessWidget {
  final int count;
  const SkeletonRosterList({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          const _RosterRow(),
          if (i != count - 1) const SizedBox(height: AppSpacing.stackSm),
        ],
      ],
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          const SkeletonBox(width: 40, height: 40, radius: AppRadius.full),
          const SizedBox(width: AppSpacing.stackSm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 150, height: 13),
                SizedBox(height: 8),
                SkeletonBox(width: 110, height: 11),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          const SkeletonBox(width: 44, height: 20, radius: AppRadius.full),
        ],
      ),
    );
  }
}

/// Two-across KPI tiles, for dashboards and report headers.
class SkeletonStatGrid extends StatelessWidget {
  final int count;
  final double height;

  const SkeletonStatGrid({super.key, this.count = 4, this.height = 84});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i += 2) ...[
          Row(
            children: [
              Expanded(
                  child: SkeletonBox(height: height, radius: AppRadius.card)),
              const SizedBox(width: AppSpacing.stackMd),
              if (i + 1 < count)
                Expanded(
                    child: SkeletonBox(height: height, radius: AppRadius.card))
              else
                const Expanded(child: SizedBox()),
            ],
          ),
          if (i + 2 < count) const SizedBox(height: AppSpacing.stackMd),
        ],
      ],
    );
  }
}

/// A row of narrow tiles sitting side by side (three-across KPI strips).
class SkeletonStatRow extends StatelessWidget {
  final int count;
  final double height;
  const SkeletonStatRow({super.key, this.count = 3, this.height = 96});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          Expanded(child: SkeletonBox(height: height, radius: AppRadius.card)),
          if (i != count - 1) const SizedBox(width: AppSpacing.stackSm),
        ],
      ],
    );
  }
}

/// Message-thread silhouette: avatar, two body lines, trailing timestamp.
class SkeletonThreadList extends StatelessWidget {
  final int count;
  const SkeletonThreadList({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          const _ThreadRow(),
          if (i != count - 1) const SizedBox(height: AppSpacing.stackSm),
        ],
      ],
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 40, height: 40, radius: AppRadius.full),
          const SizedBox(width: AppSpacing.stackSm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 13),
                SizedBox(height: 8),
                SkeletonBox(height: 11),
                SizedBox(height: 6),
                SkeletonBox(width: 200, height: 11),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          const SkeletonBox(width: 34, height: 10),
        ],
      ),
    );
  }
}

/// Form placeholder: label + field pairs, optionally capped with a submit
/// button block.
///
/// Form screens block on loading their pickers' options, so what arrives is a
/// stack of labelled fields — not cards. Showing a card skeleton there would
/// misrepresent the screen; a bare spinner tells the user nothing about what's
/// coming and collapses the layout while it spins.
class SkeletonForm extends StatelessWidget {
  /// Number of label + field pairs to draw.
  final int fields;

  /// Draws a full-width action block at the bottom.
  final bool withSubmit;

  const SkeletonForm({super.key, this.fields = 4, this.withSubmit = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < fields; i++) ...[
          // Vary the label width so the stack doesn't read as a rigid grid.
          SkeletonBox(width: i.isEven ? 96 : 124, height: 11),
          const SizedBox(height: 6),
          const SkeletonBox(height: 46, radius: AppRadius.button),
          if (i != fields - 1) const SizedBox(height: AppSpacing.stackMd),
        ],
        if (withSubmit) ...[
          const SizedBox(height: AppSpacing.stackLg),
          const SkeletonBox(height: 48, radius: AppRadius.button),
        ],
      ],
    );
  }
}

/// Full-screen loading state for a listing page: shimmering header plus a body
/// placeholder, padded to match the real screen.
///
/// This is the drop-in replacement for `Center(child: CircularProgressIndicator())`
/// on a list screen — pass whichever body variant matches the content.
class SkeletonPage extends StatelessWidget {
  final Widget body;
  final bool withHeader;
  final bool withAction;

  const SkeletonPage({
    super.key,
    required this.body,
    this.withHeader = true,
    this.withAction = true,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        // Never scrolls in practice, but stops a tall skeleton overflowing on
        // short screens.
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            0,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (withHeader) ...[
              SkeletonHeader(withAction: withAction),
              const SizedBox(height: AppSpacing.stackLg),
            ],
            body,
          ],
        ),
      ),
    );
  }
}
