import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_elevation.dart';
import '../tokens/app_radius.dart';

/// The base glass card from DESIGN.md.
///
/// - Translucent white fill (80% / 60% by level)
/// - 20-sigma backdrop blur
/// - 1 px inner stroke at 20% white (the "edge lighting")
/// - Optional 5%-teal "solar glow" at level 2
///
/// Usage:
/// ```dart
/// GlassSurface(
///   padding: const EdgeInsets.all(24),
///   child: Text('Vitals'),
/// )
/// ```
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final GlassLevel level;
  final Color? fill;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = AppRadius.card,
    this.level = GlassLevel.l1,
    this.fill,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final bg = fill ?? (level == GlassLevel.l2 ? AppElevation.l2Fill : AppElevation.l1Fill);
    final glow = level == GlassLevel.l2 ? AppElevation.solarGlow : <BoxShadow>[];

    final card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: AppElevation.glassFilter(),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: Border.all(color: AppElevation.edgeStroke, width: 1),
          ),
          child: child,
        ),
      ),
    );

    // Wrap in DecoratedBox for the outer glow so it sits *outside* the clip.
    final withGlow = glow.isEmpty
        ? card
        : DecoratedBox(
            decoration: BoxDecoration(borderRadius: radius, boxShadow: glow),
            child: card,
          );

    if (onTap == null) return withGlow;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        hoverColor: AppColors.glassBorder,
        child: withGlow,
      ),
    );
  }
}

enum GlassLevel { l1, l2 }
