// Headmaster exam-authoring models: reusable exam categories (terms) and a
// lightweight exam list item used by the promotion picker. Mirror the backend
// `examination` payloads.

class ExamCategory {
  final String id;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool canAnnounce;
  final bool announced;

  const ExamCategory({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.canAnnounce = false,
    this.announced = false,
  });

  static DateTime? _date(Object? v) =>
      v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

  factory ExamCategory.fromJson(Map<String, dynamic> j) => ExamCategory(
        id: '${j['id']}',
        name: j['name'] as String? ?? '',
        startDate: _date(j['start_date']),
        endDate: _date(j['end_date']),
        canAnnounce: j['can_announce'] as bool? ?? false,
        announced: j['announced'] as bool? ?? false,
      );
}

/// A minimal exam row (id + name + status) for pickers.
class ExamListItem {
  final String id;
  final String name;
  final String status;
  final String? categoryId;
  final String? classId;

  const ExamListItem({
    required this.id,
    required this.name,
    required this.status,
    this.categoryId,
    this.classId,
  });

  factory ExamListItem.fromJson(Map<String, dynamic> j) => ExamListItem(
        id: '${j['id']}',
        name: j['name'] as String? ?? '',
        status: (j['status'] as String? ?? '').toLowerCase(),
        categoryId: j['category_id'] as String?,
        classId: j['class_id'] as String?,
      );
}
