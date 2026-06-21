import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'message_thread.dart';

class CommunicationRepository {
  Future<ApiResponse<List<MessageThread>>> fetch({
    String query = '',
    ThreadParty? party,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final filtered = _all.where((t) {
      final q = query.toLowerCase();
      final matchQ = q.isEmpty ||
          t.senderName.toLowerCase().contains(q) ||
          t.preview.toLowerCase().contains(q);
      final matchP = party == null || t.party == party;
      return matchQ && matchP;
    }).toList();
    return ApiResponse.ok(filtered);
  }

  static const _all = <MessageThread>[
    MessageThread(
      id: 'T-1',
      senderName: 'Sarah Jenkins',
      preview: "Regarding Timmy's math assignment…",
      time: '10:42 AM',
      party: ThreadParty.parent,
      unread: true,
    ),
    MessageThread(
      id: 'T-2',
      senderName: 'Alex Rivera',
      preview: 'Thank you for the extension on the project.',
      time: 'Yesterday',
      party: ThreadParty.student,
    ),
    MessageThread(
      id: 'T-3',
      senderName: 'Faculty Group',
      preview: 'Principal: Reminder about staff meeting…',
      time: 'Mon',
      party: ThreadParty.staff,
      avatarIcon: Icons.school_rounded,
    ),
  ];
}
