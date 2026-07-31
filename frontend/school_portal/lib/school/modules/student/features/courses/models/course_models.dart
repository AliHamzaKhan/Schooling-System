// Data models for the Courses feature — courses and their two reading tracks:
// a Book (ordered text chapters) and Notes (standalone text). Mirrors the
// backend `courses` module payloads.

class Course {
  final String id;
  final String title;
  final String? description;
  final String? subject;
  final String? coverUrl;
  final int bookCount;
  final int noteCount;

  const Course({
    required this.id,
    required this.title,
    this.description,
    this.subject,
    this.coverUrl,
    this.bookCount = 0,
    this.noteCount = 0,
  });

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: '${j['id']}',
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        subject: j['subject'] as String?,
        coverUrl: j['cover_url'] as String?,
        bookCount: (j['book_count'] as num?)?.toInt() ?? 0,
        noteCount: (j['note_count'] as num?)?.toInt() ?? 0,
      );
}

class CourseBook {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int chapterCount;

  const CourseBook({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.chapterCount = 0,
  });

  factory CourseBook.fromJson(Map<String, dynamic> j) => CourseBook(
        id: '${j['id']}',
        courseId: '${j['course_id']}',
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        chapterCount: (j['chapter_count'] as num?)?.toInt() ?? 0,
      );
}

/// A chapter without its body — the table of contents entry.
class ChapterBrief {
  final String id;
  final String bookId;
  final String title;

  const ChapterBrief({
    required this.id,
    required this.bookId,
    required this.title,
  });

  factory ChapterBrief.fromJson(Map<String, dynamic> j) => ChapterBrief(
        id: '${j['id']}',
        bookId: '${j['book_id']}',
        title: j['title'] as String? ?? '',
      );
}

/// A chapter with its full text body — the reading screen payload.
class Chapter {
  final String id;
  final String bookId;
  final String title;
  final String content;

  const Chapter({
    required this.id,
    required this.bookId,
    required this.title,
    required this.content,
  });

  factory Chapter.fromJson(Map<String, dynamic> j) => Chapter(
        id: '${j['id']}',
        bookId: '${j['book_id']}',
        title: j['title'] as String? ?? '',
        content: j['content'] as String? ?? '',
      );
}

class NoteBrief {
  final String id;
  final String courseId;
  final String title;

  const NoteBrief({
    required this.id,
    required this.courseId,
    required this.title,
  });

  factory NoteBrief.fromJson(Map<String, dynamic> j) => NoteBrief(
        id: '${j['id']}',
        courseId: '${j['course_id']}',
        title: j['title'] as String? ?? '',
      );
}

class Note {
  final String id;
  final String courseId;
  final String title;
  final String content;

  const Note({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
  });

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: '${j['id']}',
        courseId: '${j['course_id']}',
        title: j['title'] as String? ?? '',
        content: j['content'] as String? ?? '',
      );
}

/// A saved reading position. For a book, [chapterId] + [page]; for a note, [page].
class ReadingProgress {
  final String resourceType; // 'book' | 'note'
  final String resourceId;
  final String? chapterId;
  final int page;

  const ReadingProgress({
    required this.resourceType,
    required this.resourceId,
    this.chapterId,
    this.page = 0,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> j) => ReadingProgress(
        resourceType: j['resource_type'] as String? ?? '',
        resourceId: '${j['resource_id']}',
        chapterId: j['chapter_id'] == null ? null : '${j['chapter_id']}',
        page: (j['page'] as num?)?.toInt() ?? 0,
      );
}
