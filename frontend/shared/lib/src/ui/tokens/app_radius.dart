import 'package:flutter/material.dart';

/// Corner-radius scale from DESIGN.md `rounded` block (rem → px @ 16px).
class AppRadius {
  AppRadius._();

  static const double sm = 8;       // 0.5rem
  static const double defaultR = 16; // 1rem — base radius
  static const double md = 24;       // 1.5rem
  static const double lg = 32;       // 2rem
  static const double xl = 48;       // 3rem
  static const double full = 9999;

  // ── Pre-built BorderRadius for convenience ─────────────────
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brDefault = BorderRadius.all(Radius.circular(defaultR));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));

  // ── Component-specific aliases per DESIGN.md ───────────────
  /// Buttons + input fields → 12px squircle feel.
  static const double button = 12;
  /// Large cards → 24–32px (use `card` for default, `cardLarge` for hero).
  static const double card = defaultR;
  static const double cardLarge = card;
}
