import 'package:shared/shared.dart';

import 'activity_item.dart';

/// Per-child activity feed for the guardian dashboard. Mock-backed; keyed by
/// child id so switching children swaps the timeline.
class GuardianDashboardRepository {
  Future<ApiResponse<List<ActivityItem>>> loadFeed(String childId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ApiResponse.ok(_byChild[childId] ?? _byChild['c1']!);
  }

  static const _byChild = <String, List<ActivityItem>>{
    'c1': [
      ActivityItem(
        kind: ActivityKind.grade,
        title: 'Math quiz graded',
        detail: 'Scored 18/20 — Unit 4: Fractions',
        timeAgo: '2h ago',
      ),
      ActivityItem(
        kind: ActivityKind.attendance,
        title: 'Marked present',
        detail: 'All periods attended today',
        timeAgo: '6h ago',
      ),
      ActivityItem(
        kind: ActivityKind.homework,
        title: 'New homework assigned',
        detail: 'Science — Chapter 3 worksheet, due Fri',
        timeAgo: 'Yesterday',
      ),
      ActivityItem(
        kind: ActivityKind.notice,
        title: 'School notice',
        detail: 'Annual sports day on Oct 28',
        timeAgo: '2 days ago',
      ),
    ],
    'c2': [
      ActivityItem(
        kind: ActivityKind.fee,
        title: 'Fee reminder',
        detail: 'Term 2 invoice due in 5 days',
        timeAgo: '1h ago',
      ),
      ActivityItem(
        kind: ActivityKind.homework,
        title: 'Homework due tomorrow',
        detail: 'English — reading log',
        timeAgo: '4h ago',
      ),
      ActivityItem(
        kind: ActivityKind.meeting,
        title: 'Parent-teacher meeting',
        detail: 'Scheduled for Oct 24, 10:00 AM',
        timeAgo: 'Yesterday',
      ),
    ],
  };
}
