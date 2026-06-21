import 'package:shared/shared.dart';

import 'guardian.dart';

class GuardiansRepository {
  Future<ApiResponse<List<Guardian>>> fetch({String query = ''}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (query.isEmpty) return ApiResponse.ok(_all);
    final q = query.toLowerCase();
    return ApiResponse.ok(_all
        .where((g) =>
            g.name.toLowerCase().contains(q) ||
            g.email.toLowerCase().contains(q))
        .toList());
  }

  static const _all = <Guardian>[
    Guardian(
      id: 'G-001',
      name: 'Sarah Jenkins',
      email: 'sarah.j@example.com',
      phone: '(555) 123-4567',
      status: GuardianStatus.active,
      linkedStudents: [
        LinkedStudent(id: 'S-1', name: 'Leo Jenkins', grade: '4', color: AppColors.aiAccent),
      ],
    ),
    Guardian(
      id: 'G-002',
      name: 'Marcus Reed',
      email: 'm.reed@example.com',
      phone: null,
      status: GuardianStatus.pending,
      linkedStudents: [
        LinkedStudent(id: 'S-2', name: 'Chloe Reed', grade: '2', color: AppColors.tertiary),
        LinkedStudent(id: 'S-3', name: 'Sam Reed', grade: '5', color: AppColors.primary),
      ],
    ),
    Guardian(
      id: 'G-003',
      name: 'David Chen',
      email: 'david.chen@example.com',
      phone: '(555) 987-6543',
      status: GuardianStatus.active,
      linkedStudents: [
        LinkedStudent(id: 'S-4', name: 'Mia Chen', grade: '6', color: AppColors.aiAccent),
      ],
    ),
  ];
}
