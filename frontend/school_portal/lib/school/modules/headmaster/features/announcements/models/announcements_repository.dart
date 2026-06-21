import 'package:shared/shared.dart';

import 'announcement.dart';

/// Loads filterable announcements. Mock-backed; swap to `ApiService.request`
/// when the backend endpoint is available.
class AnnouncementsRepository {
  Future<ApiResponse<List<Announcement>>> fetch({String filter = 'All Updates'}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (filter == 'All Updates') return ApiResponse.ok(_all);
    final scope = switch (filter) {
      'School-Wide' => AnnouncementScope.schoolWide,
      'Teachers Only' => AnnouncementScope.teachers,
      'Events' => AnnouncementScope.event,
      _ => null,
    };
    return ApiResponse.ok(
      scope == null ? _all : _all.where((a) => a.scope == scope).toList(),
    );
  }

  static const _all = <Announcement>[
    Announcement(
      id: 'A-001',
      scope: AnnouncementScope.schoolWide,
      timestamp: 'Today, 8:00 AM',
      title: 'Campus Main Building Plumbing Maintenance',
      body:
          'Please note that water will be shut off in the East Wing of the main building '
          'from 10:00 AM to 2:00 PM today. Restrooms in the West Wing and Gymnasium '
          'will remain operational.',
      author: 'Facilities Dept',
    ),
    Announcement(
      id: 'A-002',
      scope: AnnouncementScope.teachers,
      timestamp: 'Yesterday, 3:30 PM',
      title: 'Q3 Grade Submission Deadline Approaching',
      body:
          'A gentle reminder that all Q3 grades and progress reports must be finalized '
          'in the portal by Friday at 5:00 PM. The system will lock for parent-view '
          'generation over the weekend.',
      ctaLabel: 'View Portal Instructions',
    ),
    Announcement(
      id: 'A-003',
      scope: AnnouncementScope.event,
      timestamp: 'Mon, 9:15 AM',
      title: 'Annual Science Fair Winners Announced!',
      body:
          "Congratulations to all participants in this year's Island Science Fair. The "
          'ingenuity on display was phenomenal. Special shoutout to Grade 8 for their '
          'renewable energy models.',
      attachment: AnnouncementAttachment(
        filename: 'Science_Fair_Results_2024.pdf',
        url: 'https://example.com/results.pdf',
      ),
    ),
  ];
}
