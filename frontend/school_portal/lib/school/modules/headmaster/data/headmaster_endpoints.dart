/// Central registry of every backend path used by the Headmaster module. No
/// endpoint string is hardcoded inside the API service or repository.
class HeadmasterEndpoints {
  HeadmasterEndpoints._();

  static const _base = '/headmaster';

  static const dashboard = '$_base/dashboard';
  static const overview = '$_base/overview';
  static const attendance = '$_base/attendance';
  static const exams = '$_base/exams';
  static const fees = '$_base/fees';
  static const classes = '$_base/classes';
  static const timetable = '$_base/timetable';
  static const reports = '$_base/reports';
  static const announcements = '$_base/announcements';
  static const teachers = '$_base/teachers';
  static const students = '$_base/students';
  static const guardians = '$_base/guardians';

  // ── Live, school-scoped backend paths (`/schools/{school_id}/...`) ──
  // Used by the wired features (people directories, classes, exams). The
  // aggregate paths above remain for the still-mock dashboard/overview/etc.
  static String users(String schoolId) => '/schools/$schoolId/users';
  static String uploads(String schoolId) => '/schools/$schoolId/uploads';
  static String academicClasses(String schoolId) =>
      '/schools/$schoolId/academic/classes';
  static String examsList(String schoolId) => '/schools/$schoolId/exams';

  // Aggregate report endpoints (read-only) now backed by the API.
  static String school(String schoolId) => '/schools/$schoolId';
  static String reportsOverview(String schoolId) =>
      '/schools/$schoolId/reports/overview';
  static String reportsAttendance(String schoolId) =>
      '/schools/$schoolId/reports/attendance';
  static String reportsAcademic(String schoolId) =>
      '/schools/$schoolId/reports/academic';
  static String reportsFinance(String schoolId) =>
      '/schools/$schoolId/reports/finance';
  static String reportsEnrollment(String schoolId) =>
      '/schools/$schoolId/reports/enrollment';
  static String feesInvoices(String schoolId) =>
      '/schools/$schoolId/fees/invoices';
  static String feesStudents(String schoolId) =>
      '/schools/$schoolId/fees/students';
  static String academicTimetable(String schoolId) =>
      '/schools/$schoolId/academic/timetable';
  static String academicSubjects(String schoolId) =>
      '/schools/$schoolId/academic/subjects';
  static String timetableSlot(String schoolId, String slotId) =>
      '/schools/$schoolId/academic/timetable/$slotId';
  static String broadcasts(String schoolId) =>
      '/schools/$schoolId/communication/broadcasts';

  // ── Write paths (create actions) ──
  static String classSections(String schoolId, String classId) =>
      '/schools/$schoolId/academic/classes/$classId/sections';
  static String classDetail(String schoolId, String classId) =>
      '/schools/$schoolId/academic/classes/$classId';
  static String sectionStudents(String schoolId, String sectionId) =>
      '/schools/$schoolId/sections/$sectionId/students';
  static String invoicePayments(String schoolId, String invoiceId) =>
      '/schools/$schoolId/fees/invoices/$invoiceId/payments';
  static String examResultsPublish(String schoolId, String examId) =>
      '/schools/$schoolId/exams/$examId/results/publish';
  static String studentReport(String schoolId, String studentId) =>
      '/schools/$schoolId/reports/students/$studentId';
  static String meetings(String schoolId) => '/schools/$schoolId/meetings';
  static String guardianChildren(String schoolId, String guardianId) =>
      '/schools/$schoolId/guardians/$guardianId/children';
  static String schoolProfile(String schoolId) =>
      '/schools/$schoolId/profile';

  // ── HR / payroll (salary management) ──
  static String hrStaff(String schoolId) => '/schools/$schoolId/hr/staff';
  static String hrTeacherAttendance(String schoolId) =>
      '/schools/$schoolId/hr/attendance';
  static String hrTeacherAttendanceSummary(String schoolId, String teacherId) =>
      '/schools/$schoolId/hr/teachers/$teacherId/attendance-summary';
  static String hrStaffDetail(String schoolId, String profileId) =>
      '/schools/$schoolId/hr/staff/$profileId';
  static String hrStaffPayslips(String schoolId, String profileId) =>
      '/schools/$schoolId/hr/staff/$profileId/payslips';
  static String hrPayslips(String schoolId) => '/schools/$schoolId/hr/payslips';
  static String hrPayslipPay(String schoolId, String payslipId) =>
      '/schools/$schoolId/hr/payslips/$payslipId/pay';
}
