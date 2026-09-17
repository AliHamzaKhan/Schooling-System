import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../data/headmaster_repository.dart';
import '../models/transport_models.dart';

/// Drives the Headmaster Transport screen: review pickup requests, manage
/// drivers, assign approved students to a route + driver, and watch the online
/// fleet.
class TransportController extends GetxController {
  final HeadmasterRepository _repo;
  TransportController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();

  final requests = <TransportRequestRow>[].obs;
  final drivers = <DriverRow>[].obs;
  final online = <OnlineDriver>[].obs;
  final routes = <RouteOption>[].obs;
  final assignments = <AssignmentRow>[].obs;

  /// student_id → display name, resolved from the school roster.
  final _studentNames = <String, String>{}.obs;

  String studentName(String id) => _studentNames[id] ?? 'Student';

  /// Whether an approved student has already been assigned to a driver/route.
  bool isAssigned(String studentId) =>
      assignments.any((a) => a.studentId == studentId && a.status == 'active');

  String driverNameForUser(String? userId) =>
      drivers.firstWhereOrNull((d) => d.userId == userId)?.fullName ?? 'Unassigned';

  String routeName(String routeId) =>
      routes.firstWhereOrNull((r) => r.id == routeId)?.name ?? 'Route';

  List<AssignmentRow> assignmentsForRoute(String routeId) =>
      assignments.where((a) => a.routeId == routeId).toList();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;

    final reqRes = await _repo.loadTransportRequests();
    if (reqRes.success && reqRes.data != null) {
      requests.assignAll(reqRes.data!);
    } else {
      error.value = reqRes.error ?? 'Could not load transport requests.';
    }

    final drvRes = await _repo.loadDrivers();
    if (drvRes.success && drvRes.data != null) drivers.assignAll(drvRes.data!);

    final routeRes = await _repo.loadTransportRoutes();
    if (routeRes.success && routeRes.data != null) routes.assignAll(routeRes.data!);

    final asgRes = await _repo.loadTransportAssignments();
    if (asgRes.success && asgRes.data != null) assignments.assignAll(asgRes.data!);

    final studentRes = await _repo.loadStudents();
    if (studentRes.success && studentRes.data != null) {
      _studentNames.assignAll({for (final s in studentRes.data!) s.id: s.name});
    }

    await refreshOnline();
    loading.value = false;
  }

  Future<void> refreshOnline() async {
    final res = await _repo.loadOnlineDrivers();
    if (res.success && res.data != null) online.assignAll(res.data!);
  }

  int get pendingCount => requests.where((r) => r.isPending).length;
  int get onlineCount => online.where((d) => d.online).length;

  // ------------------------------ drivers ------------------------------ #

  Future<void> addDriverFlow() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final phone = TextEditingController();
    final license = TextEditingController();
    final ok = await showActionFormSheet(
      title: 'Add Driver',
      submitLabel: 'Create',
      ownedControllers: [name, email, password, phone, license],
      fields: [
        GlassInput(label: 'Full name', hint: 'e.g. Danny Driver', controller: name),
        GlassInput(label: 'Email', hint: 'driver@school.edu', controller: email),
        GlassInput(label: 'Password', hint: 'min 8 characters', controller: password),
        GlassInput(label: 'Phone (optional)', hint: '', controller: phone),
        GlassInput(label: 'License no. (optional)', hint: '', controller: license),
      ],
      onSubmit: () async {
        if (name.text.trim().length < 2) return 'Enter the driver\'s name';
        if (!email.text.contains('@')) return 'Enter a valid email';
        if (password.text.trim().length < 8) return 'Password must be 8+ characters';
        final res = await _repo.createDriver(
          email: email.text.trim(),
          password: password.text.trim(),
          fullName: name.text.trim(),
          phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
          licenseNo: license.text.trim().isEmpty ? null : license.text.trim(),
        );
        return res.success ? null : (res.error ?? 'Could not create driver');
      },
    );
    if (ok == true) {
      Get.snackbar('Driver added', 'The driver can now log in.',
          snackPosition: SnackPosition.BOTTOM);
      await load();
    }
  }

  Future<void> toggleDriverStatus(DriverRow d) async {
    final deactivating = d.status == 'active';
    final confirmed = await showAppConfirm(
      icon: deactivating ? AppIcons.blockRounded : AppIcons.checkCircleRounded,
      title: deactivating ? 'Deactivate driver?' : 'Activate driver?',
      message: deactivating
          ? '${d.fullName} will no longer be able to run trips until reactivated.'
          : '${d.fullName} will be able to run trips again.',
      confirmLabel: deactivating ? 'Deactivate' : 'Activate',
      destructive: deactivating,
    );
    if (!confirmed) return;
    final next = deactivating ? 'inactive' : 'active';
    final res = await _repo.updateDriver(driverId: d.id, status: next);
    if (res.success) {
      await load();
    } else {
      Get.snackbar('Could not update', res.error ?? 'Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Bottom-sheet profile for a driver (name, contact, license, status).
  void showDriverProfile(DriverRow d) {
    Get.bottomSheet<void>(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.fullName, style: AppTypography.titleLg),
              const SizedBox(height: AppSpacing.stackSm),
              _kv('Phone', d.phone == null || d.phone!.isEmpty ? '—' : d.phone!),
              _kv('Email', d.email),
              _kv('License', d.licenseNo == null || d.licenseNo!.isEmpty ? '—' : d.licenseNo!),
              _kv('Status', d.status),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  static Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
                width: 80,
                child: Text(k,
                    style: AppTypography.labelMd
                        .copyWith(color: AppColors.onSurfaceVariant))),
            Expanded(child: Text(v, style: AppTypography.bodyMd)),
          ],
        ),
      );

  // ------------------------------ requests ----------------------------- #

  Future<void> approve(TransportRequestRow r) async {
    final res = await _repo.approveTransportRequest(r.id);
    if (res.success) {
      Get.snackbar('Request approved', 'Now assign the student to a driver.',
          snackPosition: SnackPosition.BOTTOM);
      await load();
    } else {
      Get.snackbar('Could not approve', res.error ?? 'Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> reject(TransportRequestRow r) async {
    final reason = TextEditingController();
    final ok = await showActionFormSheet(
      title: 'Reject Request',
      submitLabel: 'Reject',
      ownedControllers: [reason],
      fields: [
        GlassInput(label: 'Reason (optional)', hint: '', controller: reason),
      ],
      onSubmit: () async {
        final res = await _repo.rejectTransportRequest(
          r.id,
          reason: reason.text.trim().isEmpty ? null : reason.text.trim(),
        );
        return res.success ? null : (res.error ?? 'Could not reject');
      },
    );
    if (ok == true) await load();
  }

  /// Assign an approved request's student to a route + driver.
  Future<void> assignFlow(TransportRequestRow r) async {
    if (drivers.isEmpty) {
      Get.snackbar('Add a driver first', 'Create a driver before assigning.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final routeName = TextEditingController();
    final selectedDriver = RxnString(drivers.first.userId);
    final selectedRoute = RxnString(routes.isNotEmpty ? routes.first.id : null);

    final ok = await showActionFormSheet(
      title: 'Assign — ${studentName(r.studentId)}',
      submitLabel: 'Assign',
      ownedControllers: [routeName],
      fields: [
        Obx(() => _dropdown<String>(
              label: 'Driver',
              value: selectedDriver.value,
              items: {for (final d in drivers) d.userId: d.fullName},
              onChanged: (v) => selectedDriver.value = v,
            )),
        Obx(() => _dropdown<String>(
              label: routes.isEmpty ? 'Route (none yet — create below)' : 'Route',
              value: selectedRoute.value,
              items: {for (final rt in routes) rt.id: rt.name},
              onChanged: (v) => selectedRoute.value = v,
            )),
        GlassInput(
          label: 'Or create a new route',
          hint: 'e.g. North Route',
          controller: routeName,
        ),
      ],
      onSubmit: () async {
        var routeId = selectedRoute.value;
        // Create a route on the fly if the headmaster typed a name.
        if (routeName.text.trim().isNotEmpty) {
          final created = await _repo.createTransportRoute(routeName.text.trim());
          if (!created.success || created.data == null) {
            return created.error ?? 'Could not create route';
          }
          routeId = created.data!.id;
        }
        if (routeId == null) return 'Pick or create a route';
        if (selectedDriver.value == null) return 'Pick a driver';
        final res = await _repo.assignTransportStudent(
          requestId: r.id, routeId: routeId, driverId: selectedDriver.value!,
        );
        return res.success ? null : (res.error ?? 'Could not assign');
      },
    );
    if (ok == true) {
      Get.snackbar('Assigned', 'The student was assigned to the driver.',
          snackPosition: SnackPosition.BOTTOM);
      await load();
    }
  }

  static Widget _dropdown<T>({
    required String label,
    required T? value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelMd
                .copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              items: [
                for (final e in items.entries)
                  DropdownMenuItem<T>(value: e.key, child: Text(e.value)),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
