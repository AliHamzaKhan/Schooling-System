import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../settings/models/school_profile.dart';
import '../controller/salary_controller.dart';
import '../models/salary_models.dart';
import 'money.dart';

/// Builds and shares a payslip PDF headed with the school's name and logo.
///
/// The attendance block is rendered from the snapshot stored on the payslip at
/// generation time, so a reprint always matches what was actually paid — even
/// if attendance is edited afterwards.
class PayslipPdf {
  const PayslipPdf._();

  static Future<void> share({
    required PayslipRow payslip,
    required SalaryStaff staff,
    required SchoolProfile? school,
  }) async {
    final bytes = await build(
      payslip: payslip,
      staff: staff,
      school: school,
    );
    final period =
        '${SalaryController.monthNames[(payslip.month - 1).clamp(0, 11)]}-${payslip.year}';
    final safeName = staff.name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-');
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'payslip-$safeName-$period.pdf',
    );
  }

  static Future<Uint8List> build({
    required PayslipRow payslip,
    required SalaryStaff staff,
    required SchoolProfile? school,
  }) async {
    final logo = await _loadLogo(school?.logoUrl);
    final doc = pw.Document();
    final monthName =
        SalaryController.monthNames[(payslip.month - 1).clamp(0, 11)];
    final generatedOn = DateTime.now();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(school, logo, generatedOn),
            pw.SizedBox(height: 24),
            pw.Text(
              'PAYSLIP — $monthName ${payslip.year}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),
            _employeeBlock(staff, payslip),
            pw.SizedBox(height: 20),
            _attendanceBlock(payslip),
            pw.SizedBox(height: 20),
            _earningsTable(payslip),
            pw.SizedBox(height: 24),
            _netBanner(payslip),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey400),
            pw.Text(
              'This is a computer-generated payslip and does not require a '
              'signature.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  // ------------------------------ sections ------------------------------ //

  static pw.Widget _header(
      SchoolProfile? school, Uint8List? logo, DateTime generatedOn) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null) ...[
          pw.Container(
            width: 56,
            height: 56,
            child: pw.Image(pw.MemoryImage(logo), fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(width: 12),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                school?.name ?? 'School',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Generated ${_fmtDate(generatedOn)}',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _employeeBlock(SalaryStaff staff, PayslipRow payslip) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: _kv('Employee', staff.name),
          ),
          pw.Expanded(
            child: _kv('Designation', staff.designation ?? 'Teacher'),
          ),
          pw.Expanded(
            child: _kv('Status', payslip.status.toUpperCase()),
          ),
        ],
      ),
    );
  }

  static pw.Widget _attendanceBlock(PayslipRow p) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('ATTENDANCE',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            _attCell('Present', p.presentDays),
            _attCell('Absent', p.absentDays),
            _attCell('Late', p.lateDays),
            _attCell('Leave', p.leaveDays),
          ],
        ),
      ],
    );
  }

  static pw.Widget _attCell(String label, int value) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 6),
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          children: [
            pw.Text('$value',
                style: pw.TextStyle(
                    fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.Text(label,
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey700)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _earningsTable(PayslipRow p) {
    final base = p.gross - p.allowances;
    final otherDeductions = p.deductions - p.absenceDeduction;
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1.4),
      },
      children: [
        _tr('Description', 'Amount', header: true),
        _tr('Base salary', money(base)),
        _tr('Allowances', money(p.allowances)),
        _tr('Gross', money(p.gross), bold: true),
        if (p.absenceDeduction > 0)
          _tr('Absence deduction (${p.absentDays} day'
              '${p.absentDays == 1 ? "" : "s"})',
              '- ${money(p.absenceDeduction)}'),
        if (otherDeductions > 0)
          _tr('Other deductions', '- ${money(otherDeductions)}'),
        _tr('Total deductions', '- ${money(p.deductions)}', bold: true),
      ],
    );
  }

  static pw.TableRow _tr(String label, String value,
      {bool header = false, bool bold = false}) {
    final style = pw.TextStyle(
      fontSize: header ? 10 : 11,
      fontWeight:
          (header || bold) ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.TableRow(
      decoration: header
          ? const pw.BoxDecoration(color: PdfColors.grey200)
          : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: style),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value,
              style: style, textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }

  static pw.Widget _netBanner(PayslipRow p) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey900,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('NET PAY',
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold)),
          pw.Text(money(p.net),
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _kv(String k, String v) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(k.toUpperCase(),
            style:
                const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(v, style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }

  // ------------------------------- helpers ------------------------------ //

  /// Best-effort logo fetch — a broken or missing URL just omits the logo
  /// rather than failing the whole export.
  static Future<Uint8List?> _loadLogo(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    try {
      final res = await http
          .get(Uri.parse(url.trim()))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return res.bodyBytes;
      }
    } catch (_) {
      // Ignore — render without a logo.
    }
    return null;
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
