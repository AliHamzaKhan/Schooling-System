import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Glassmorphic depth tokens from DESIGN.md.
///
/// Depth is communicated via blur + transparency, not drop shadows:
/// - L0 Base   → solid neutral background.
/// - L1 Surface → 80% white + 20px backdrop blur + 20% white inner border.
/// - L2 Modal   → 60% white + 20px blur + soft 40px "solar" glow.
class AppElevation {
  AppElevation._();

  // ── Backdrop blur ───────────────────────────────────────────
  /// Standard glass blur sigma (in Flutter units — ~20px CSS).
  static const double blurSigma = 20;

  /// L1 fill — translucent white for glass surfaces.
  static const Color l1Fill = AppColors.glassFillLight;

  /// L2 fill — slightly more translucent for modals/popovers.
  static const Color l2Fill = Color(0x99FFFFFF); // 60% white

  /// Inner stroke — 1px @ 20% white, the "light catching the edge".
  static const Color edgeStroke = AppColors.glassBorder;

  // ── Solar glow — soft 40px spread, 5% primary teal ──────────
  static final List<BoxShadow> solarGlow = [
    BoxShadow(
      color: AppColors.solarGlow,
      blurRadius: 40,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  // ── AI insight glow — 12px @ 30% purple ─────────────────────
  static final List<BoxShadow> aiGlow = [
    BoxShadow(
      color: AppColors.aiAccentSoft,
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  /// Backdrop filter used inside glass surfaces.
  static ImageFilter glassFilter() => ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma);
}
