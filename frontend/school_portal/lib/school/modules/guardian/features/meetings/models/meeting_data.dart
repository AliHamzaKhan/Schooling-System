enum MeetingStatus { requested, confirmed, completed, cancelled }

enum MeetingMode { inPerson, video }

class Meeting {
  final String teacher;
  final String subject; // teacher's subject / role
  final String date; // "Oct 24"
  final String time; // "10:00 AM"
  final MeetingMode mode;
  final MeetingStatus status;
  final String? note;
  const Meeting({
    required this.teacher,
    required this.subject,
    required this.date,
    required this.time,
    required this.mode,
    required this.status,
    this.note,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) => Meeting(
        teacher: json['teacher'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        date: json['date'] as String? ?? '',
        time: json['time'] as String? ?? '',
        mode: MeetingMode.values.firstWhere(
          (m) => m.name == json['mode'],
          orElse: () => MeetingMode.inPerson,
        ),
        status: MeetingStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => MeetingStatus.requested,
        ),
        note: json['note'] as String?,
      );
}

class MeetingData {
  final List<Meeting> upcoming;
  final List<Meeting> past;
  const MeetingData({required this.upcoming, required this.past});

  factory MeetingData.fromJson(Map<String, dynamic> json) => MeetingData(
        upcoming: ((json['upcoming'] as List?) ?? [])
            .map((e) => Meeting.fromJson(e as Map<String, dynamic>))
            .toList(),
        past: ((json['past'] as List?) ?? [])
            .map((e) => Meeting.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
