import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../widgets/skeletons.dart';
import 'controller/driver_trip_controller.dart';

/// Driver module shell — a single screen. Before a trip it offers a start form;
/// during a trip it shows the next-destination header + reorderable manifest.
class DriverShell extends GetView<DriverTripController> {
  const DriverShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('My Trip'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            tooltip: 'Active sessions',
            icon: const Icon(Icons.devices_outlined),
            onPressed: () => Get.to(
              () => SessionsView(
                auth: Get.find<AuthService>(),
                onSignedOut: () => Get.offAllNamed(AuthRoutes.login),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(AppIcons.logoutRounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonRosterList());
        }
        if (controller.error.value != null) {
          return AppStateView.error(
            title: 'Trip information is unavailable',
            message: controller.error.value!,
            actionLabel: 'Try again',
            onAction: controller.load,
          );
        }
        return controller.trip.value == null
            ? _StartTrip(controller: controller)
            : _ActiveTrip(controller: controller);
      }),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showAppConfirm(
      icon: AppIcons.logoutRounded,
      title: 'Log out?',
      message: 'You will need to sign in again to continue.',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (!confirmed) return;
    await Get.find<AuthService>().logout();
    Get.offAllNamed(AuthRoutes.login);
  }
}

class _StartTrip extends StatelessWidget {
  final DriverTripController controller;
  const _StartTrip({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final options = controller.routeOptions;
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.containerPaddingMobile),
        children: [
          const SizedBox(height: AppSpacing.stackLg),
          Text('Start today\'s trip', style: AppTypography.titleLg),
          const SizedBox(height: AppSpacing.stackSm),
          if (options.isEmpty)
            Text(
              'No students are assigned to you yet. Ask your school to '
              'assign pickups to you.',
              style: AppTypography.bodyLg,
            )
          else ...[
            Text('Route', style: AppTypography.labelCaps),
            const SizedBox(height: 6),
            _Dropdown(
              value: controller.selectedRouteId.value,
              items: {for (final r in options) r.id: r.name},
              onChanged: (v) => controller.selectedRouteId.value = v,
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text('Direction', style: AppTypography.labelCaps),
            const SizedBox(height: 6),
            _Dropdown(
              value: controller.tripType.value,
              items: const {
                'pickup': 'Pickup (to school)',
                'dropoff': 'Drop-off (from school)',
              },
              onChanged: (v) => controller.tripType.value = v ?? 'pickup',
            ),
            const SizedBox(height: AppSpacing.stackXl),
            PrimaryButton(
              label: controller.busy.value ? 'Starting…' : 'Start trip',
              leadingIcon: AppIcons.playArrowRounded,
              onPressed: controller.busy.value ? null : controller.startTrip,
            ),
          ],
        ],
      );
    });
  }
}

class _ActiveTrip extends StatelessWidget {
  final DriverTripController controller;
  const _ActiveTrip({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final trip = controller.trip.value!;
      final nextId = trip.nextStudentId;
      return Column(
        children: [
          // Next-destination header.
          Container(
            width: double.infinity,
            color: AppColors.primary.withValues(alpha: 0.10),
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEXT STOP', style: AppTypography.labelCaps),
                const SizedBox(height: 4),
                Text(
                  nextId == null
                      ? 'All stops handled 🎉'
                      : controller.stopLabel(nextId),
                  style: AppTypography.headlineLgMobile,
                ),
                const SizedBox(height: 2),
                Text(
                  '${controller.routeName(trip.routeId)} · ${trip.tripType}',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.containerPaddingMobile,
                vertical: AppSpacing.stackMd,
              ),
              onReorder: controller.reorder,
              children: [
                for (final studentId in trip.stopOrder)
                  _StopTile(
                    key: ValueKey(studentId),
                    label: controller.stopLabel(studentId),
                    status: trip.statusFor(studentId),
                    isNext: studentId == nextId,
                    onBoarded: () => controller.setStatus(studentId, 'boarded'),
                    onAbsent: () => controller.setStatus(studentId, 'absent'),
                    onDropped: () => controller.setStatus(studentId, 'dropped'),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.containerPaddingMobile),
              child: GhostButton(
                label: controller.busy.value ? 'Ending…' : 'End trip',
                onPressed: controller.busy.value ? null : controller.endTrip,
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _StopTile extends StatelessWidget {
  final String label;
  final String status;
  final bool isNext;
  final VoidCallback onBoarded;
  final VoidCallback onAbsent;
  final VoidCallback onDropped;

  const _StopTile({
    required super.key,
    required this.label,
    required this.status,
    required this.isNext,
    required this.onBoarded,
    required this.onAbsent,
    required this.onDropped,
  });

  @override
  Widget build(BuildContext context) {
    final done = status != 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: isNext
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: isNext ? AppColors.primary : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.dragIndicator,
            size: 20,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodyMd),
                Text(
                  status,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!done)
            PopupMenuButton<String>(
              icon: const Icon(AppIcons.moreVert),
              onSelected: (v) {
                switch (v) {
                  case 'boarded':
                    onBoarded();
                    break;
                  case 'absent':
                    onAbsent();
                    break;
                  case 'dropped':
                    onDropped();
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'boarded', child: Text('Boarded')),
                PopupMenuItem(value: 'dropped', child: Text('Dropped off')),
                PopupMenuItem(value: 'absent', child: Text('Absent / no-show')),
              ],
            )
          else
            const Icon(
              AppIcons.checkCircle,
              color: AppColors.primary,
              size: 22,
            ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String? value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;
  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: [
            for (final e in items.entries)
              DropdownMenuItem<String>(value: e.key, child: Text(e.value)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
