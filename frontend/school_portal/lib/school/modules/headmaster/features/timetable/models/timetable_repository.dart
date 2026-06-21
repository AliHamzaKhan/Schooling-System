import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'timetable_data.dart';

class TimetableRepository {
  Future<ApiResponse<TimetableData>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_mock);
  }

  static const _math = Lesson(
    subject: 'Mathematics',
    classLabel: 'Class 8B',
    teacher: 'Mr. Anderson',
    color: AppColors.primary,
  );
  static const _world = Lesson(
    subject: 'World History',
    classLabel: 'Class 8B',
    teacher: 'Mr. Jones',
    color: Color(0xFFE8A317),
  );
  static const _grammar = Lesson(
    subject: 'Grammar',
    classLabel: 'Class 8B',
    teacher: 'Ms. Davis',
    color: AppColors.aiAccent,
  );
  static const _chem = Lesson(
    subject: 'Chemistry',
    classLabel: 'Class 8B',
    teacher: 'Dr. Smith',
    color: AppColors.tertiary,
  );
  static const _physics = Lesson(
    subject: 'Physics',
    classLabel: 'Class 8B',
    teacher: 'Dr. Smith',
    color: AppColors.primary,
  );
  static const _art = Lesson(
    subject: 'Art',
    classLabel: 'Class 8B',
    teacher: 'Ms. Lee',
    color: Color(0xFFE8A317),
  );

  static const _mock = TimetableData(
    days: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
    slots: [
      TimeSlot(label: '08:00 AM', lessons: {'Monday': _math, 'Wednesday': _physics, 'Friday': _grammar}),
      TimeSlot(label: '09:00 AM', lessons: {'Tuesday': _world, 'Thursday': _art}),
      TimeSlot(label: '10:00 AM', isBreak: true, lessons: {}),
      TimeSlot(label: '10:30 AM', lessons: {'Monday': _grammar, 'Tuesday': _chem, 'Wednesday': _math, 'Friday': _world}),
      TimeSlot(label: '11:30 AM', lessons: {'Tuesday': _physics, 'Thursday': _math, 'Friday': _chem}),
      TimeSlot(label: '12:30 PM', isBreak: true, lessons: {}),
      TimeSlot(label: '01:00 PM', lessons: {'Monday': _art, 'Wednesday': _world, 'Friday': _physics}),
    ],
  );
}
