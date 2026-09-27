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
  final error = RxnString();

  /// Load this feature's data for [childId]. Return null on failure.
  Future<T?> fetch(String childId);

  @override
  void onInit() {
    super.onInit();
    ever<String?>(session.selectedId, (id) {
      if (id == null) {
        data.value = null;
        error.value = null;
      } else {
        _load(id);
      }
    });
    final current = session.selectedId.value;
    if (current != null) _load(current);
  }

  Future<void> _load(String childId) async {
    loading.value = true;
    error.value = null;
    data.value = null;
    final loaded = await fetch(childId);
    if (loaded == null) {
      error.value = 'Could not load this child’s latest information.';
    } else {
      data.value = loaded;
    }
    loading.value = false;
  }

  Future<void> reload() {
    final id = session.selectedId.value;
    return id == null ? Future.value() : _load(id);
  }
}
