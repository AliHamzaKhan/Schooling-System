/// A teacher's quiz as shown in the list.
class TeacherQuiz {
  final String id;
  final String title;
  final String status; // draft / published / closed

  const TeacherQuiz({
    required this.id,
    required this.title,
    required this.status,
  });

  bool get isPublished => status == 'published';

  factory TeacherQuiz.fromJson(Map<String, dynamic> j) => TeacherQuiz(
        id: '${j['id']}',
        title: j['title'] as String? ?? '',
        status: j['status'] as String? ?? 'draft',
      );
}

/// A multiple-choice question built in the create-quiz form (pre-persistence).
class DraftQuestion {
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final double marks;

  const DraftQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.marks = 1,
  });

  /// Backend `QuestionCreate` payload (always MCQ; correct answer = option text).
  Map<String, dynamic> toJson(int order) => {
        'prompt': prompt,
        'question_type': 'mcq',
        'options': options,
        'correct_answer': options[correctIndex],
        'marks': marks,
        'order_index': order,
      };
}

/// An id/label pair for the section & subject pickers.
class IdLabel {
  final String id;
  final String label;
  const IdLabel(this.id, this.label);
}

/// One student's row in a quiz performance report.
class QuizPerfRow {
  final String name;
  final double? score;
  final String status; // not_attempted / in_progress / submitted / graded
  final bool submitted;

  const QuizPerfRow({
    required this.name,
    required this.score,
    required this.status,
    required this.submitted,
  });

  factory QuizPerfRow.fromJson(Map<String, dynamic> j) => QuizPerfRow(
        name: j['name'] as String? ?? '',
        score: (j['score'] as num?)?.toDouble(),
        status: j['status'] as String? ?? 'not_attempted',
        submitted: j['submitted'] as bool? ?? false,
      );
}

/// Per-student performance for one quiz.
class QuizPerformance {
  final String title;
  final double totalMarks;
  final List<QuizPerfRow> rows;

  const QuizPerformance({
    required this.title,
    required this.totalMarks,
    required this.rows,
  });

  factory QuizPerformance.fromJson(Map<String, dynamic> j) => QuizPerformance(
        title: j['title'] as String? ?? '',
        totalMarks: (j['total_marks'] as num?)?.toDouble() ?? 0,
        rows: ((j['rows'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(QuizPerfRow.fromJson)
            .toList(),
      );
}
