import 'package:shared/shared.dart';

import '../../../data/admin_api_service.dart';
import 'school.dart';
import 'school_page.dart';

/// Loads paginated, filterable, searchable schools and performs school writes.
///
/// Single data gateway for the Schools feature: controllers depend on this, not
/// on [AdminApiService] or [ApiService]. When [_useMock] is false every call
/// routes to the live backend; the backend list endpoint supports only
/// `limit`/`offset`, so search + status filtering + paging happen client-side.
class SchoolsRepository {
  SchoolsRepository({AdminApiService? api})
      : _api = api ?? AdminApiService();

  final AdminApiService _api;

  /// When true, methods return bundled mock data instead of hitting the API.
  static const bool _useMock = false;

  static const _pageSize = 8;

  Future<ApiResponse<SchoolPage>> fetch({
    int page = 1,
    String query = '',
    SchoolStatus? status,
  }) async {
    final List<School> all;
    if (_useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      all = _all;
    } else {
      final res = await _api.fetchSchools();
      if (!res.success || res.data == null) {
        return ApiResponse.fail(res.error ?? 'Could not load schools.',
            statusCode: res.statusCode);
      }
      all = res.data!;
    }

    final filtered = all.where((s) {
      final q = query.toLowerCase();
      final matchesQuery = query.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.location.toLowerCase().contains(q) ||
          s.code.toLowerCase().contains(q);
      final matchesStatus = status == null || s.status == status;
      return matchesQuery && matchesStatus;
    }).toList();

    final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 999);
    final start = (page - 1) * _pageSize;
    final slice = filtered.skip(start).take(_pageSize).toList();

    return ApiResponse.ok(SchoolPage(
      schools: slice,
      page: page,
      totalPages: totalPages,
    ));
  }

  /// Creates a school. [payload] is the backend `SchoolCreate` body
  /// (`name`, `code`, `contact_email`, `contact_phone`, `address`,
  /// `subscription_plan_code`).
  Future<ApiResponse<School>> create(Map<String, dynamic> payload) async {
    if (_useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return ApiResponse.ok(School(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        name: payload['name'] as String? ?? 'New School',
        location: payload['address'] as String? ?? '—',
        students: 0,
        status: SchoolStatus.pending,
        tenureLabel: 'Pending',
      ));
    }
    return _api.createSchool(payload);
  }

  /// Updates a school's general info (backend `SchoolUpdate`).
  Future<ApiResponse<School>> update(
    String id,
    Map<String, dynamic> payload,
  ) async {
    if (_useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return ApiResponse.ok(_all.firstWhere((s) => s.id == id,
          orElse: () => _all.first));
    }
    return _api.updateSchool(id, payload);
  }

  /// Sets a school's status (`pending` / `active` / `suspended`).
  Future<ApiResponse<School>> setStatus(String id, String status) async {
    if (_useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return ApiResponse.ok(_all.firstWhere((s) => s.id == id,
          orElse: () => _all.first));
    }
    return _api.setSchoolStatus(id, status);
  }

  /// Assigns a subscription plan (`basic` / `standard` / `premium`).
  Future<ApiResponse<School>> assignSubscription(String id, String planCode) async {
    if (_useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return ApiResponse.ok(_all.firstWhere((s) => s.id == id, orElse: () => _all.first));
    }
    return _api.assignSubscription(id, planCode);
  }

  static const _all = <School>[
    School(
      id: 'SCH-2023-089',
      name: 'Oakridge International Academy',
      location: 'Seattle, WA',
      students: 1240,
      status: SchoolStatus.active,
      tenureLabel: 'Joined Aug 2022',
    ),
    School(
      id: 'SCH-2024-114',
      name: 'Maplewood Elementary',
      location: 'Portland, OR',
      students: 450,
      status: SchoolStatus.trial,
      tenureLabel: '12 Days Left',
    ),
    School(
      id: 'SCH-2021-052',
      name: 'Summit Preparatory',
      location: 'Denver, CO',
      students: 890,
      status: SchoolStatus.expired,
      tenureLabel: 'Expired Jan 15',
    ),
    School(
      id: 'SCH-2023-201',
      name: 'Valley View Charter',
      location: 'Austin, TX',
      students: 620,
      status: SchoolStatus.active,
      tenureLabel: 'Joined Mar 2023',
    ),
    School(
      id: 'SCH-2024-260',
      name: 'Riverside Day School',
      location: 'Sacramento, CA',
      students: 310,
      status: SchoolStatus.pending,
      tenureLabel: 'Awaiting review',
    ),
  ];
}
