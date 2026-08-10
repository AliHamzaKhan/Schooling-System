import 'package:flutter/material.dart';

/// Clinical Precision palette — light mode tokens straight from DESIGN.md.
/// Naming mirrors Material 3 ColorScheme terms so they slot into ThemeData.
class AppColors {
  AppColors._();

  // ── Surface ─────────────────────────────────────────────────
  static const surface = Color(0xFFF6FAF8);
  static const surfaceDim = Color(0xFFD6DBD9);
  static const surfaceBright = Color(0xFFF6FAF8);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF0F5F2);
  static const surfaceContainer = Color(0xFFEAEFEC);
  static const surfaceContainerHigh = Color(0xFFE4E9E7);
  static const surfaceContainerHighest = Color(0xFFDFE4E1);
  static const onSurface = Color(0xFF171D1B);
  static const onSurfaceVariant = Color(0xFF3D4946);
  static const inverseSurface = Color(0xFF2C3130);
  static const inverseOnSurface = Color(0xFFEDF2EF);
  static const outline = Color(0xFF6D7A77);
  static const outlineVariant = Color(0xFFBCC9C5);
  static const surfaceTint = Color(0xFF0F172A);
  static const surfaceVariant = Color(0xFFDFE4E1);

  // ── Primary (deep slate — brand) ────────────────────────────
  static const primary = Color(0xFF0F172A);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF334155);
  static const onPrimaryContainer = Color(0xFFEAEEFF);
  static const inversePrimary = Color(0xFFB6C2FF);
  static const primaryFixed = Color(0xFFDCE1FF);
  static const primaryFixedDim = Color(0xFFB6C2FF);
  static const onPrimaryFixed = Color(0xFF00105C);
  static const onPrimaryFixedVariant = Color(0xFF263B86);

  /// Darker slate — the end stop of the [PrimaryButton] vertical gradient.
  static const primaryGradientEnd = Color(0xFF0A0F1E);

  // ── Secondary (soft blue) ───────────────────────────────────
  static const secondary = Color(0xFF526069);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFD3E2ED);
  static const onSecondaryContainer = Color(0xFF56656E);
  static const secondaryFixed = Color(0xFFD6E5EF);
  static const secondaryFixedDim = Color(0xFFBAC9D3);
  static const onSecondaryFixed = Color(0xFF0F1D25);
  static const onSecondaryFixedVariant = Color(0xFF3B4951);

  // ── Tertiary (emerald — vitals / positive) ──────────────────
  static const tertiary = Color(0xFF006B1B);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF268630);
  static const onTertiaryContainer = Color(0xFFF7FFF1);
  static const tertiaryFixed = Color(0xFF98F994);
  static const tertiaryFixedDim = Color(0xFF7DDC7A);
  static const onTertiaryFixed = Color(0xFF002204);
  static const onTertiaryFixedVariant = Color(0xFF005313);

  // ── Error ───────────────────────────────────────────────────
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // ── Background ──────────────────────────────────────────────
  static const background = Color(0xFFF1F5F9);
  static const onBackground = Color(0xFF171D1B);

  // ── AI accent (subtle purple — predictive data, smart suggestions) ──
  /// Per DESIGN.md component spec — glow rgba(126,87,194,.3).
  static const aiAccent = Color(0xFF7E57C2);
  static const aiAccentSoft = Color(0x4D7E57C2); // 30% opacity for glow

  // ── Glass effect overlays ───────────────────────────────────
  /// Inner border at 20% white — every glass surface uses this.
  static const glassBorder = Color(0x33FFFFFF); // 20% white
  /// Glass fill base — 80% white per DESIGN.md.
  static const glassFillLight = Color(0xCCFFFFFF); // 80% white
  /// Solar glow — 5% primary slate for level-2 modals.
  static const solarGlow = Color(0x0D0F172A); // 5% primary
}
