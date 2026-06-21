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

  static const bool _useMock = true;

  Future<ApiResponse<DashboardData>> loadDashboard() =>
      _useMock ? _dashboardMock.load() : _api.fetchDashboard();

  Future<ApiResponse<OverviewData>> loadOverview() =>
      _useMock ? _overviewMock.load() : _api.fetchOverview();

  Future<ApiResponse<AttendanceData>> loadAttendance(AttendanceRange range) =>
      _useMock ? _attendanceMock.load(range) : _api.fetchAttendance(range);

  Future<ApiResponse<ExamsData>> loadExams() =>
      _useMock ? _examsMock.load() : _api.fetchExams();

  Future<ApiResponse<FeesData>> loadFees() =>
      _useMock ? _feesMock.load() : _api.fetchFees();

  Future<ApiResponse<ClassDirectoryData>> loadClasses() =>
      _useMock ? _classesMock.load() : _api.fetchClasses();

  Future<ApiResponse<TimetableData>> loadTimetable() =>
      _useMock ? _timetableMock.load() : _api.fetchTimetable();

  Future<ApiResponse<ReportsData>> loadReports() =>
      _useMock ? _reportsMock.load() : _api.fetchReports();

  Future<ApiResponse<List<Announcement>>> loadAnnouncements({
    String filter = 'All Updates',
  }) =>
      _useMock
          ? _announcementsMock.fetch(filter: filter)
          : _api.fetchAnnouncements(filter: filter);

  Future<ApiResponse<List<Teacher>>> loadTeachers({String query = ''}) =>
      _useMock
          ? _teachersMock.fetch(query: query)
          : _api.fetchTeachers(query: query);

  Future<ApiResponse<List<Student>>> loadStudents({
    String query = '',
    String? grade,
    String? section,
  }) =>
      _useMock
          ? _studentsMock.fetch(query: query, grade: grade, section: section)
          : _api.fetchStudents(query: query, grade: grade, section: section);

  Future<ApiResponse<List<Guardian>>> loadGuardians({String query = ''}) =>
      _useMock
          ? _guardiansMock.fetch(query: query)
          : _api.fetchGuardians(query: query);
}
