/// Central registry of every backend path used by the Guardian module.
///
/// No endpoint string is hardcoded inside the API service or repository — they
/// all live here so the backend contract can change in one place. Paths are
/// relative to `EnvConfig.apiBaseUrl` (the shared [ApiService] prefixes it).
///
/// The Guardian portal has no dedicated namespace on the backend: a guardian is
/// a school user linked to one or more students, and reads their children's
/// data through the same school-scoped resources a student uses (scoped to the
/// child's `student_id`). The only guardian-specific endpoint is the children
/// list (`/me/children`).
class GuardianEndpoints {
  GuardianEndpoints._();

  static String _base(String schoolId) => '/schools/$schoolId';

  /// Children linked to the signed-in guardian (`ChildOut` list).
  static String myChildren(String schoolId) => '${_base(schoolId)}/me/children';

  /// Per-child resources, scoped by the child's `student_id` (or section).
  static String studentAttendance(String schoolId, String studentId) =>
      '${_base(schoolId)}/students/$studentId/attendance';
  static String feesInvoices(String schoolId) =>
      '${_base(schoolId)}/fees/invoices';
  static String homeworkAssignments(String schoolId) =>
      '${_base(schoolId)}/homework/assignments';
  static String studentSubmissions(String schoolId, String studentId) =>
      '${_base(schoolId)}/homework/students/$studentId/submissions';
  static String exams(String schoolId) => '${_base(schoolId)}/exams';
  static String reportCard(String schoolId, String examId, String studentId) =>
      '${_base(schoolId)}/exams/$examId/students/$studentId/report-card';
  static String academicTimetable(String schoolId) =>
      '${_base(schoolId)}/academic/timetable';
  static String academicSubjects(String schoolId) =>
      '${_base(schoolId)}/academic/subjects';
  static String meetings(String schoolId) => '${_base(schoolId)}/meetings';

  /// School broadcasts → the guardian notifications feed (MESSAGING view).
  static String broadcasts(String schoolId) =>
      '${_base(schoolId)}/communication/broadcasts';

  /// Direct messages/complaints addressed to the signed-in guardian.
  static String directMessages(String schoolId) =>
      '${_base(schoolId)}/messages';

  // ── Leave applications (submitted for a child) ──
  static String leaveRequests(String schoolId) =>
      '${_base(schoolId)}/leave/requests';
  static String leaveMine(String schoolId) =>
      '${_base(schoolId)}/leave/requests/mine';

  // ── Transport (requests for a child + live tracking) ──
  static String transportRequests(String schoolId) =>
      '${_base(schoolId)}/transport/requests';
  static String transportRequestsMine(String schoolId) =>
      '${_base(schoolId)}/transport/requests/mine';
  static String transportTripsActive(String schoolId) =>
      '${_base(schoolId)}/transport/trips/active';
  static String transportTripLocation(String schoolId, String tripId) =>
      '${_base(schoolId)}/transport/trips/$tripId/location';
  static String transportTripEta(String schoolId, String tripId) =>
      '${_base(schoolId)}/transport/trips/$tripId/eta';
}
