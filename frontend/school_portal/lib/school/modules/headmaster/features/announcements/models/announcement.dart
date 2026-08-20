import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Audience tag on an announcement (controls the pill color & icon).
enum AnnouncementScope { schoolWide, teachers, event }

extension AnnouncementScopeX on AnnouncementScope {
  String get label => switch (this) {
        AnnouncementScope.schoolWide => 'School-Wide',
        AnnouncementScope.teachers => 'Teachers Only',
        AnnouncementScope.event => 'Event',
      };

  Color get color => switch (this) {
        AnnouncementScope.schoolWide => AppColors.error,
        AnnouncementScope.teachers => AppColors.primary,
        AnnouncementScope.event => const Color(0xFFE8A317),
      };

  IconData get icon => switch (this) {
        AnnouncementScope.schoolWide => AppIcons.campaignRounded,
        AnnouncementScope.teachers => AppIcons.groupsRounded,
        AnnouncementScope.event => AppIcons.celebrationRounded,
      };
}

/// Optional attachment on an announcement (PDF / image).
class AnnouncementAttachment {
  final String filename;
  final String url;
  const AnnouncementAttachment({required this.filename, required this.url});

  factory AnnouncementAttachment.fromJson(Map<String, dynamic> json) =>
      AnnouncementAttachment(
        filename: json['filename'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );
}

/// One entry in the Announcements Hub.
class Announcement {
  final String id;
  final AnnouncementScope scope;
  final String timestamp;
  final String title;
  final String body;
  final String? author;
  final String? authorAvatarUrl;
  final String? ctaLabel;
  final AnnouncementAttachment? attachment;

  const Announcement({
    required this.id,
    required this.scope,
    required this.timestamp,
    required this.title,
    required this.body,
    this.author,
    this.authorAvatarUrl,
    this.ctaLabel,
    this.attachment,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: '${json['id']}',
        scope: AnnouncementScope.values.firstWhere(
          (s) => s.name == json['scope'],
          orElse: () => AnnouncementScope.schoolWide,
        ),
        timestamp: json['timestamp'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        author: json['author'] as String?,
        authorAvatarUrl: json['author_avatar_url'] as String?,
        ctaLabel: json['cta_label'] as String?,
        attachment: json['attachment'] == null
            ? null
            : AnnouncementAttachment.fromJson(
                json['attachment'] as Map<String, dynamic>),
      );
}
