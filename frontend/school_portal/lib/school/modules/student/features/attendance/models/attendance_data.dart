class DayBar {
  final String label;
  final double presentRatio; // 0..1 — partial bar for "late" days
  const DayBar(this.label, this.presentRatio);

  factory DayBar.fromJson(Map<String, dynamic> json) => DayBar(
        json['label'] as String? ?? '',
        (json['present_ratio'] as num?)?.toDouble() ?? 0,
      );
}

class LateMark {
  final String date;
  final String period;
  final int minutes;
  const LateMark({required this.date, required this.period, required this.minutes});

  factory LateMark.fromJson(Map<String, dynamic> json) => LateMark(
        date: json['date'] as String? ?? '',
        period: json['period'] as String? ?? '',
        minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      );
}

class AttendanceData {
  final int monthlyAverage;
  /// Change against last month; null when there is no previous figure.
  final int? deltaPercent;
  final List<DayBar> week;
  final List<String> recentAbsences;
  final List<LateMark> lateMarks;

  const AttendanceData({
    required this.monthlyAverage,
    this.deltaPercent,
    required this.week,
    required this.recentAbsences,
    required this.lateMarks,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) => AttendanceData(
        monthlyAverage: (json['monthly_average'] as num?)?.toInt() ?? 0,
        deltaPercent: (json['delta_percent'] as num?)?.toInt(),
        week: ((json['week'] as List?) ?? [])
            .map((e) => DayBar.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentAbsences: ((json['recent_absences'] as List?) ?? [])
            .map((e) => '$e')
            .toList(),
        lateMarks: ((json['late_marks'] as List?) ?? [])
            .map((e) => LateMark.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
