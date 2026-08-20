import 'package:shared/shared.dart';

import '../../../data/admin_api_service.dart';
import '../../schools/models/school.dart';
import 'headmaster.dart';

/// Loads filterable, paginated headmasters.
///
/// When [_useMock] is false the list is built live by aggregating every
/// school's headmaster-role users (there is no global headmasters endpoint);
/// search + status filtering happen client-side.
class HeadmastersRepository {
  HeadmastersRepository({AdminApiService? api}) : _api = api ?? AdminApiService();

  final AdminApiService _api;

  static const bool _useMock = false;
  static const pageSize = 3;

  Future<ApiResponse<List<Headmaster>>> fetch({
    String query = '',
    HeadmasterStatus? status,
  }) async {
    final List<Headmaster> all;
    if (_useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      all = _all;
    } else {
      final res = await _api.fetchHeadmasters();
      if (!res.success || res.data == null) {
        return ApiResponse.fail(res.error ?? 'Could not load headmasters.',
            statusCode: res.statusCode);
      }
      all = res.data!;
    }

    final q = query.toLowerCase();
    final filtered = all.where((h) {
      final matchQ = q.isEmpty ||
          h.name.toLowerCase().contains(q) ||
          h.email.toLowerCase().contains(q) ||
          (h.school?.toLowerCase().contains(q) ?? false);
      final matchS = status == null || h.status == status;
      return matchQ && matchS;
    }).toList();
    return ApiResponse.ok(filtered);
  }

  /// One page of schools for the create-headmaster picker. [query] runs a
  /// server-side name/code search (empty = the newest schools); [limit]/[offset]
  /// page the results so the whole directory is never loaded at once.
  Future<ApiResponse<List<School>>> searchSchools({
    String query = '',
    int limit = schoolPageSize,
    int offset = 0,
  }) =>
      _api.fetchSchools(limit: limit, offset: offset, search: query);

  /// Page size for the school picker (also the API page limit).
  static const schoolPageSize = 8;

  /// Creates a headmaster for [schoolId]. [payload] is the backend
  /// `HeadmasterCreate` body (`email`, `password`, `full_name`, optional `phone`).
  Future<ApiResponse<Headmaster>> create(String schoolId, Map<String, dynamic> payload) =>
      _api.createHeadmaster(schoolId, payload);

  /// Updates a headmaster's name/phone.
  Future<ApiResponse<Headmaster>> update(
          String schoolId, String userId, Map<String, dynamic> payload) =>
      _api.updateUser(schoolId, userId, payload);

  /// Soft-deletes (deactivates) a headmaster.
  Future<ApiResponse<Headmaster>> remove(String schoolId, String userId) =>
      _api.deactivateUser(schoolId, userId);

  static const _all = <Headmaster>[
    Headmaster(
      id: 'HM-001',
      name: 'Sarah Jenkins',
      email: 's.jenkins@oakridge.edu',
      phone: '(555) 123-4567',
      school: 'Oakridge Elementary School',
      status: HeadmasterStatus.active,
    ),
    Headmaster(
      id: 'HM-002',
      name: 'David Chen',
      email: 'd.chen@maplevalley.edu',
      phone: '(555) 987-6543',
      school: 'Maple Valley High',
      status: HeadmasterStatus.onLeave,
    ),
    Headmaster(
      id: 'HM-003',
      name: 'Marcus Reed',
      email: 'm.reed@edumaster.net',
      phone: null,
      school: null,
      status: HeadmasterStatus.pendingSetup,
    ),
    Headmaster(
      id: 'HM-004',
      name: 'Elena Rodriguez',
      email: 'e.rodriguez@summit.edu',
      phone: '(555) 222-8080',
      school: 'Summit Preparatory',
      status: HeadmasterStatus.active,
    ),
  ];
}
