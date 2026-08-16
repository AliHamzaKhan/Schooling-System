import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Admin portal visual language — "Indigo Ledger".
///
/// The shared `AppColors` palette is tuned for the school/parent apps (a warm
/// green-tinted "Clinical Precision" surface). The admin portal is a control
/// plane rather than a classroom tool, so it runs on its own cooler palette:
/// a near-white lavender canvas, deep navy ink, and flat white cards with a
/// hairline border instead of the glass/blur treatment.
///
/// These tokens are admin-local on purpose — nothing here leaks back into
/// `shared`, so the school portal keeps its own look.
class AdminPalette {
  AdminPalette._();

  // ── Canvas & surfaces ───────────────────────────────────────
  /// Page background — barely-there lavender.
  static const canvas = Color(0xFFF8F7FC);

  /// Card / sheet fill.
  static const card = Color(0xFFFFFFFF);

  /// Tinted fill for stat tiles and icon chips.
  static const tint = Color(0xFFEFF1FA);

  /// Hairline card border.
  static const border = Color(0xFFE7E6F2);

  /// Divider inside a card (lighter than [border]).
  static const divider = Color(0xFFF0EFF7);

  // ── Ink ─────────────────────────────────────────────────────
  /// Headings, values, primary actions.
  static const ink = Color(0xFF13294B);

  /// Slightly lifted navy for filled surfaces (FAB, hero card).
  static const inkSoft = Color(0xFF1B3560);

  /// Body copy / secondary text.
  static const muted = Color(0xFF6B7590);

  /// Metadata, uppercase section labels, placeholder text.
  static const faint = Color(0xFF9AA1B8);

  // ── Semantic accents ────────────────────────────────────────
  static const positive = Color(0xFF16A34A);
  static const positiveSoft = Color(0xFFDDF6E5);
  static const warning = Color(0xFFD97706);
  static const warningSoft = Color(0xFFFDF0DC);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFCE4E4);
  static const info = Color(0xFF6366F1);
  static const infoSoft = Color(0xFFE8E9FD);

  // ── Elevation ───────────────────────────────────────────────
  /// The only shadow in the system — soft, low, and barely visible.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A13294B), blurRadius: 14, offset: Offset(0, 4)),
  ];

  /// Lift used by the FAB and the filled hero card.
  static const List<BoxShadow> raisedShadow = [
    BoxShadow(color: Color(0x2613294B), blurRadius: 18, offset: Offset(0, 8)),
  ];
}

/// Corner radii used across admin screens.
class AdminRadius {
  AdminRadius._();

  static const double chip = 999;
  static const double tile = 12;
  static const double card = 18;
  static const double sheet = 24;

  static const BorderRadius brTile = BorderRadius.all(Radius.circular(tile));
  static const BorderRadius brCard = BorderRadius.all(Radius.circular(card));
  static const BorderRadius brSheet = BorderRadius.all(Radius.circular(sheet));
}

/// Type ramp for the admin portal — same Inter family as `shared`, re-weighted
/// around the navy ink so screen titles read as headlines rather than labels.
class AdminType {
  AdminType._();

  static const _family = 'packages/shared/Inter';

  /// Screen title ("Schools Directory", "Welcome Back, Admin").
  static const TextStyle screenTitle = TextStyle(
    fontFamily: _family,
    fontSize: 27,
    fontWeight: FontWeight.w700,
    height: 34 / 27,
    letterSpacing: -0.6,
    color: AdminPalette.ink,
  );

  /// Sub-line under a screen title.
  static const TextStyle screenSubtitle = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 22 / 15,
    color: AdminPalette.muted,
  );

  /// Section heading inside the page flow ("Quick Actions").
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 28 / 20,
    letterSpacing: -0.3,
    color: AdminPalette.ink,
  );

  /// Card title (school name, tile heading).
  static const TextStyle cardTitle = TextStyle(
    fontFamily: _family,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    height: 26 / 19,
    letterSpacing: -0.3,
    color: AdminPalette.ink,
  );

  /// List-row title (settings tile, transaction name).
  static const TextStyle rowTitle = TextStyle(
    fontFamily: _family,
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    height: 22 / 15.5,
    color: AdminPalette.ink,
  );

  /// The big number on a KPI tile.
  static const TextStyle metric = TextStyle(
    fontFamily: _family,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 32 / 26,
    letterSpacing: -0.8,
    color: AdminPalette.ink,
  );

  /// Body copy inside cards.
  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AdminPalette.muted,
  );

  /// Metadata rows, timestamps.
  static const TextStyle meta = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    color: AdminPalette.muted,
  );

  /// Buttons, chips, inline links.
  static const TextStyle label = TextStyle(
    fontFamily: _family,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    height: 18 / 13.5,
    color: AdminPalette.ink,
  );

  /// Uppercase group label ("ACCESS CONTROL", "TOTAL REVENUE").
  static const TextStyle overline = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 16 / 11,
    letterSpacing: 0.7,
    color: AdminPalette.faint,
  );
}

/// Admin `ThemeData` — the shared light theme re-based onto [AdminPalette] so
/// framework-owned chrome (scaffold, dialogs, inputs, ripples) matches the
/// hand-built admin widgets.
ThemeData adminTheme() {
  final base = AppTheme.light();
  return base.copyWith(
    scaffoldBackgroundColor: AdminPalette.canvas,
    colorScheme: base.colorScheme.copyWith(
      primary: AdminPalette.ink,
      onPrimary: Colors.white,
      surface: AdminPalette.canvas,
      onSurface: AdminPalette.ink,
      onSurfaceVariant: AdminPalette.muted,
      outlineVariant: AdminPalette.border,
      error: AdminPalette.danger,
    ),
    dividerColor: AdminPalette.divider,
    cardTheme: base.cardTheme.copyWith(
      color: AdminPalette.card,
      shape: const RoundedRectangleBorder(borderRadius: AdminRadius.brCard),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: AdminPalette.card,
      shape: const RoundedRectangleBorder(borderRadius: AdminRadius.brSheet),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      fillColor: AdminPalette.tint,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AdminRadius.tile),
        borderSide: const BorderSide(color: AdminPalette.ink, width: 1.5),
      ),
      hintStyle: AdminType.body.copyWith(color: AdminPalette.faint),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AdminPalette.ink,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AdminRadius.brCard),
    ),
  );
}
