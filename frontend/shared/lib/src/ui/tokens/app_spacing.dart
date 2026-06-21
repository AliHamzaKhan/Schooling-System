/// 8-px spacing rhythm from DESIGN.md.
class AppSpacing {
  AppSpacing._();

  /// Base unit. All other spacing is a multiple of this.
  static const double unit = 8;

  // ── Stack gaps ──────────────────────────────────────────────
  static const double stackSm = 8;
  static const double stackMd = 16;
  static const double stackLg = 24;
  static const double stackXl = 32;
  static const double stackXxl = 48;

  // ── Container padding (per DESIGN.md) ───────────────────────
  static const double containerPaddingMobile = 20;
  static const double containerPaddingDesktop = 32;

  // ── Grid gutters ────────────────────────────────────────────
  static const double gutterDesktop = 24;
  static const double gutterTablet = 20;
  static const double gutterMobile = 16;

  // ── Layout maxima ───────────────────────────────────────────
  /// Centered content max-width on desktop.
  static const double contentMaxWidth = 1280;
}
