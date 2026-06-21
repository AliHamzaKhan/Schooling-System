import 'package:shared/shared.dart';

import 'notification_item.dart';

class NotificationsRepository {
  Future<ApiResponse<List<NotificationItem>>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ApiResponse.ok(_all);
  }

  static const _all = <NotificationItem>[
    NotificationItem(
      id: 'N-1',
      title: 'New Assignment Posted: Biology',
      body:
          'Cellular Mitosis Lab Report is due next Friday. Please review the attached guidelines.',
      timeAgo: '10m ago',
      kind: NotificationKind.assignment,
      unread: true,
    ),
    NotificationItem(
      id: 'N-2',
      title: 'Exam Result Published: History',
      body:
          'Scores for the Midterm on the Industrial Revolution are now available in your portal.',
      timeAgo: '2h ago',
      kind: NotificationKind.examResult,
    ),
    NotificationItem(
      id: 'N-3',
      title: 'School Announcement: Winter Break',
      body:
          'Campus facilities will operate on reduced hours starting December 20th. Stay warm!',
      timeAgo: '1d ago',
      kind: NotificationKind.announcement,
    ),
  ];
}
