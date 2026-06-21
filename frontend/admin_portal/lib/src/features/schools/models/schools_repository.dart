import 'package:shared/shared.dart';

import 'school.dart';
import 'school_page.dart';

/// Loads paginated, filterable, searchable schools.
///
/// Mock-backed for now; the [ApiResponse] envelope matches the real API so the
/// body becomes a single `ApiService.request` call later.
class SchoolsRepository {
  static const _pageSize = 4;

  Future<ApiResponse<SchoolPage>> fetch({
    int page = 1,
    String query = '',
    SchoolStatus? status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    var filtered = _all.where((s) {
      final matchesQuery = query.isEmpty ||
          s.name.toLowerCase().contains(query.toLowerCase()) ||
          s.location.toLowerCase().contains(query.toLowerCase());
      final matchesStatus = status == null || s.status == status;
      return matchesQuery && matchesStatus;
    }).toList();

    final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 999);
    final start = (page - 1) * _pageSize;
    final slice = filtered.skip(start).take(_pageSize).toList();

    return ApiResponse.ok(SchoolPage(
      schools: slice,
      page: page,
      // Pad to 12 to mirror the mock pager in the spec.
      totalPages: filtered.length == _all.length ? 12 : totalPages,
    ));
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
