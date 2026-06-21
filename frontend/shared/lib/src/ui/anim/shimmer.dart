import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import 'app_motion.dart';

/// A lightweight shimmer — sweeps a highlight gradient across its child.
/// Wrap a tree of [SkeletonBox]es to build loading placeholders.
class Shimmer extends StatefulWidget {
  final Widget child;
  final Color? base;
  final Color? highlight;

  const Shimmer({super.key, required this.child, this.base, this.highlight});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AppMotion.shimmer)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.base ?? AppColors.surfaceContainerHigh;
    final highlight = widget.highlight ?? AppColors.surfaceContainerLowest;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width;
            final t = _c.value * 2 - 1; // -1 → 1
            return LinearGradient(
              begin: Alignment(-1 - t.abs(), 0),
              end: Alignment(1 + t.abs(), 0),
              stops: const [0.1, 0.5, 0.9],
              colors: [base, highlight, base],
              transform: _SlideGradient(t),
            ).createShader(Rect.fromLTWH(0, 0, dx, bounds.height));
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double t;
  const _SlideGradient(this.t);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * t, 0, 0);
}

/// A single grey placeholder block. Use inside [Shimmer].
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A ready-made shimmering "card row" skeleton — icon block + two text lines.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    // Card background stays static; only the skeleton blocks shimmer.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      child: Shimmer(
        child: Row(
          children: [
            const SkeletonBox(width: 44, height: 44, radius: AppRadius.sm),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 160, height: 13),
                  SizedBox(height: 8),
                  SkeletonBox(width: 100, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
