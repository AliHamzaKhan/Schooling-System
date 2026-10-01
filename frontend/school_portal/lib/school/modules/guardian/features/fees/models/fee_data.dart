enum InvoiceStatus { paid, due, overdue }

class FeeInvoice {
  final String title; // "Term 2 Tuition"
  final String period; // "Oct 2025"
  final double amount;
  final String dueDate; // "Oct 31, 2025"
  final InvoiceStatus status;
  const FeeInvoice({
    required this.title,
    required this.period,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  factory FeeInvoice.fromJson(Map<String, dynamic> json) => FeeInvoice(
        title: json['title'] as String? ?? '',
        period: json['period'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        dueDate: json['due_date'] as String? ?? '',
        status: InvoiceStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => InvoiceStatus.due,
        ),
      );
}

class FeeData {
  final String currency; // empty: amounts are plain numbers
  final double outstanding;
  final double paidThisYear;
  final String? nextDueDate;
  final List<FeeInvoice> invoices;

  const FeeData({
    required this.currency,
    required this.outstanding,
    required this.paidThisYear,
    required this.nextDueDate,
    required this.invoices,
  });

  factory FeeData.fromJson(Map<String, dynamic> json) => FeeData(
        currency: json['currency'] as String? ?? '',
        outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0,
        paidThisYear: (json['paid_this_year'] as num?)?.toDouble() ?? 0,
        nextDueDate: json['next_due_date'] as String?,
        invoices: ((json['invoices'] as List?) ?? [])
            .map((e) => FeeInvoice.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
