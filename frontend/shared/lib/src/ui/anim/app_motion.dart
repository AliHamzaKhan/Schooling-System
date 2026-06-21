import 'package:flutter/animation.dart';

/// Central motion tokens — durations and curves used across the app so timing
/// stays consistent and tunable from one place.
class AppMotion {
  AppMotion._();

  // ── Durations ───────────────────────────────────────────────
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 450);

  /// Per-item delay used when staggering list entrances.
  static const Duration stagger = Duration(milliseconds: 60);

  /// Route push/pop transition length.
  static const Duration route = Duration(milliseconds: 320);

  /// Shimmer sweep period.
  static const Duration shimmer = Duration(milliseconds: 1200);

  // ── Curves ──────────────────────────────────────────────────
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve decelerate = Curves.easeOut;
}
