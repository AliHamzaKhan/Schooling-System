// Headmaster promotion-flow models. Mirror the backend `promotion` payloads.

/// Per-student outcome the headmaster can assign when promoting from an exam.
/// `promoted` moves the student to a chosen next section; `reexam` flags a
/// failed student for re-examination; `retained` keeps them; `graduated` exits.
enum PromotionOutcome { promoted, retained, reexam, graduated }

extension PromotionOutcomeX on PromotionOutcome {
  String get wire => switch (this) {
        PromotionOutcome.promoted => 'promoted',
        PromotionOutcome.retained => 'retained',
        PromotionOutcome.reexam => 'reexam',
        PromotionOutcome.graduated => 'graduated',
      };

  String get label => switch (this) {
        PromotionOutcome.promoted => 'Promote',
        PromotionOutcome.retained => 'Retain',
        PromotionOutcome.reexam => 'Re-exam',
        PromotionOutcome.graduated => 'Graduate',
      };

  static PromotionOutcome fromWire(String? s) => switch (s) {
        'promoted' => PromotionOutcome.promoted,
        'reexam' => PromotionOutcome.reexam,
        'graduated' => PromotionOutcome.graduated,
        _ => PromotionOutcome.retained,
      };
}

/// One row of the promotion preview for a published exam.
class PromotionPreviewRow {
  final String studentId;
  final String? studentName;
  final String? currentSectionId;
  final String? currentSectionLabel;
  final double? percentage;
  final String? resultStatus; // 'pass' | 'fail'
  final PromotionOutcome suggestedOutcome;

  const PromotionPreviewRow({
    required this.studentId,
    required this.suggestedOutcome,
    this.studentName,
    this.currentSectionId,
    this.currentSectionLabel,
    this.percentage,
    this.resultStatus,
  });

  bool get passed => resultStatus == 'pass';

  factory PromotionPreviewRow.fromJson(Map<String, dynamic> j) =>
      PromotionPreviewRow(
        studentId: '${j['student_id']}',
        studentName: j['student_name'] as String?,
        currentSectionId: j['current_section_id'] as String?,
        currentSectionLabel: j['current_section_label'] as String?,
        percentage: (j['percentage'] as num?)?.toDouble(),
        resultStatus: (j['result_status'] as String?)?.toLowerCase(),
        suggestedOutcome:
            PromotionOutcomeX.fromWire(j['suggested_outcome'] as String?),
      );
}
