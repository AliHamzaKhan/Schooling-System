import 'package:shared/shared.dart';

import '../../../data/admin_api_service.dart';
import 'module_models.dart';

/// Data gateway for per-school module permissions. Controllers depend on this,
/// not on [AdminApiService]. Every call routes to the live backend
/// (`GET/PUT /schools/{id}/modules`).
class SchoolModulesRepository {
  SchoolModulesRepository({AdminApiService? api}) : _api = api ?? AdminApiService();

  final AdminApiService _api;

  Future<ApiResponse<SchoolModulesView>> load(String schoolId) =>
      _api.fetchSchoolModules(schoolId);

  Future<ApiResponse<SchoolModulesView>> save(
    String schoolId,
    List<ModuleToggle> toggles,
  ) =>
      _api.setSchoolModules(schoolId, toggles);
}
