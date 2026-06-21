/// Central registry of every backend path used by the Guardian module.
///
/// No endpoint string is hardcoded inside the API service or repository — they
/// all live here so the backend contract can change in one place. Paths are
/// relative to `EnvConfig.apiBaseUrl` (the shared [ApiService] prefixes it).
class GuardianEndpoints {
  GuardianEndpoints._();

  static const _base = '/guardian';

  /// Children linked to the signed-in guardian.
  static const children = '$_base/children';

  /// Per-child resources. Pass the child id to build the concrete path.
  static String dashboardFeed(String childId) => '$_base/$childId/activity';
  static String attendance(String childId) => '$_base/$childId/attendance';
  static String performance(String childId) => '$_base/$childId/performance';
  static String fees(String childId) => '$_base/$childId/fees';
  static String homework(String childId) => '$_base/$childId/homework';
  static String exams(String childId) => '$_base/$childId/exams';
  static String meetings(String childId) => '$_base/$childId/meetings';

  /// Guardian-wide notifications (not scoped to a single child).
  static const notifications = '$_base/notifications';

  // ── Live, school-scoped backend path (`/schools/{school_id}/...`) ──
  // The only guardian-wide feature with a real backend: school broadcasts
  // (guardian has MESSAGING view). All per-child paths above stay mock — the
  // backend has no guardian↔child linkage or per-child guardian endpoints.
  static String broadcasts(String schoolId) =>
      '/schools/$schoolId/communication/broadcasts';
}
