import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'dashboard_data.dart';

class DashboardRepository {
  Future<ApiResponse<DashboardData>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_mock);
  }

  static const _mock = DashboardData(
    greeting: 'Good morning,\nProf. Anderson!',
    summary:
        "You have 3 classes today and 15 pending assignments to review. Let's make it a great day of learning.",
    actions: [
      QuickAction(
        label: 'Mark Attendance',
        subtitle: 'Homeroom starts in 15m',
        icon: Icons.fact_check_outlined,
        color: AppColors.tertiary,
      ),
      QuickAction(
        label: 'Add Assignment',
        subtitle: 'Drafts available',
        icon: Icons.assignment_outlined,
        color: AppColors.primary,
      ),
      QuickAction(
        label: 'Announce',
        subtitle: 'Send a class update',
        icon: Icons.campaign_outlined,
        color: AppColors.aiAccent,
      ),
    ],
    schedule: [
      ScheduleItem(
        time: '09:00',
        period: 'AM',
        title: 'Advanced Calculus (Math 301)',
        location: 'Room 4B',
        students: 28,
        railColor: AppColors.primary,
      ),
      ScheduleItem(
        time: '11:30',
        period: 'AM',
        title: 'Geometry Basics (Math 102)',
        location: 'Room 2A',
        students: 32,
        railColor: Color(0xFFE8A317),
      ),
      ScheduleItem(
        time: '02:00',
        period: 'PM',
        title: 'Office Hours / Planning',
        location: 'Staff Room',
        students: 0,
        railColor: AppColors.outline,
        isPlanning: true,
      ),
    ],
    todos: [
      TodoItem(
        id: 'TD-1',
        title: 'Grade Midterm Papers (Math 301)',
        dueLine: 'Due Today',
        urgent: true,
      ),
      TodoItem(
        id: 'TD-2',
        title: 'Review Curriculum changes for Q3',
        dueLine: 'Due Tomorrow',
      ),
      TodoItem(
        id: 'TD-3',
        title: 'Submit Attendance Report',
        dueLine: 'Completed 8:00 AM',
        done: true,
      ),
    ],
    pendingGrades: 15,
    newSubmissions: 42,
    uploads: [
      RecentUpload(label: 'Sarah J. - Homework 4', time: '2m ago'),
      RecentUpload(label: 'Michael T. - Homework 4', time: '15m ago'),
    ],
  );
}
