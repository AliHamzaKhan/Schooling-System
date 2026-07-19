/// A teacher and their salary/staff-profile status for the Salary screen.
class SalaryStaff {
  final String userId;
  final String name;
  final String email;
  final String? profileId; // null == no staff profile / salary set up yet
  final String? designation;
  final double? baseSalary;

  const SalaryStaff({
    required this.userId,
    required this.name,
    required this.email,
    this.profileId,
    this.designation,
    this.baseSalary,
  });

  bool get hasSalary => profileId != null;
}

/// A generated payslip row, including the attendance snapshot captured when it
/// was generated (used by the payslip PDF).
class PayslipRow {
  final String id;
  final String staffProfileId;
  final int month;
  final int year;
  final double gross;
  final double allowances;
  final double deductions;
  final double net;
  final String status; // e.g. "pending" / "paid"
  final String? paidOn;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int leaveDays;
  final double absenceDeduction;

  const PayslipRow({
    required this.id,
    required this.staffProfileId,
    required this.month,
    required this.year,
    required this.gross,
    required this.net,
    required this.status,
    this.allowances = 0,
    this.deductions = 0,
    this.paidOn,
    this.presentDays = 0,
    this.absentDays = 0,
    this.lateDays = 0,
    this.leaveDays = 0,
    this.absenceDeduction = 0,
  });

  factory PayslipRow.fromJson(Map<String, dynamic> json) => PayslipRow(
        id: '${json['id']}',
        staffProfileId: '${json['staff_profile_id']}',
        month: (json['period_month'] as num?)?.toInt() ?? 0,
        year: (json['period_year'] as num?)?.toInt() ?? 0,
        gross: (json['gross'] as num?)?.toDouble() ?? 0,
        allowances: (json['allowances'] as num?)?.toDouble() ?? 0,
        deductions: (json['deductions'] as num?)?.toDouble() ?? 0,
        net: (json['net'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'pending',
        paidOn: json['paid_on'] as String?,
        presentDays: (json['present_days'] as num?)?.toInt() ?? 0,
        absentDays: (json['absent_days'] as num?)?.toInt() ?? 0,
        lateDays: (json['late_days'] as num?)?.toInt() ?? 0,
        leaveDays: (json['leave_days'] as num?)?.toInt() ?? 0,
        absenceDeduction:
            (json['absence_deduction'] as num?)?.toDouble() ?? 0,
      );
}

/// Monthly attendance roll-up shown on the Generate Payslip screen.
class MonthlyAttendanceSummary {
  final int month;
  final int year;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int leaveDays;
  final int markedDays;
  final double projectedAbsenceDeduction;

  const MonthlyAttendanceSummary({
    required this.month,
    required this.year,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.leaveDays,
    required this.markedDays,
    required this.projectedAbsenceDeduction,
  });

  factory MonthlyAttendanceSummary.fromJson(Map<String, dynamic> json) =>
      MonthlyAttendanceSummary(
        month: (json['period_month'] as num?)?.toInt() ?? 0,
        year: (json['period_year'] as num?)?.toInt() ?? 0,
        presentDays: (json['present_days'] as num?)?.toInt() ?? 0,
        absentDays: (json['absent_days'] as num?)?.toInt() ?? 0,
        lateDays: (json['late_days'] as num?)?.toInt() ?? 0,
        leaveDays: (json['leave_days'] as num?)?.toInt() ?? 0,
        markedDays: (json['marked_days'] as num?)?.toInt() ?? 0,
        projectedAbsenceDeduction:
            (json['projected_absence_deduction'] as num?)?.toDouble() ?? 0,
      );
}
