import 'package:shared/shared.dart';

import '../features/announcements/models/announcement.dart';
import '../features/announcements/models/announcements_repository.dart';
import '../features/attendance/models/attendance_data.dart';
import '../features/attendance/models/attendance_repository.dart';
import '../features/classes/models/classes_data.dart';
import '../features/classes/models/classes_repository.dart';
import '../features/dashboard/models/dashboard_data.dart';
import '../features/dashboard/models/dashboard_repository.dart';
import '../features/exams/models/exams_data.dart';
import '../features/exams/models/exams_repository.dart';
import '../features/fees/models/fees_data.dart';
import '../features/fees/models/fees_repository.dart';
import '../features/guardians/models/guardian.dart';
import '../features/guardians/models/guardians_repository.dart';
import '../features/overview/models/overview_data.dart';
import '../features/overview/models/overview_repository.dart';
import '../features/reports/models/reports_data.dart';
import '../features/reports/models/reports_repository.dart';
import '../features/students/models/student.dart';
import '../features/students/models/students_repository.dart';
import '../features/teachers/models/teacher.dart';
import '../features/teachers/models/teachers_repository.dart';
import '../features/timetable/models/timetable_data.dart';
import '../features/timetable/models/timetable_repository.dart';
import 'headmaster_api_service.dart';

/// Single data gateway for the Headmaster module. Every Headmaster controller
/// depends on this class (never on [HeadmasterApiService] or [ApiService]
/// directly).
///
/// Flip [_useMock] to `false` to route through the live [HeadmasterApiService];
/// while `true` the methods return the bundled per-feature mock fixtures.
class HeadmasterRepository {
  final HeadmasterApiService _api;

  final _dashboardMock = DashboardRepository();
  final _overviewMock = OverviewRepository();
  final _attendanceMock = AttendanceRepository();
  final _examsMock = ExamsRepository();
  final _feesMock = FeesRepository();
  final _classesMock = ClassesRepository();
  final _timetableMock = TimetableRepository();
  final _reportsMock = ReportsRepository();
  final _announcementsMock = AnnouncementsRepository();
  final _teachersMock = TeachersRepository();
  final _studentsMock = StudentsRepository();
  final _guardiansMock = GuardiansRepository();

  HeadmasterRepository({HeadmasterApiService? api})
      : _api = api ?? HeadmasterApiService();

  // Every Headmaster feature is wired to real `/schools/{id}/...` endpoints
  // (see the per-feature flags below and HeadmasterApiService for the mapping
  // + documented field losses). The mock fixtures are kept only as the
  // `false`-branch fallback for each flag.

  // Per-feature live flags: these map to real `/schools/{id}/...` endpoints
  // (with documented field losses — see HeadmasterApiService). Flip back to
  // false to revert any one feature to its bundled mock fixture.
  static const bool _liveDirectory = true; // teachers / students / guardians
  static const bool _liveClasses = true;
  static const bool _liveExams = true;
  static const bool _liveDashboard = true;
  static const bool _liveOverview = true;
  static const bool _liveAttendance = true;
  static const bool _liveFees = true;
  static const bool _liveTimetable = true;
  static const bool _liveReports = true;
  static const bool _liveAnnouncements = true;

  Future<ApiResponse<DashboardData>> loadDashboard() =>
      _liveDashboard ? _api.fetchDashboard() : _dashboardMock.load();

  Future<ApiResponse<OverviewData>> loadOverview() =>
      _liveOverview ? _api.fetchOverview() : _overviewMock.load();

  Future<ApiResponse<AttendanceData>> loadAttendance(AttendanceRange range) =>
      _liveAttendance
          ? _api.fetchAttendance(range)
          : _attendanceMock.load(range);

  Future<ApiResponse<ExamsData>> loadExams() =>
      _liveExams ? _api.fetchExams() : _examsMock.load();

  Future<ApiResponse<FeesData>> loadFees() =>
      _liveFees ? _api.fetchFees() : _feesMock.load();

  Future<ApiResponse<ClassDirectoryData>> loadClasses() =>
      _liveClasses ? _api.fetchClasses() : _classesMock.load();

  Future<ApiResponse<TimetableData>> loadTimetable() =>
      _liveTimetable ? _api.fetchTimetable() : _timetableMock.load();

  Future<ApiResponse<ReportsData>> loadReports() =>
      _liveReports ? _api.fetchReports() : _reportsMock.load();

  Future<ApiResponse<List<Announcement>>> loadAnnouncements({
    String filter = 'All Updates',
  }) =>
      _liveAnnouncements
          ? _api.fetchAnnouncements(filter: filter)
          : _announcementsMock.fetch(filter: filter);

  Future<ApiResponse<List<Teacher>>> loadTeachers({String query = ''}) =>
      _liveDirectory
          ? _api.fetchTeachers(query: query)
          : _teachersMock.fetch(query: query);

  Future<ApiResponse<List<Student>>> loadStudents({
    String query = '',
    String? grade,
    String? section,
  }) =>
      _liveDirectory
          ? _api.fetchStudents(query: query, grade: grade, section: section)
          : _studentsMock.fetch(query: query, grade: grade, section: section);

  Future<ApiResponse<List<Guardian>>> loadGuardians({String query = ''}) =>
      _liveDirectory
          ? _api.fetchGuardians(query: query)
          : _guardiansMock.fetch(query: query);
}
