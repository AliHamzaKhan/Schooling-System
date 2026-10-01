import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/report_card_data.dart';

/// Builds and shares the report card that is on screen, from published
/// results only.
class ReportCardPdf {
  const ReportCardPdf._();

  static Future<void> share({
    required String childName,
    required String grade,
    required ReportCardData data,
  }) async {
    final bytes = await build(childName: childName, grade: grade, data: data);
    final safe = '$childName-${data.termLabel}'
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-');
    await Printing.sharePdf(bytes: bytes, filename: 'report-card-$safe.pdf');
  }

  static Future<Uint8List> build({
    required String childName,
    required String grade,
    required ReportCardData data,
  }) async {
    final doc = pw.Document(title: 'Report card — $childName');
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Report card',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(childName, style: const pw.TextStyle(fontSize: 14)),
            if (grade.isNotEmpty) pw.Text(grade),
            pw.SizedBox(height: 4),
            pw.Text(
              '${data.termLabel} · Overall ${data.averagePercent.round()}%'
              '${data.overallGrade.isEmpty ? '' : ' (${data.overallGrade})'}',
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: const ['Subject', 'Grade', 'Percent'],
              data: [
                for (final s in data.subjects)
                  [s.subject, s.grade, '${s.percent}%'],
              ],
            ),
            if (data.gpaTrend.length > 1) ...[
              pw.SizedBox(height: 16),
              pw.Text('Results by exam',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              for (final p in data.gpaTrend)
                pw.Text('${p.label}: ${p.percent.round()}%'),
            ],
            pw.Spacer(),
            pw.Text(
              'Generated from results published by the school.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
