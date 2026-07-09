/// A single question added through the Create Exam "question builder".
enum ExamQuestionType { mcq, trueFalse, essay }

extension ExamQuestionTypeX on ExamQuestionType {
  String get label => switch (this) {
        ExamQuestionType.mcq => 'Multiple Choice',
        ExamQuestionType.trueFalse => 'True / False',
        ExamQuestionType.essay => 'Essay',
      };

  String get apiValue => switch (this) {
        ExamQuestionType.mcq => 'mcq',
        ExamQuestionType.trueFalse => 'true_false',
        ExamQuestionType.essay => 'essay',
      };
}

class ExamQuestion {
  final ExamQuestionType type;
  final String prompt;

  /// Choice labels for [ExamQuestionType.mcq] (empty for other types).
  final List<String> options;

  /// Index into [options] (mcq) or 0=True / 1=False (trueFalse); null for essay.
  final int? correctIndex;

  const ExamQuestion({
    required this.type,
    required this.prompt,
    this.options = const [],
    this.correctIndex,
  });

  Map<String, dynamic> toJson() => {
        'type': type.apiValue,
        'prompt': prompt,
        if (options.isNotEmpty) 'options': options,
        if (correctIndex != null) 'correct_index': correctIndex,
      };
}
