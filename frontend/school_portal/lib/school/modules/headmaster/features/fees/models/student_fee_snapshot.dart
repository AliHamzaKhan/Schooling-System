/// One invoice line under a [StudentFeeSnapshot].
class InvoiceSummary {
  final String id;
  final String title;
  final double amount;
  final double amountPaid;
  final double balance;
  final String status; // "unpaid" | "partial" | "paid"
  final DateTime dueDate;

  const InvoiceSummary({
    required this.id,
    required this.title,
    required this.amount,
    required this.amountPaid,
    required this.balance,
    required this.status,
    required this.dueDate,
  });

  bool get isOverdue =>
      status != 'paid' && dueDate.isBefore(DateTime.now());

  factory InvoiceSummary.fromJson(Map<String, dynamic> json) => InvoiceSummary(
        id: '${json['id']}',
        title: json['title'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'unpaid',
        dueDate: DateTime.tryParse(json['due_date'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// A student and their live fee position, returned by the Record Payment
/// search endpoint.
class StudentFeeSnapshot {
  final String studentId;
  final String fullName;
  final String? fatherName;
  final String? classId;
  final String? className;
  final String? sectionId;
  final String? sectionName;
  final int? grade;
  final double outstandingTotal;
  final double paidTotal;
  final bool hasOverdue;
  final List<InvoiceSummary> invoices;

  const StudentFeeSnapshot({
    required this.studentId,
    required this.fullName,
    required this.outstandingTotal,
    required this.paidTotal,
    required this.hasOverdue,
    required this.invoices,
    this.fatherName,
    this.classId,
    this.className,
    this.sectionId,
    this.sectionName,
    this.grade,
  });

  factory StudentFeeSnapshot.fromJson(Map<String, dynamic> json) =>
      StudentFeeSnapshot(
        studentId: '${json['student_id']}',
        fullName: json['full_name'] as String? ?? '',
        fatherName: json['father_name'] as String?,
        classId: json['class_id']?.toString(),
        className: json['class_name'] as String?,
        sectionId: json['section_id']?.toString(),
        sectionName: json['section_name'] as String?,
        grade: (json['grade'] as num?)?.toInt(),
        outstandingTotal:
            (json['outstanding_total'] as num?)?.toDouble() ?? 0,
        paidTotal: (json['paid_total'] as num?)?.toDouble() ?? 0,
        hasOverdue: json['has_overdue'] as bool? ?? false,
        invoices: ((json['invoices'] as List?) ?? [])
            .map((e) => InvoiceSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Combined status: 'overdue' > 'unpaid'/'partial' > 'paid' > 'no dues'.
  String get displayStatus {
    if (invoices.isEmpty) return 'no dues';
    if (hasOverdue) return 'overdue';
    if (outstandingTotal > 0) return 'pending';
    return 'paid';
  }
}

/// Paginated envelope returned by `/fees/students`.
class StudentFeePage {
  final int total;
  final List<StudentFeeSnapshot> items;
  const StudentFeePage({required this.total, required this.items});

  factory StudentFeePage.fromJson(Map<String, dynamic> json) => StudentFeePage(
        total: (json['total'] as num?)?.toInt() ?? 0,
        items: ((json['items'] as List?) ?? [])
            .map((e) =>
                StudentFeeSnapshot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
