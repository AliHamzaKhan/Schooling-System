import 'package:shared/shared.dart';

import 'fee_data.dart';

class FeeRepository {
  Future<ApiResponse<FeeData>> load(String childId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ApiResponse.ok(_byChild[childId] ?? _byChild['c1']!);
  }

  static const _byChild = <String, FeeData>{
    'c1': FeeData(
      currency: r'$',
      outstanding: 0,
      paidThisYear: 4200,
      nextDueDate: 'Jan 15, 2026',
      invoices: [
        FeeInvoice(
            title: 'Term 1 Tuition',
            period: 'Aug 2025',
            amount: 2100,
            dueDate: 'Aug 31, 2025',
            status: InvoiceStatus.paid),
        FeeInvoice(
            title: 'Term 2 Tuition',
            period: 'Oct 2025',
            amount: 2100,
            dueDate: 'Oct 31, 2025',
            status: InvoiceStatus.paid),
      ],
    ),
    'c2': FeeData(
      currency: r'$',
      outstanding: 1850,
      paidThisYear: 1700,
      nextDueDate: 'Oct 24, 2025',
      invoices: [
        FeeInvoice(
            title: 'Term 1 Tuition',
            period: 'Aug 2025',
            amount: 1700,
            dueDate: 'Aug 31, 2025',
            status: InvoiceStatus.paid),
        FeeInvoice(
            title: 'Term 2 Tuition',
            period: 'Oct 2025',
            amount: 1700,
            dueDate: 'Oct 24, 2025',
            status: InvoiceStatus.due),
        FeeInvoice(
            title: 'Activity Fee',
            period: 'Sep 2025',
            amount: 150,
            dueDate: 'Sep 30, 2025',
            status: InvoiceStatus.overdue),
      ],
    ),
  };
}
