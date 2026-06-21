import 'package:shared/shared.dart';

import 'headmaster.dart';

/// Loads filterable, paginated headmasters.
class HeadmastersRepository {
  static const pageSize = 3;

  Future<ApiResponse<List<Headmaster>>> fetch({
    String query = '',
    HeadmasterStatus? status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final q = query.toLowerCase();
    final filtered = _all.where((h) {
      final matchQ = q.isEmpty ||
          h.name.toLowerCase().contains(q) ||
          h.email.toLowerCase().contains(q) ||
          (h.school?.toLowerCase().contains(q) ?? false);
      final matchS = status == null || h.status == status;
      return matchQ && matchS;
    }).toList();
    return ApiResponse.ok(filtered);
  }

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
