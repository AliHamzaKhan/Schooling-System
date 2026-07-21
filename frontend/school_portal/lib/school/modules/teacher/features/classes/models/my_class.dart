import '../../calendar/models/timetable_slot.dart';

/// One section the signed-in teacher actually teaches, folded up from their
/// timetable periods.
///
/// This replaces the old `/academic/classes` read, which returned *every* class
/// in the school with a hardcoded `students: 0` and no subject information.
/// Grouping the teacher's own timetable slots gives the real roster size, the
/// subjects they take for that section, and whether they are its class teacher.
class MyClass {
  final String sectionId;
  final String className;
  final String sectionName;
  final String? room;
  final int studentCount;
  final bool isClassTeacher;

  /// Distinct subjects this teacher takes for the section, alphabetical.
  final List<String> subjects;

  /// Periods a week the teacher has with this section.
  final int periodsPerWeek;

  const MyClass({
    required this.sectionId,
    required this.className,
    required this.sectionName,
    required this.studentCount,
    required this.subjects,
    required this.periodsPerWeek,
    this.room,
    this.isClassTeacher = false,
  });

  String get title => '$className $sectionName';

  /// Folds a flat list of timetable periods into one entry per section.
  static List<MyClass> fromSlots(List<TeacherSlot> slots) {
    final bySection = <String, List<TeacherSlot>>{};
    for (final s in slots) {
      bySection.putIfAbsent(s.sectionId, () => []).add(s);
    }

    final out = bySection.values.map((group) {
      final first = group.first;
      final subjects = group.map((s) => s.subject).toSet().toList()..sort();
      return MyClass(
        sectionId: first.sectionId,
        className: first.className,
        sectionName: first.sectionName,
        room: group.map((s) => s.room).firstWhere((r) => r != null, orElse: () => null),
        studentCount: first.studentCount,
        // True if the teacher is class teacher on any of this section's periods.
        isClassTeacher: group.any((s) => s.isClassTeacher),
        subjects: subjects,
        periodsPerWeek: group.length,
      );
    }).toList();

    // Sections the teacher owns first, then alphabetically — a class teacher
    // cares most about their own homeroom.
    out.sort((a, b) {
      if (a.isClassTeacher != b.isClassTeacher) return a.isClassTeacher ? -1 : 1;
      return a.title.compareTo(b.title);
    });
    return out;
  }
}
