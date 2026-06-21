import 'package:get/get.dart';

import 'guardian_session_controller.dart';

/// Base controller for guardian features that show data for the *active* child.
/// Subclasses implement [fetch] to load their data for a given child id;
/// reloads happen automatically on init and whenever the selected child changes.
abstract class ChildScopedController<T> extends GetxController {
  final GuardianSessionController session;
  ChildScopedController({GuardianSessionController? session})
      : session = session ?? Get.find<GuardianSessionController>();

  final loading = true.obs;
  final data = Rxn<T>();

  /// Load this feature's data for [childId]. Return null on failure.
  Future<T?> fetch(String childId);

  @override
  void onInit() {
    super.onInit();
    ever<String?>(session.selectedId, (id) {
      if (id != null) _load(id);
    });
    final current = session.selectedId.value;
    if (current != null) _load(current);
  }

  Future<void> _load(String childId) async {
    loading.value = true;
    data.value = await fetch(childId);
    loading.value = false;
  }

  void reload() {
    final id = session.selectedId.value;
    if (id != null) _load(id);
  }
}
