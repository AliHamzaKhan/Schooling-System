enum HomeworkStatus { pending, submitted, graded, overdue }

class HomeworkItem {
  final String subject;
  final String title;
  final String dueDate; // "Oct 18"
  final HomeworkStatus status;
  final String? grade; // when graded, e.g. "9/10"
  const HomeworkItem({
    required this.subject,
    required this.title,
    required this.dueDate,
    required this.status,
    this.grade,
  });

  factory HomeworkItem.fromJson(Map<String, dynamic> json) => HomeworkItem(
        subject: json['subject'] as String? ?? '',
        title: json['title'] as String? ?? '',
        dueDate: json['due_date'] as String? ?? '',
        status: HomeworkStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => HomeworkStatus.pending,
        ),
        grade: json['grade'] as String?,
      );
}

class HomeworkData {
  final int pending;
  final int submitted;
  final List<HomeworkItem> items;
  const HomeworkData({
    required this.pending,
    required this.submitted,
    required this.items,
  });

  factory HomeworkData.fromJson(Map<String, dynamic> json) => HomeworkData(
        pending: (json['pending'] as num?)?.toInt() ?? 0,
        submitted: (json['submitted'] as num?)?.toInt() ?? 0,
        items: ((json['items'] as List?) ?? [])
            .map((e) => HomeworkItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
