import 'package:shared/shared.dart';

import '../features/announcements/models/announcement.dart';
import '../features/attendance/models/attendance_data.dart';
import '../features/classes/models/classes_data.dart';
import '../features/dashboard/models/dashboard_data.dart';
import '../features/exams/models/exams_data.dart';
import '../features/attendance/models/teacher_attendance_day.dart';
import '../features/timetable/models/timetable_slot.dart';
import '../features/fees/models/fees_data.dart';
import '../features/fees/models/student_fee_snapshot.dart';
import '../features/guardians/models/guardian.dart';
import '../features/overview/models/overview_data.dart';
import '../features/reports/models/reports_data.dart';
import '../features/salary/models/salary_models.dart';
import '../features/settings/models/school_profile.dart';
import '../features/students/models/student.dart';
import '../features/teachers/models/teacher.dart';
import '../features/timetable/models/timetable_data.dart';
import 'headmaster_api_service.dart';

/// Single data gateway for the Headmaster module. Every Headmaster controller
/// depends on this class (never on [HeadmasterApiService] or [ApiService]
/// directly).
///
/// Every method reads/writes live backend data through [HeadmasterApiService].
class HeadmasterRepository {
  final HeadmasterApiService _api;

  HeadmasterRepository({HeadmasterApiService? api})
      : _api = api ?? HeadmasterApiService();

  Future<ApiResponse<DashboardData>> loadDashboard() => _api.fetchDashboard();

  Future<ApiResponse<OverviewData>> loadOverview() => _api.fetchOverview();

  Future<ApiResponse<AttendanceData>> loadAttendance(AttendanceRange range) =>
      _api.fetchAttendance(range);

  Future<ApiResponse<ExamsData>> loadExams() => _api.fetchExams();

  Future<ApiResponse<FeesData>> loadFees() => _api.fetchFees();

  Future<ApiResponse<ClassDirectoryData>> loadClasses() => _api.fetchClasses();

  Future<ApiResponse<TimetableData>> loadTimetable() => _api.fetchTimetable();

  Future<ApiResponse<ReportsData>> loadReports() => _api.fetchReports();

  Future<ApiResponse<List<Announcement>>> loadAnnouncements({
    String filter = 'All Updates',
  }) =>
      _api.fetchAnnouncements(filter: filter);

  Future<ApiResponse<List<Teacher>>> loadTeachers({String query = ''}) =>
      _api.fetchTeachers(query: query);

  Future<ApiResponse<List<Student>>> loadStudents({
    String query = '',
    String? grade,
    String? section,
  }) =>
      _api.fetchStudents(query: query, grade: grade, section: section);

  Future<ApiResponse<List<Guardian>>> loadGuardians({String query = ''}) =>
      _api.fetchGuardians(query: query);

  // ── Create actions (always live) ──
  Future<ApiResponse<dynamic>> createClass({
    required String name,
    int? level,
    String? roomNo,
  }) =>
      _api.createClass(name: name, level: level, roomNo: roomNo);

  Future<ApiResponse<dynamic>> createSection({
    required String classId,
    required String name,
    String? roomNo,
  }) =>
      _api.createSection(classId: classId, name: name, roomNo: roomNo);

  Future<ApiResponse<dynamic>> updateClass({
    required String classId,
    required String name,
  }) =>
      _api.updateClass(classId: classId, name: name);

  Future<ApiResponse<dynamic>> deleteClass(String classId) =>
      _api.deleteClass(classId);

  Future<ApiResponse<dynamic>> linkChild({
    required String guardianId,
    required String studentId,
  }) =>
      _api.linkChild(guardianId: guardianId, studentId: studentId);

  Future<ApiResponse<dynamic>> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    Map<String, dynamic>? profileMetadata,
  }) =>
      _api.createUser(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
        profileMetadata: profileMetadata,
      );

  Future<ApiResponse<String>> uploadAvatar({
    String? filePath,
    List<int>? bytes,
    String filename = 'avatar.jpg',
    String contentType = 'image/jpeg',
  }) =>
      _api.uploadAvatar(
        filePath: filePath,
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      );

  Future<ApiResponse<dynamic>> enrollStudent({
    required String sectionId,
    required String studentId,
  }) =>
      _api.enrollStudent(sectionId: sectionId, studentId: studentId);

  Future<ApiResponse<StudentFeePage>> searchStudentFees({
    String query = '',
    int limit = 20,
    int offset = 0,
    String? classId,
    String? feeStatus,
  }) =>
      _api.searchStudentFees(
        query: query,
        limit: limit,
        offset: offset,
        classId: classId,
        feeStatus: feeStatus,
      );

  Future<ApiResponse<List<SubjectOption>>> loadSubjectOptions() =>
      _api.fetchSubjectOptions();

  Future<ApiResponse<List<TimetableSlot>>> loadTimetableSlots({
    String? sectionId,
  }) =>
      _api.fetchTimetableSlots(sectionId: sectionId);

  Future<ApiResponse<TimetableSlot>> createTimetableSlot({
    required String sectionId,
    required String subjectId,
    String? teacherId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) =>
      _api.createTimetableSlot(
        sectionId: sectionId,
        subjectId: subjectId,
        teacherId: teacherId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        room: room,
      );

  Future<ApiResponse<TimetableSlot>> updateTimetableSlot({
    required String slotId,
    String? subjectId,
    String? teacherId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? room,
  }) =>
      _api.updateTimetableSlot(
        slotId: slotId,
        subjectId: subjectId,
        teacherId: teacherId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        room: room,
      );

  Future<ApiResponse<dynamic>> deleteTimetableSlot(String slotId) =>
      _api.deleteTimetableSlot(slotId);

  Future<ApiResponse<TeacherAttendanceDay>> loadTeacherAttendance({
    required DateTime date,
    String? status,
  }) =>
      _api.fetchTeacherAttendance(date: date, status: status);

  Future<ApiResponse<dynamic>> markTeacherAttendance({
    required DateTime date,
    required List<Map<String, dynamic>> entries,
  }) =>
      _api.markTeacherAttendance(date: date, entries: entries);

  Future<ApiResponse<List<Map<String, dynamic>>>> loadOverdueInvoices({
    String? classId,
    int limit = 50,
    int offset = 0,
  }) =>
      _api.fetchOverdueInvoices(classId: classId, limit: limit, offset: offset);

  Future<ApiResponse<dynamic>> recordPayment({
    required String invoiceId,
    required double amount,
    required String method,
    DateTime? paidOn,
  }) =>
      _api.recordPayment(
        invoiceId: invoiceId,
        amount: amount,
        method: method,
        paidOn: paidOn,
      );

  /// Compose a school-wide (or audience-scoped) announcement broadcast.
  Future<ApiResponse<dynamic>> createBroadcast({
    required String body,
    String? title,
    String audienceType = 'entire_school',
  }) =>
      _api.createBroadcast(
          body: body, title: title, audienceType: audienceType);

  /// Publish computed results for a single exam.
  Future<ApiResponse<dynamic>> publishExamResults(String examId) =>
      _api.publishExamResults(examId);

  Future<ApiResponse<List<PickerOption>>> loadSectionOptions() =>
      _api.fetchSectionOptions();

  Future<ApiResponse<List<PickerOption>>> loadStudentOptions() =>
      _api.fetchStudentOptions();

  // ── School settings ──
  Future<ApiResponse<SchoolProfile>> loadSchoolProfile() =>
      _api.fetchSchoolProfile();

  Future<ApiResponse<SchoolProfile>> saveSchoolProfile({
    required String name,
    String? logoUrl,
    String? uniformColor,
    int? feeDueDay,
  }) =>
      _api.updateSchoolProfile(
        name: name,
        logoUrl: logoUrl,
        uniformColor: uniformColor,
        feeDueDay: feeDueDay,
      );

  // ── Salary / HR ──
  Future<ApiResponse<List<SalaryStaff>>> loadSalaryStaff() =>
      _api.fetchSalaryStaff();

  Future<ApiResponse<List<PayslipRow>>> loadPayslips() => _api.fetchPayslips();

  Future<ApiResponse<dynamic>> createStaffProfile({
    required String userId,
    required String designation,
    required double baseSalary,
  }) =>
      _api.createStaffProfile(
          userId: userId, designation: designation, baseSalary: baseSalary);

  Future<ApiResponse<dynamic>> updateStaffProfile({
    required String profileId,
    required String designation,
    required double baseSalary,
  }) =>
      _api.updateStaffProfile(
          profileId: profileId, designation: designation, baseSalary: baseSalary);

  Future<ApiResponse<PayslipRow>> generatePayslip({
    required String profileId,
    required int month,
    required int year,
    double allowances = 0,
    double deductions = 0,
    bool deductAbsences = false,
  }) =>
      _api.generatePayslip(
        profileId: profileId,
        month: month,
        year: year,
        allowances: allowances,
        deductions: deductions,
        deductAbsences: deductAbsences,
      );

  Future<ApiResponse<MonthlyAttendanceSummary>> loadTeacherMonthlyAttendance({
    required String teacherId,
    required int month,
    required int year,
  }) =>
      _api.fetchTeacherMonthlyAttendance(
          teacherId: teacherId, month: month, year: year);

  Future<ApiResponse<dynamic>> markPayslipPaid(String payslipId) =>
      _api.markPayslipPaid(payslipId);
}
