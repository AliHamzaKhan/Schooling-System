import 'package:flutter/material.dart';

/// App palette — light mode tokens.
///
/// Indigo actions, rose highlights and teal progress on a lavender canvas.
/// Naming mirrors Material 3 ColorScheme terms so they slot into ThemeData.
class AppColors {
  AppColors._();

  // ── Surface ────────────────────────────────────────────────
  static const surface = Color(0xFFF6F7FC);
  static const surfaceDim = Color(0xFFD6DBD9);
  static const surfaceBright = Color(0xFFFFFFFF);

  // ── Card ────────────────────────────────────────────────────
  /// White cards separate from the tinted canvas. Feature cards may add a
  /// translucent subject accent while preserving readable foreground colors.
  static const card = Color(0xFFFFFFFF);

  /// Hairline border for cards — a touch deeper than [card] so the panel edge
  /// stays crisp on white.
  static const cardBorder = Color(0xFFE2E7F1);

  // `surfaceContainerLowest` is the M3 "card level" surface; alias it to [card]
  // so the many call sites that fill with it match every other card.
  static const surfaceContainerLowest = card;
  static const surfaceContainerLow = Color(0xFFF0F2FB);
  static const surfaceContainer = Color(0xFFEAEDF8);
  static const surfaceContainerHigh = Color(0xFFE2E6F5);
  static const surfaceContainerHighest = Color(0xFFD8DFF0);
  static const onSurface = Color(0xFF202644);
  static const onSurfaceVariant = Color(0xFF606780);
  static const inverseSurface = Color(0xFF2C3130);
  static const inverseOnSurface = Color(0xFFEDF2EF);
  static const outline = Color(0xFF6D7A77);
  static const outlineVariant = Color(0xFFDFE3F0);
  static const surfaceTint = primary;
  static const surfaceVariant = surfaceContainerHigh;

  // ── Primary (indigo) ────────────────────────────────────────
  static const primary = Color(0xFF5446D9);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF4437B8);
  static const onPrimaryContainer = Color(0xFFEAEEFF);
  static const inversePrimary = Color(0xFFB6C2FF);
  static const primaryFixed = Color(0xFFDCE1FF);
  static const primaryFixedDim = Color(0xFFB6C2FF);
  static const onPrimaryFixed = Color(0xFF00105C);
  static const onPrimaryFixedVariant = Color(0xFF263B86);

  /// Violet end stop of the primary action gradient.
  static const primaryGradientEnd = Color(0xFF7763ED);

  // ── Secondary (rose) ───────────────────────────────────────
  static const secondary = Color(0xFFB84662);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFFE8EF);
  static const onSecondaryContainer = Color(0xFF1A1C22);
  static const secondaryFixed = Color(0xFFD6E5EF);
  static const secondaryFixedDim = Color(0xFFBAC9D3);
  static const onSecondaryFixed = Color(0xFF0F1D25);
  static const onSecondaryFixedVariant = Color(0xFF3B4951);

  // ── Tertiary (emerald — vitals / positive) ──────────────────
  static const tertiary = Color(0xFF087F78);
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

  // ── Background ─────────────────────────────────────────────
  static const background = Color(0xFFF6F7FC);
  static const onBackground = onSurface;

  // ── AI accent (subtle purple — predictive data, smart suggestions) ──
  /// Per DESIGN.md component spec — glow rgba(126,87,194,.3).
  static const aiAccent = Color(0xFF7E57C2);
  static const aiAccentSoft = Color(0x4D7E57C2); // 30% opacity for glow

  // ── Glass effect overlays ───────────────────────────────────
  /// Inner border at 20% white — every glass surface uses this.
  static const glassBorder = Color(0x33FFFFFF); // 20% white
  /// Glass fill base — 80% white per DESIGN.md.
  static const glassFillLight = Color(0xCCFFFFFF); // 80% white
  /// Solar glow — 5% primary navy for level-2 modals.
  static const solarGlow = Color(0x0D1E2952); // 5% primary
}
