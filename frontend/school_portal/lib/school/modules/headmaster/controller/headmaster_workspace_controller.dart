import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../data/headmaster_repository.dart';
import '../models/headmaster_workspace_context.dart';

typedef HeadmasterWorkspaceLoader =
    Future<ApiResponse<HeadmasterWorkspaceContext>> Function();

/// Loads the navigation capabilities and persistent school/session identity
/// before exposing the headmaster workspace.
class HeadmasterWorkspaceController extends GetxController {
  final HeadmasterWorkspaceLoader _loader;

  HeadmasterWorkspaceController({
    HeadmasterRepository? repository,
    HeadmasterWorkspaceLoader? loader,
  }) : _loader =
           loader ??
           (repository ?? Get.find<HeadmasterRepository>())
               .loadWorkspaceContext;

  final loading = true.obs;
  final error = RxnString();
  final context = Rxn<HeadmasterWorkspaceContext>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    context.value = null;
    final result = await _loader();
    if (result.success && result.data != null) {
      context.value = result.data;
    } else {
      error.value = result.error ?? 'Could not load workspace access.';
    }
    loading.value = false;
  }
}
