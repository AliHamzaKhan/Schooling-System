import 'package:shared/shared.dart';

import '../features/announcements/models/announcement.dart';
import '../features/attendance/models/attendance_data.dart';
import '../features/classes/models/classes_data.dart';
import '../features/courses/models/admin_course_models.dart';
import '../features/dashboard/models/dashboard_data.dart';
import '../features/dashboard/models/subscription_status.dart';
import '../../../widgets/leave_review.dart';
import '../features/exams/models/exams_data.dart';
import '../features/exams/models/exam_category.dart';
import '../features/exams/models/exam_paper.dart';
import '../features/promotion/models/promotion_models.dart';
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
import '../features/transport/models/transport_models.dart';
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

  // ------------------------------ transport ---------------------------- #

  Future<ApiResponse<List<DriverRow>>> loadDrivers() => _api.fetchDrivers();

  Future<ApiResponse<DriverRow>> createDriver({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? licenseNo,
  }) =>
      _api.createDriver(
        email: email, password: password, fullName: fullName,
        phone: phone, licenseNo: licenseNo,
      );

  Future<ApiResponse<DriverRow>> updateDriver({
    required String driverId,
    String? licenseNo,
    String? phone,
    String? status,
  }) =>
      _api.updateDriver(
        driverId: driverId, licenseNo: licenseNo, phone: phone, status: status,
      );

  Future<ApiResponse<List<OnlineDriver>>> loadOnlineDrivers() =>
      _api.fetchOnlineDrivers();

  Future<ApiResponse<List<TransportRequestRow>>> loadTransportRequests({
    String? status,
  }) =>
      _api.fetchTransportRequests(status: status);

  Future<ApiResponse<dynamic>> approveTransportRequest(String id) =>
      _api.approveTransportRequest(id);

  Future<ApiResponse<dynamic>> rejectTransportRequest(String id, {String? reason}) =>
      _api.rejectTransportRequest(id, reason: reason);

  Future<ApiResponse<List<RouteOption>>> loadTransportRoutes() =>
      _api.fetchTransportRoutes();

  Future<ApiResponse<List<AssignmentRow>>> loadTransportAssignments() =>
      _api.fetchTransportAssignments();

  Future<ApiResponse<RouteOption>> createTransportRoute(String name) =>
      _api.createTransportRoute(name);

  Future<ApiResponse<dynamic>> assignTransportStudent({
    required String requestId,
    required String routeId,
    required String driverId,
  }) =>
      _api.assignTransportStudent(
        requestId: requestId, routeId: routeId, driverId: driverId,
      );

  Future<ApiResponse<List<TripRow>>> loadTransportTrips({String? status}) =>
      _api.fetchTransportTrips(status: status);

  Future<ApiResponse<SubscriptionStatus>> loadSubscriptionStatus() =>
      _api.fetchSubscriptionStatus();

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
    int? salaryDay,
  }) =>
      _api.updateSchoolProfile(
        name: name,
        logoUrl: logoUrl,
        uniformColor: uniformColor,
        feeDueDay: feeDueDay,
        salaryDay: salaryDay,
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

  // ── Exam categories + promotion ──
  Future<ApiResponse<List<ExamCategory>>> loadExamCategories() =>
      _api.fetchExamCategories();
  Future<ApiResponse<dynamic>> createExamCategory(
    String name, {
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _api.createExamCategory(name, startDate: startDate, endDate: endDate);
  Future<ApiResponse<dynamic>> updateExamCategory(
    String id, {
    String? name,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _api.updateExamCategory(id,
          name: name, startDate: startDate, endDate: endDate);
  Future<ApiResponse<dynamic>> announceExamCategory(String id) =>
      _api.announceExamCategory(id);
  Future<ApiResponse<dynamic>> deleteExamCategory(String id) =>
      _api.deleteExamCategory(id);

  // ── Exam timetable ──
  Future<ApiResponse<List<PickerOption>>> loadClassOptions() =>
      _api.fetchClassOptions();
  Future<ApiResponse<String>> createExam({
    required String classId,
    required String name,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _api.createExam(
        classId: classId,
        name: name,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
      );
  Future<ApiResponse<List<ExamPaper>>> loadExamPapers(String examId) =>
      _api.fetchExamPapers(examId);
  Future<ApiResponse<ExamPaper>> addExamPaper({
    required String examId,
    required String subjectId,
    required double maxMarks,
    required double passMarks,
    DateTime? examDate,
    String? examTime,
  }) =>
      _api.addExamPaper(
        examId: examId,
        subjectId: subjectId,
        maxMarks: maxMarks,
        passMarks: passMarks,
        examDate: examDate,
        examTime: examTime,
      );

  Future<ApiResponse<List<ExamListItem>>> loadExamList() =>
      _api.fetchExamList();
  Future<ApiResponse<List<PromotionPreviewRow>>> loadPromotionPreview(
          String examId) =>
      _api.fetchPromotionPreview(examId);
  Future<ApiResponse<dynamic>> applyPromotions({
    required String examId,
    required List<Map<String, dynamic>> items,
  }) =>
      _api.applyPromotions(examId: examId, items: items);

  // ── Courses (authoring) ──
  Future<ApiResponse<List<AdminCourse>>> loadCourses() => _api.fetchCourses();

  Future<ApiResponse<dynamic>> createCourse({
    required String title,
    String? subject,
    String? description,
    String? sectionId,
    String? subjectId,
  }) =>
      _api.createCourse(
        title: title,
        subject: subject,
        description: description,
        sectionId: sectionId,
        subjectId: subjectId,
      );

  Future<ApiResponse<List<AdminBook>>> loadBooks(String courseId) =>
      _api.fetchBooks(courseId);

  Future<ApiResponse<dynamic>> createBook({
    required String courseId,
    required String title,
    String? description,
  }) =>
      _api.createBook(courseId: courseId, title: title, description: description);

  Future<ApiResponse<List<AdminChapter>>> loadChapters(String bookId) =>
      _api.fetchChapters(bookId);

  Future<ApiResponse<dynamic>> createChapter({
    required String bookId,
    required String title,
    required String content,
  }) =>
      _api.createChapter(bookId: bookId, title: title, content: content);

  Future<ApiResponse<List<AdminNote>>> loadNotes(String courseId) =>
      _api.fetchNotes(courseId);

  Future<ApiResponse<dynamic>> createNote({
    required String courseId,
    required String title,
    required String content,
  }) =>
      _api.createNote(courseId: courseId, title: title, content: content);

  // ── School info (authoring) ──
  Future<ApiResponse<Map<String, dynamic>>> loadSchoolInfo() =>
      _api.fetchSchoolInfo();

  Future<ApiResponse<String>> uploadImage({
    required String folder,
    String? filePath,
    List<int>? bytes,
    String filename = 'image.jpg',
    String contentType = 'image/jpeg',
  }) =>
      _api.uploadImage(
        folder: folder,
        filePath: filePath,
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      );

  Future<ApiResponse<dynamic>> saveSchoolInfo({
    String? about,
    List<Map<String, dynamic>>? achievements,
    String? uniformImageUrl,
  }) =>
      _api.saveSchoolInfo(
        about: about,
        achievements: achievements,
        uniformImageUrl: uniformImageUrl,
      );

  // ── Leave review ──
  Future<ApiResponse<List<LeaveReviewItem>>> loadLeaveReview() =>
      _api.fetchLeaveReview();

  Future<ApiResponse<dynamic>> reviewLeave({
    required String leaveId,
    required bool approve,
    String? note,
  }) =>
      _api.reviewLeave(leaveId: leaveId, approve: approve, note: note);
}
