import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';

class _Store extends DataStoreService {
  @override
  Future<String?> readToken() async => 'member-token';
}

// 1x1 transparent PNG.
final _png = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    EnvConfig.bootstrap(Environment.debug);
    Get.put<DataStoreService>(_Store());
  });
  tearDown(Get.reset);

  test('school media is loaded with the signed-in token', () async {
    final url = EnvConfig.mediaUrl('/media/avatars/school/photo.png');
    final provider = schoolImage(url);
    expect(provider, isA<SchoolMediaImage>());

    final authorization = Completer<String?>();
    final client = MockClient((request) async {
      authorization.complete(request.headers['Authorization']);
      return http.Response.bytes(_png, 200);
    });
    final image = SchoolMediaImage(url, client: client);
    image.resolve(ImageConfiguration.empty);
    expect(await authorization.future, 'Bearer member-token');
  });

  test('other hosts never receive the token', () {
    expect(schoolImage('https://images.example.org/photo.png'), isA<NetworkImage>());
    expect(
      SchoolMediaImage.isSchoolMedia('https://images.example.org/media/x.png'),
      isFalse,
    );
  });
}
