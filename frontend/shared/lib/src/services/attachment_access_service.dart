import '../env/env_config.dart';
import 'api_service.dart';
import 'http_method.dart';

/// Resolves a record, never a caller-supplied blob URL. Tickets are not cached.
class AttachmentAccessService {
  final ApiService api;
  AttachmentAccessService(this.api);

  Future<Uri> downloadUri({
    required String schoolId,
    required String kind,
    required String recordId,
  }) async {
    if (!{'documents', 'submissions'}.contains(kind) ||
        schoolId.isEmpty ||
        recordId.isEmpty) {
      throw StateError('An attachment record is required.');
    }
    final result = await api.request<Map<String, dynamic>>(
      method: HttpMethod.post,
      path:
          '/schools/${Uri.encodeComponent(schoolId)}/files/$kind/'
          '${Uri.encodeComponent(recordId)}/ticket',
    );
    if (!result.success || result.data == null) {
      throw StateError('Attachment unavailable or access denied.');
    }
    return validateTicketPath(result.data!['path'], EnvConfig.apiBaseUrl);
  }

  /// A compromised/misconfigured response cannot send a ticket to another host.
  static Uri validateTicketPath(dynamic path, String apiBaseUrl) {
    final base = Uri.parse(apiBaseUrl);
    final relative = path is String ? Uri.tryParse(path) : null;
    if (relative == null ||
        relative.hasScheme ||
        relative.hasAuthority ||
        relative.hasFragment ||
        relative.path !=
            '${base.path.replaceFirst(RegExp(r'/$'), '')}/file-download' ||
        relative.queryParametersAll.length != 1 ||
        relative.queryParametersAll['ticket']?.length != 1 ||
        (relative.queryParameters['ticket'] ?? '').isEmpty) {
      throw StateError('Invalid attachment download link.');
    }
    return base.resolveUri(relative);
  }
}
