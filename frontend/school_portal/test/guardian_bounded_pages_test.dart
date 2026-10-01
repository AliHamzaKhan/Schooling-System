import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:school_portal/school/modules/guardian/data/guardian_api_service.dart';
import 'package:shared/shared.dart';

/// Serves `total` invoice rows through the server's bounded 100-row pages.
class _PagedApi extends ApiService {
  _PagedApi(this.total) : super(store: DataStoreService());
  final int total;
  final queries = <Map<String, String>>[];

  @override
  Future<ApiResponse<T>> request<T>({
    required HttpMethod method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    Map<String, String>? headers,
    List<MultipartUpload>? files,
    bool requiresAuth = true,
    bool asForm = false,
    T Function(dynamic json)? parser,
    Duration? timeout,
  }) async {
    queries.add(query ?? const {});
    final limit = int.parse(query!['limit']!);
    final offset = int.parse(query['offset'] ?? '0');
    if (limit > 100) return ApiResponse.fail('limit too large', statusCode: 422);
    final end = (offset + limit).clamp(0, total);
    final rows = [
      for (var i = offset; i < end; i++)
        {'title': 'Invoice $i', 'amount': 10, 'amount_paid': 4, 'due_date': '2030-01-01', 'status': 'unpaid'},
    ];
    return ApiResponse.ok(rows as T);
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
    final auth = AuthService(api: ApiService(store: DataStoreService()), store: DataStoreService());
    auth.currentUser.value = {'school_id': 'school-1'};
    Get.put<AuthService>(auth);
  });
  tearDown(Get.reset);

  test('guardian fees read every bounded page instead of an over-limit request', () async {
    final api = _PagedApi(105);
    final res = await GuardianApiService(api: api).fetchFees('child-1');

    expect(res.success, isTrue, reason: res.error);
    expect(res.data!.invoices, hasLength(105));
    expect(res.data!.outstanding, 105 * 6);
    expect(api.queries.map((q) => q['limit']).toSet(), {'100'});
    expect(api.queries.map((q) => q['offset']), ['0', '100']);
    expect(api.queries.every((q) => q['student_id'] == 'child-1'), isTrue);
  });
}
