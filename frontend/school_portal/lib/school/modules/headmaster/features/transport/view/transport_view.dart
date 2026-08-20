import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/skeletons.dart';
import '../controller/transport_controller.dart';
import '../models/transport_models.dart';

/// Headmaster Transport — review pickup requests, manage drivers, and watch the
/// online fleet.
class TransportView extends GetView<TransportController> {
  const TransportView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: AppScaffold(
        appBar: AppBar(
          title: const Text('Transport'),
          backgroundColor: AppColors.surface,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Requests'),
              Tab(text: 'Drivers'),
              Tab(text: 'Routes'),
              Tab(text: 'Fleet'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.loading.value) {
            return const SkeletonPage(body: SkeletonRosterList());
          }
          if (controller.error.value != null) {
            return Center(
                child: Text(controller.error.value!, style: AppTypography.bodyLg));
          }
          return TabBarView(
            children: [
              _RequestsTab(controller: controller),
              _DriversTab(controller: controller),
              _RoutesTab(controller: controller),
              _FleetTab(controller: controller),
            ],
          );
        }),
      ),
    );
  }
}

const _pad = EdgeInsets.fromLTRB(
  AppSpacing.containerPaddingMobile,
  AppSpacing.stackLg,
  AppSpacing.containerPaddingMobile,
  AppSpacing.stackXl,
);

class _RequestsTab extends StatelessWidget {
  final TransportController controller;
  const _RequestsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pending = controller.requests.where((r) => r.isPending).toList();
      final reviewed = controller.requests.where((r) => !r.isPending).toList();
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: _pad,
          children: [
            Text('Pending (${pending.length})', style: AppTypography.labelCaps),
            const SizedBox(height: AppSpacing.stackSm),
            if (pending.isEmpty)
              Text('No pending requests.', style: AppTypography.bodyLg)
            else
              for (final r in pending) ...[
                _RequestCard(r: r, controller: controller),
                const SizedBox(height: AppSpacing.stackMd),
              ],
            const SizedBox(height: AppSpacing.stackLg),
            Text('Reviewed', style: AppTypography.labelCaps),
            const SizedBox(height: AppSpacing.stackSm),
            if (reviewed.isEmpty)
              Text('Nothing reviewed yet.', style: AppTypography.bodyLg)
            else
              for (final r in reviewed) ...[
                _RequestCard(r: r, controller: controller),
                const SizedBox(height: AppSpacing.stackMd),
              ],
          ],
        ),
      );
    });
  }
}

class _RequestCard extends StatelessWidget {
  final TransportRequestRow r;
  final TransportController controller;
  const _RequestCard({required this.r, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(controller.studentName(r.studentId),
                    style: AppTypography.bodyLg),
              ),
              _StatusChip(status: r.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(r.pickupAddress,
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
          if (r.notes != null && r.notes!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(r.notes!,
                style: AppTypography.labelMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ],
          if (r.rejectReason != null && r.rejectReason!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('Reason: ${r.rejectReason!}',
                style: AppTypography.labelMd
                    .copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: AppSpacing.stackMd),
          if (r.status == 'pending')
            Row(
              children: [
                Expanded(
                  child: GhostButton(
                    label: 'Reject',
                    onPressed: () => controller.reject(r),
                  ),
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: PrimaryButton(
                    label: 'Approve',
                    onPressed: () => controller.approve(r),
                  ),
                ),
              ],
            )
          else if (r.status == 'approved')
            controller.isAssigned(r.studentId)
                ? Row(
                    children: [
                      const Icon(AppIcons.checkCircle,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('Assigned to transport',
                          style: AppTypography.labelMd
                              .copyWith(color: AppColors.primary)),
                    ],
                  )
                : PrimaryButton(
                    label: 'Assign to driver',
                    onPressed: () => controller.assignFlow(r),
                  ),
        ],
      ),
    );
  }
}

class _DriversTab extends StatelessWidget {
  final TransportController controller;
  const _DriversTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: _pad,
            children: [
              PrimaryButton(
                label: 'Add Driver',
                leadingIcon: AppIcons.personAddAlt1Outlined,
                onPressed: controller.addDriverFlow,
              ),
              const SizedBox(height: AppSpacing.stackLg),
              if (controller.drivers.isEmpty)
                Text('No drivers yet.', style: AppTypography.bodyLg)
              else
                for (final d in controller.drivers) ...[
                  _DriverCard(d: d, controller: controller),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
            ],
          ),
        ));
  }
}

class _DriverCard extends StatelessWidget {
  final DriverRow d;
  final TransportController controller;
  const _DriverCard({required this.d, required this.controller});

  @override
  Widget build(BuildContext context) {
    final active = d.status == 'active';
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => controller.showDriverProfile(d),
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  child: Icon(AppIcons.personOutline, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.fullName, style: AppTypography.bodyLg),
                      Text(
                        d.phone == null || d.phone!.isEmpty
                            ? 'No phone number'
                            : d.phone!,
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      Text(
                        [d.email, if (d.licenseNo != null && d.licenseNo!.isNotEmpty) 'Lic ${d.licenseNo}']
                            .join(' · '),
                        style: AppTypography.labelMd
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (!active)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('Inactive',
                        style: AppTypography.labelMd.copyWith(color: AppColors.error)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => controller.toggleDriverStatus(d),
              child: Text(active ? 'Deactivate' : 'Activate'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutesTab extends StatelessWidget {
  final TransportController controller;
  const _RoutesTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: _pad,
            children: [
              Text('Routes (${controller.routes.length})',
                  style: AppTypography.labelCaps),
              const SizedBox(height: AppSpacing.stackSm),
              if (controller.routes.isEmpty)
                Text(
                    'No routes yet. A route is created when you assign an '
                    'approved student to a driver (type a route name in the '
                    'assign dialog).',
                    style: AppTypography.bodyLg)
              else
                for (final route in controller.routes) ...[
                  _RouteCard(route: route, controller: controller),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
            ],
          ),
        ));
  }
}

class _RouteCard extends StatelessWidget {
  final RouteOption route;
  final TransportController controller;
  const _RouteCard({required this.route, required this.controller});

  @override
  Widget build(BuildContext context) {
    final riders = controller.assignmentsForRoute(route.id);
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.altRouteRounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(route.name, style: AppTypography.titleLg)),
              Text('${riders.length} student${riders.length == 1 ? '' : 's'}',
                  style: AppTypography.labelMd
                      .copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          if (riders.isEmpty)
            Text('No students on this route yet.',
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant))
          else
            for (final a in riders) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(controller.studentName(a.studentId),
                        style: AppTypography.bodyMd),
                    Text(
                      '${a.address ?? "No pickup address"} · Driver: ${controller.driverNameForUser(a.driverId)}',
                      style: AppTypography.labelMd
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _FleetTab extends StatelessWidget {
  final TransportController controller;
  const _FleetTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => RefreshIndicator(
          onRefresh: controller.refreshOnline,
          child: ListView(
            padding: _pad,
            children: [
              Text('Online now (${controller.onlineCount})',
                  style: AppTypography.labelCaps),
              const SizedBox(height: AppSpacing.stackSm),
              if (controller.online.isEmpty)
                Text('No drivers created yet.', style: AppTypography.bodyLg)
              else
                for (final o in controller.online) ...[
                  _FleetRow(o: o),
                  const SizedBox(height: AppSpacing.stackSm),
                ],
            ],
          ),
        ));
  }
}

class _FleetRow extends StatelessWidget {
  final OnlineDriver o;
  const _FleetRow({required this.o});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(AppIcons.circle,
              size: 10,
              color: o.online ? AppColors.primary : AppColors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(child: Text(o.fullName, style: AppTypography.bodyMd)),
          Text(o.online ? 'On trip' : 'Offline',
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (status) {
      case 'approved':
        c = AppColors.primary;
        break;
      case 'rejected':
        c = AppColors.error;
        break;
      default:
        c = AppColors.tertiary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status,
          style: AppTypography.labelMd.copyWith(color: c)),
    );
  }
}
