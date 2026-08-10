import 'package:get/get.dart';

import '../../../services/api_response.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/http_method.dart';
import '../models/direct_message.dart';
import '../models/messaging_contact.dart';

/// Data access for two-way direct messaging, shared by every portal.
///
/// Talks to `/schools/{id}/messages` directly through [ApiService] so it has no
/// dependency on any portal's own repository. The same endpoints back the
/// teacher, guardian, student and headmaster inboxes.
class MessagingService {
  final ApiService _api;
  MessagingService({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  String get _sid => Get.find<AuthService>().schoolId ?? '';

  /// The signed-in user's messages. [box] is 'all' (both directions), 'inbox'
  /// (received) or 'sent'. Conversations are grouped client-side, so 'all' is
  /// what the inbox uses.
  Future<ApiResponse<List<DirectMessage>>> list({String box = 'all'}) {
    return _api.request<List<DirectMessage>>(
      method: HttpMethod.get,
      path: '/schools/$_sid/messages',
      query: {'box': box},
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(DirectMessage.fromJson)
          .toList(),
    );
  }

  /// Sends a message (or complaint) to [recipientId]. Returns the created
  /// message so the caller can append it to the open conversation.
  Future<ApiResponse<DirectMessage>> send({
    required String recipientId,
    required String body,
    String? studentId,
    String kind = 'message',
  }) {
    return _api.request<DirectMessage>(
      method: HttpMethod.post,
      path: '/schools/$_sid/messages',
      body: {
        'recipient_id': recipientId,
        'student_id': ?studentId,
        'kind': kind,
        'body': body,
      },
      parser: (json) => DirectMessage.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Marks one received message as read.
  Future<ApiResponse<dynamic>> markRead(String messageId) {
    return _api.request<dynamic>(
      method: HttpMethod.patch,
      path: '/schools/$_sid/messages/$messageId/read',
      parser: (json) => json,
    );
  }

  /// Members of the school the signed-in user can start a conversation with.
  Future<ApiResponse<List<MessagingContact>>> contacts() {
    return _api.request<List<MessagingContact>>(
      method: HttpMethod.get,
      path: '/schools/$_sid/messages/contacts',
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(MessagingContact.fromJson)
          .toList(),
    );
  }
}
