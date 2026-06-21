import 'package:flutter_test/flutter_test.dart';

import 'package:shared/shared.dart';

void main() {
  test('ApiResponse.ok wraps a success payload', () {
    final res = ApiResponse.ok(42);
    expect(res.success, isTrue);
    expect(res.data, 42);
  });
}
