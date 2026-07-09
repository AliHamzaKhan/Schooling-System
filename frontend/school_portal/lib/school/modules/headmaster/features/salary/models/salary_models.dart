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

/// A generated payslip row.
class PayslipRow {
  final String id;
  final String staffProfileId;
  final int month;
  final int year;
  final double gross;
  final double net;
  final String status; // e.g. "pending" / "paid"
  final String? paidOn;

  const PayslipRow({
    required this.id,
    required this.staffProfileId,
    required this.month,
    required this.year,
    required this.gross,
    required this.net,
    required this.status,
    this.paidOn,
  });

  factory PayslipRow.fromJson(Map<String, dynamic> json) => PayslipRow(
        id: '${json['id']}',
        staffProfileId: '${json['staff_profile_id']}',
        month: (json['period_month'] as num?)?.toInt() ?? 0,
        year: (json['period_year'] as num?)?.toInt() ?? 0,
        gross: (json['gross'] as num?)?.toDouble() ?? 0,
        net: (json['net'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'pending',
        paidOn: json['paid_on'] as String?,
      );
}
