/// Centralized user-facing strings for school_portal.
///
/// Group strings by the screen / domain that owns them. When localization is
/// wired up later, replace these getters with `tr('app.name')` calls — every
/// callsite already routes through this single surface.
class AppStrings {
  AppStrings._();

  // ── App ─────────────────────────────────────────────────────
  static const appName = 'Meri Taleem';
  static const islandTitle = 'Meri Taleem Island';

  // ── Splash ──────────────────────────────────────────────────
  static const splashTagline = 'One school, one app.';
  static const splashUnreachable =
      "Can't reach the server.\nCheck your connection and try again.";

  // ── Auth / shell ────────────────────────────────────────────
  static const homeWelcome = "Here's what's happening on campus today.";

  // ── Common actions ──────────────────────────────────────────
  static const viewAll = 'View All';
  static const viewProfile = 'View Profile';
  static const filter = 'Filter';
  static const newItem = 'New';
}
