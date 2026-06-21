/// Single source of truth for bundled image/asset paths.
///
/// Reference these constants instead of hard-coding string paths, so moving or
/// renaming an asset only changes one line. When you add real assets, drop them
/// under `shared/assets/...`, declare them in `shared/pubspec.yaml`, and add a
/// constant here (use the `packages/shared/...` prefix so consuming apps resolve
/// them from this package).
class AppAssets {
  AppAssets._();

  /// Prefix that lets the consuming apps (doctor_app + patient_app) resolve
  /// assets bundled inside the `shared` package.
  static const String _pkg = 'packages/shared/assets';

  // ── Images (add files under shared/assets/images/) ──────────
  static const String logo = '$_pkg/images/logo.png';
  static const String onboardingHero = '$_pkg/images/onboarding_hero.png';
  static const String avatarPlaceholder = '$_pkg/images/avatar_placeholder.png';
  static const String emptyState = '$_pkg/images/empty_state.png';

  // ── Illustrations / icons-as-assets ─────────────────────────
  static const String aiBadge = '$_pkg/images/ai_badge.png';
}
