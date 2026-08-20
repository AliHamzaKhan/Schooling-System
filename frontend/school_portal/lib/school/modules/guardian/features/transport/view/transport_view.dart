import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../widgets/skeletons.dart';
import '../controller/transport_controller.dart';
import '../models/transport_models.dart';

/// Opens the phone dialer for [phone]; no-op on failure.
Future<void> _dial(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

/// Guardian Transport — request a pickup for the selected child and track the
/// assigned bus.
class GuardianTransportView extends GetView<GuardianTransportController> {
  const GuardianTransportView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Transport'),
        backgroundColor: AppColors.surface,
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonRosterList());
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackLg,
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackXl),
            children: [
              _TrackCard(controller: controller),
              const SizedBox(height: AppSpacing.stackLg),
              Row(
                children: [
                  Expanded(child: Text('Requests', style: AppTypography.labelCaps)),
                  TextButton.icon(
                    onPressed: controller.raiseRequestFlow,
                    icon: const Icon(AppIcons.add, size: 18),
                    label: const Text('Request'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackSm),
              if (controller.requests.isEmpty)
                Text('No requests yet. Tap Request to ask for transport.',
                    style: AppTypography.bodyLg)
              else
                for (final r in controller.requests) ...[
                  _RequestRow(r: r),
                  const SizedBox(height: AppSpacing.stackSm),
                ],
            ],
          ),
        );
      }),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final GuardianTransportController controller;
  const _TrackCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Obx(() {
        final hasTrip = controller.trips.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(AppIcons.directionsBusOutlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(child: Text('Track the bus', style: AppTypography.titleLg)),
                if (hasTrip)
                  IconButton(
                    icon: const Icon(AppIcons.refresh, size: 20),
                    onPressed: () =>
                        controller.refreshTracking(controller.trips.first.id),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackSm),
            if (!hasTrip)
              Text('No bus is on a trip right now.',
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant))
            else ...[
              _DriverRow(trip: controller.trips.first),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                controller.location.value?.address ??
                    'Waiting for the driver\'s location…',
                style: AppTypography.bodyLg,
              ),
              const SizedBox(height: 4),
              Text(
                controller.eta.value?.pretty ?? '',
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _DriverRow extends StatelessWidget {
  final ActiveTrip trip;
  const _DriverRow({required this.trip});

  @override
  Widget build(BuildContext context) {
    final phone = trip.driverPhone;
    return Row(
      children: [
        const Icon(AppIcons.personOutline, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            trip.driverName == null || trip.driverName!.isEmpty
                ? 'Driver'
                : trip.driverName!,
            style: AppTypography.bodyMd,
          ),
        ),
        if (phone != null && phone.isNotEmpty)
          TextButton.icon(
            onPressed: () => _dial(phone),
            icon: const Icon(AppIcons.call, size: 18),
            label: const Text('Call'),
          ),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  final MyTransportRequest r;
  const _RequestRow({required this.r});

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (r.status) {
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
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.pickupAddress, style: AppTypography.bodyMd),
                if (r.rejectReason != null && r.rejectReason!.isNotEmpty)
                  Text('Reason: ${r.rejectReason!}',
                      style: AppTypography.labelMd
                          .copyWith(color: AppColors.error)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(r.status, style: AppTypography.labelMd.copyWith(color: c)),
          ),
        ],
      ),
    );
  }
}
