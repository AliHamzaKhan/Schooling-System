import 'package:flutter_test/flutter_test.dart';
import 'package:school_portal/school/modules/guardian/features/report_card/models/report_card_data.dart';
import 'package:school_portal/school/modules/guardian/features/report_card/utils/report_card_pdf.dart';

void main() {
  test('report card PDF is generated from the published results on screen', () async {
    final bytes = await ReportCardPdf.build(
      childName: 'Synthetic Student',
      grade: 'Grade 1 — Section A',
      data: const ReportCardData(
        termLabel: 'Midterm',
        averagePercent: 82,
        overallGrade: 'A',
        subjects: [ReportSubject(subject: 'Mathematics', grade: 'A', percent: 82)],
        gpaTrend: [
          GpaTrendPoint(label: 'Quiz week', percent: 70),
          GpaTrendPoint(label: 'Midterm', percent: 82),
        ],
      ),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(500));
  });
}
