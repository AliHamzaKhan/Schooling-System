import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

enum ThreadParty { parent, student, staff }

extension ThreadPartyX on ThreadParty {
  String get label => switch (this) {
        ThreadParty.parent => 'PARENT',
        ThreadParty.student => 'STUDENT',
        ThreadParty.staff => 'STAFF',
      };

  Color get color => switch (this) {
        ThreadParty.parent => AppColors.tertiary,
        ThreadParty.student => AppColors.aiAccent,
        ThreadParty.staff => AppColors.primary,
      };
}

class MessageThread {
  final String id;
  final String senderName;
  final String preview;
  final String time;
  final ThreadParty party;
  final String? avatarUrl;
  final IconData? avatarIcon;
  final bool unread;

  const MessageThread({
    required this.id,
    required this.senderName,
    required this.preview,
    required this.time,
    required this.party,
    this.avatarUrl,
    this.avatarIcon,
    this.unread = false,
  });

  String get initial =>
      senderName.isEmpty ? '?' : senderName.characters.first.toUpperCase();

  factory MessageThread.fromJson(Map<String, dynamic> json) => MessageThread(
        id: '${json['id']}',
        senderName: json['sender_name'] as String? ?? '',
        preview: json['preview'] as String? ?? '',
        time: json['time'] as String? ?? '',
        party: ThreadParty.values.firstWhere(
          (p) => p.name == json['party'],
          orElse: () => ThreadParty.parent,
        ),
        avatarUrl: json['avatar_url'] as String?,
        unread: json['unread'] as bool? ?? false,
      );
}
