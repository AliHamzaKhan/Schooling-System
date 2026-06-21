import 'package:get/get.dart';

import '../../services/api_service.dart';
import '../../services/http_method.dart';
import 'models/institution.dart';

/// Default [InstitutionLoader] — fetches the public list of institutions from
/// the backend. Returns an empty list on any failure so the login screen still
/// renders. Override via [AuthConfig.institutionsLoader] for a custom source.
Future<List<Institution>> apiInstitutionLoader() async {
  if (!Get.isRegistered<ApiService>()) return const [];
  final api = Get.find<ApiService>();
  final res = await api.request<List<dynamic>>(
    method: HttpMethod.get,
    path: '/schools/public',
    requiresAuth: false,
  );
  if (!res.success || res.data == null) return const [];
  return res.data!
      .whereType<Map<String, dynamic>>()
      .map(Institution.fromJson)
      .toList();
}
