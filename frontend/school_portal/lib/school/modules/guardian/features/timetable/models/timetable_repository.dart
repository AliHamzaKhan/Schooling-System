import 'package:shared/shared.dart';

import 'timetable_data.dart';

/// Bundled mock fixtures for the Timetable screen, keyed by child id. Used as
/// the internal data source while [GuardianRepository] runs in mock mode.
class TimetableRepository {
  Future<ApiResponse<TimetableData>> load(String childId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ApiResponse.ok(_byChild[childId] ?? _byChild['c1']!);
  }

  static const _byChild = <String, TimetableData>{
    'c1': TimetableData(
      weekLabel: 'Week of October 12th',
      days: [
        TimetableDay(weekday: 'Mon', dayNum: '12', entries: _monC1),
        TimetableDay(
            weekday: 'Tue', dayNum: '13', isToday: true, entries: _tueC1),
        TimetableDay(weekday: 'Wed', dayNum: '14', entries: _monC1),
        TimetableDay(weekday: 'Thu', dayNum: '15', entries: _tueC1),
        TimetableDay(weekday: 'Fri', dayNum: '16', entries: _monC1),
      ],
    ),
    'c2': TimetableData(
      weekLabel: 'Week of October 12th',
      days: [
        TimetableDay(weekday: 'Mon', dayNum: '12', entries: _genC2),
        TimetableDay(
            weekday: 'Tue', dayNum: '13', isToday: true, entries: _genC2),
        TimetableDay(weekday: 'Wed', dayNum: '14', entries: _genC2),
        TimetableDay(weekday: 'Thu', dayNum: '15', entries: _genC2),
        TimetableDay(weekday: 'Fri', dayNum: '16', entries: _genC2),
      ],
    ),
  };

  static const _monC1 = <TimetableEntry>[
    TimetableEntry(
        subject: 'World History II',
        startTime: '08:15',
        endTime: '09:45',
        teacher: 'Ms. Carter',
        room: 'Room 104'),
    TimetableEntry(
        subject: 'Lunch Break',
        startTime: '12:00',
        endTime: '13:00',
        isBreak: true),
    TimetableEntry(
        subject: 'Calculus I',
        startTime: '13:00',
        endTime: '14:30',
        teacher: 'Mrs. Smith',
        room: 'Room 201'),
  ];

  static const _tueC1 = <TimetableEntry>[
    TimetableEntry(
        subject: 'World History II',
        startTime: '08:15',
        endTime: '09:45',
        teacher: 'Ms. Carter',
        room: 'Room 104'),
    TimetableEntry(
        subject: 'Computer Science: Data Structures',
        note: 'Focus on Binary Trees and sorting algorithms. Bring laptops.',
        startTime: '10:00',
        endTime: '11:30',
        teacher: 'Mr. Anderson',
        room: 'Room 4B',
        isNow: true),
    TimetableEntry(
        subject: 'Lunch Break',
        startTime: '12:00',
        endTime: '13:00',
        isBreak: true),
    TimetableEntry(
        subject: 'Calculus I',
        startTime: '13:00',
        endTime: '14:30',
        teacher: 'Mrs. Smith',
        room: 'Room 201'),
  ];

  static const _genC2 = <TimetableEntry>[
    TimetableEntry(
        subject: 'English',
        startTime: '09:00',
        endTime: '10:00',
        teacher: 'Ms. Reed',
        room: 'Room 5'),
    TimetableEntry(
        subject: 'Mathematics',
        startTime: '10:15',
        endTime: '11:15',
        teacher: 'Mr. Khan',
        room: 'Room 5'),
    TimetableEntry(
        subject: 'Lunch Break',
        startTime: '12:00',
        endTime: '12:45',
        isBreak: true),
    TimetableEntry(
        subject: 'Art & Craft',
        startTime: '13:00',
        endTime: '14:00',
        teacher: 'Ms. Diaz',
        room: 'Studio 1'),
  ];
}
