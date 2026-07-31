// Headmaster-side course authoring models. Mirror the backend `courses` module
// payloads; kept minimal for the create/list authoring flows.

class AdminCourse {
  final String id;
  final String title;
  final String? subject;
  final String? description;
  final int bookCount;
  final int noteCount;
  // The class+section this course is offered to (a course = a subject taught to
  // one section). Null for legacy school-wide courses.
  final String? sectionId;
  final String? subjectId;
  final String? className;
  final String? sectionName;
  final String? subjectName;

  const AdminCourse({
    required this.id,
    required this.title,
    this.subject,
    this.description,
    this.bookCount = 0,
    this.noteCount = 0,
    this.sectionId,
    this.subjectId,
    this.className,
    this.sectionName,
    this.subjectName,
  });

  /// "Grade 5 · A" when the course is scoped to a class+section, else null.
  String? get classSectionLabel {
    if (className == null) return null;
    final sec = sectionName == null ? '' : ' · $sectionName';
    return '$className$sec';
  }

  factory AdminCourse.fromJson(Map<String, dynamic> j) => AdminCourse(
        id: '${j['id']}',
        title: j['title'] as String? ?? '',
        subject: j['subject'] as String?,
        description: j['description'] as String?,
        bookCount: (j['book_count'] as num?)?.toInt() ?? 0,
        noteCount: (j['note_count'] as num?)?.toInt() ?? 0,
        sectionId: j['section_id'] as String?,
        subjectId: j['subject_id'] as String?,
        className: j['class_name'] as String?,
        sectionName: j['section_name'] as String?,
        subjectName: j['subject_name'] as String?,
      );
}

class AdminBook {
  final String id;
  final String title;
  final String? description;
  final int chapterCount;

  const AdminBook({
    required this.id,
    required this.title,
    this.description,
    this.chapterCount = 0,
  });

  factory AdminBook.fromJson(Map<String, dynamic> j) => AdminBook(
        id: '${j['id']}',
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        chapterCount: (j['chapter_count'] as num?)?.toInt() ?? 0,
      );
}

class AdminChapter {
  final String id;
  final String title;

  const AdminChapter({required this.id, required this.title});

  factory AdminChapter.fromJson(Map<String, dynamic> j) =>
      AdminChapter(id: '${j['id']}', title: j['title'] as String? ?? '');
}

class AdminNote {
  final String id;
  final String title;

  const AdminNote({required this.id, required this.title});

  factory AdminNote.fromJson(Map<String, dynamic> j) =>
      AdminNote(id: '${j['id']}', title: j['title'] as String? ?? '');
}
