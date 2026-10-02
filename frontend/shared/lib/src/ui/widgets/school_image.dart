import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../env/env_config.dart';
import '../../services/data_store_service.dart';

/// Image for a school photo or logo stored by this app (`/media/...`).
///
/// School media is private to the school's own members, so the request must
/// carry the signed-in user's token; a plain [NetworkImage] cannot. Anything
/// that is not our own media (another host, an empty value) falls back to a
/// plain [NetworkImage] and never receives the token.
ImageProvider schoolImage(String url) {
  final resolved = EnvConfig.mediaUrl(url);
  if (SchoolMediaImage.isSchoolMedia(resolved)) {
    return SchoolMediaImage(resolved);
  }
  return NetworkImage(resolved);
}

class SchoolMediaImage extends ImageProvider<SchoolMediaImage> {
  const SchoolMediaImage(this.url, {this.client});

  final String url;

  /// Test hook; the default client is created per request.
  final http.Client? client;

  /// Only media on our own server gets the token.
  static bool isSchoolMedia(String url) {
    final uri = Uri.tryParse(url);
    final origin = Uri.tryParse(EnvConfig.serverOrigin);
    if (uri == null || origin == null) return false;
    return uri.scheme == origin.scheme &&
        uri.host == origin.host &&
        uri.port == origin.port &&
        uri.path.startsWith('/media/');
  }

  @override
  Future<SchoolMediaImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<SchoolMediaImage>(this);

  @override
  ImageStreamCompleter loadImage(
    SchoolMediaImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: 1.0,
      debugLabel: 'school media',
    );
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final store = Get.isRegistered<DataStoreService>()
        ? Get.find<DataStoreService>()
        : null;
    final token = await store?.readToken();
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.get(
        Uri.parse(url),
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw StateError('School image unavailable (${response.statusCode})');
      }
      return await decode(
        await ui.ImmutableBuffer.fromUint8List(response.bodyBytes),
      );
    } finally {
      if (client == null) httpClient.close();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SchoolMediaImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
