import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:school_portal/school/modules/guardian/data/guardian_api_service.dart';
import 'package:school_portal/school/modules/student/data/student_api_service.dart';
import 'package:shared/shared.dart';

/// Answers every GET with one Monday slot, leaving the other weekdays free.
class _OneSlotApi extends ApiService {
  _OneSlotApi() : super(store: DataStoreService());

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
    final dynamic json = path.endsWith('/subjects')
        ? [
            {'id': 'math', 'name': 'Mathematics'},
          ]
        : [
            {
              'day_of_week': 0,
              'subject_id': 'math',
              'subject': 'Mathematics',
              'start_time': '08:00:00',
              'end_time': '08:40:00',
            },
          ];
    return ApiResponse.ok((parser == null ? json : parser(json)) as T);
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
    final auth = AuthService(
      api: ApiService(store: DataStoreService()),
      store: DataStoreService(),
    );
    auth.currentUser.value = {'school_id': 'school-1', 'id': 'student-1'};
    Get.put<AuthService>(auth);
  });
  tearDown(Get.reset);

  test('guardian timetable loads when some weekdays have no lessons', () async {
    final res = await GuardianApiService(api: _OneSlotApi()).fetchTimetable('child-1');
    expect(res.success, isTrue, reason: res.error);
    expect(res.data!.days.first.entries, hasLength(1));
    expect(res.data!.days[1].entries, isEmpty);
  });

  test('student timetable loads when some weekdays have no lessons', () async {
    final res = await StudentApiService(api: _OneSlotApi()).fetchTimetable();
    expect(res.success, isTrue, reason: res.error);
    expect(res.data!.first.periods, hasLength(1));
    expect(res.data![1].periods, isEmpty);
  });
}
