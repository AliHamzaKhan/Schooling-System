/// A student's own attempt at a quiz (score + state).
class QuizAttempt {
  final String quizId;
  final double? score;
  final String status; // in_progress / submitted / graded

  const QuizAttempt({
    required this.quizId,
    required this.score,
    required this.status,
  });

  bool get isDone => status == 'submitted' || status == 'graded';

  factory QuizAttempt.fromJson(Map<String, dynamic> j) => QuizAttempt(
        quizId: '${j['quiz_id']}',
        score: (j['score'] as num?)?.toDouble(),
        status: j['status'] as String? ?? 'in_progress',
      );
}

/// A quiz in the student's list, with their attempt (if any) merged in.
class StudentQuiz {
  final String id;
  final String title;
  final String status; // draft / published / closed
  final QuizAttempt? attempt;

  const StudentQuiz({
    required this.id,
    required this.title,
    required this.status,
    this.attempt,
  });

  bool get isPublished => status == 'published';
  bool get isAttempted => attempt?.isDone ?? false;

  factory StudentQuiz.fromJson(Map<String, dynamic> j) => StudentQuiz(
        id: '${j['id']}',
        title: j['title'] as String? ?? '',
        status: j['status'] as String? ?? 'draft',
      );

  StudentQuiz withAttempt(QuizAttempt? a) => StudentQuiz(
        id: id,
        title: title,
        status: status,
        attempt: a,
      );
}

/// One question presented to the student while taking a quiz.
class QuizQuestionView {
  final String id;
  final String prompt;
  final List<String> options;
  final double marks;

  const QuizQuestionView({
    required this.id,
    required this.prompt,
    required this.options,
    required this.marks,
  });

  factory QuizQuestionView.fromJson(Map<String, dynamic> j) => QuizQuestionView(
        id: '${j['id']}',
        prompt: j['prompt'] as String? ?? '',
        options: ((j['options'] as List?) ?? const [])
            .map((e) => '$e')
            .toList(),
        marks: (j['marks'] as num?)?.toDouble() ?? 1,
      );
}

/// The full quiz a student is taking.
class StudentQuizDetail {
  final String id;
  final String title;
  final String? description;
  final List<QuizQuestionView> questions;

  const StudentQuizDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
  });

  double get totalMarks =>
      questions.fold<double>(0, (sum, q) => sum + q.marks);

  factory StudentQuizDetail.fromJson(Map<String, dynamic> j) =>
      StudentQuizDetail(
        id: '${j['id']}',
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        questions: ((j['questions'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(QuizQuestionView.fromJson)
            .toList(),
      );
}

/// The graded result returned after submitting an attempt.
class QuizResult {
  final double score;
  final String status;
  const QuizResult({required this.score, required this.status});

  factory QuizResult.fromJson(Map<String, dynamic> j) => QuizResult(
        score: (j['score'] as num?)?.toDouble() ?? 0,
        status: j['status'] as String? ?? 'graded',
      );
}
