import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Inter type scale from DESIGN.md.
///
/// All sizes assume Material's default 1.0 textScaler. Letter-spacing is
/// expressed in absolute px (matching the source `-0.02em` etc. conversions).
class AppTypography {
  AppTypography._();

  static const _family = 'packages/shared/Inter';

  /// Hero titles only (Login, Welcome, Empty States)
  static const TextStyle displayLg = TextStyle(
    fontFamily: _family,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 44 / 36,
    letterSpacing: -0.5,
    color: AppColors.onSurface,
  );

  /// Screen titles
  static const TextStyle headlineLg = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 36 / 28,
    letterSpacing: -0.3,
    color: AppColors.onSurface,
  );

  /// Mobile screen titles
  static const TextStyle headlineLgMobile = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 30 / 22,
    color: AppColors.onSurface,
  );

  /// Section titles / Card titles
  static const TextStyle titleLg = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 26 / 18,
    color: AppColors.onSurface,
  );

  /// Subtitles
  static const TextStyle titleMd = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 24 / 16,
    color: AppColors.onSurface,
  );

  /// Main readable text
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 22 / 15,
    color: AppColors.onSurfaceVariant,
  );

  /// Secondary text
  static const TextStyle bodyMd = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.onSurfaceVariant,
  );

  /// Small helper text
  static const TextStyle bodySm = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
    color: AppColors.onSurfaceVariant,
  );

  /// Buttons & labels
  static const TextStyle labelMd = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 18 / 13,
    color: AppColors.onSurface,
  );

  /// Metadata
  static const TextStyle labelCaps = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 16 / 11,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
  );

  static TextTheme textTheme() => const TextTheme(
    displayLarge: displayLg,
    headlineLarge: headlineLg,
    headlineMedium: headlineLg,
    titleLarge: titleLg,
    titleMedium: titleMd,
    bodyLarge: bodyLg,
    bodyMedium: bodyMd,
    bodySmall: bodySm,
    labelLarge: labelMd,
    labelMedium: labelMd,
    labelSmall: labelCaps,
  );
}