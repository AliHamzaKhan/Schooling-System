import 'package:shared/shared.dart';

import 'notification_item.dart';

class NotificationRepository {
  Future<ApiResponse<List<NotificationItem>>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ApiResponse.ok(List<NotificationItem>.from(_mock));
  }

  static const _mock = <NotificationItem>[
    NotificationItem(
      id: 'n1',
      title: 'Fee overdue',
      body: 'Zayan\'s activity fee of \$150 is past due.',
      timeAgo: '1h ago',
      level: AlertLevel.critical,
      childName: 'Zayan',
    ),
    NotificationItem(
      id: 'n2',
      title: 'New grade posted',
      body: 'Aanya scored 18/20 in the Math quiz.',
      timeAgo: '2h ago',
      level: AlertLevel.success,
      childName: 'Aanya',
    ),
    NotificationItem(
      id: 'n3',
      title: 'Homework due tomorrow',
      body: 'Zayan has an English reading log due Oct 16.',
      timeAgo: '4h ago',
      level: AlertLevel.warning,
      childName: 'Zayan',
    ),
    NotificationItem(
      id: 'n4',
      title: 'Meeting confirmed',
      body: 'Parent-teacher meeting with Ms. Rivera on Oct 24.',
      timeAgo: 'Yesterday',
      level: AlertLevel.info,
      childName: 'Aanya',
      read: true,
    ),
    NotificationItem(
      id: 'n5',
      title: 'School notice',
      body: 'Annual sports day scheduled for Oct 28.',
      timeAgo: '2 days ago',
      level: AlertLevel.info,
      read: true,
    ),
  ];
}
