import 'package:get/get.dart';

import '../../models/permission_models.dart';

/// Drives the "Select School to Configure" list — filters the schools whose
/// module permissions can be edited.
class SchoolPermissionsController extends GetxController {
  final _all = PermissionsData.schools;
  final results = <SchoolPermissionSummary>[].obs;
  final query = ''.obs;

  @override
  void onInit() {
    super.onInit();
    results.assignAll(_all);
  }

  void onSearch(String value) {
    query.value = value;
    final q = value.toLowerCase();
    results.assignAll(
      _all.where((s) =>
          s.name.toLowerCase().contains(q) || s.id.toLowerCase().contains(q)),
    );
  }
}
