import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/teacher_routes.dart';
import '../../../../../widgets/portal_filter_button.dart';
import '../../../../../widgets/portal_search_field.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/skeletons.dart';
import '../components/message_thread_row.dart';
import '../controller/communication_controller.dart';

/// Communication Center — conversations with parents, students, and staff.
///
/// The header, search field, and filter button stay mounted at all times; only
/// the list below them swaps to a shimmer while a filter or search reloads.
class CommunicationView extends StatefulWidget {
  const CommunicationView({super.key});

  @override
  State<CommunicationView> createState() => _CommunicationViewState();
}

class _CommunicationViewState extends State<CommunicationView> {
  final _scroll = ScrollController();
  CommunicationController get controller => Get.find<CommunicationController>();

  /// Distance from the bottom at which the next page starts loading.
  static const _prefetchExtent = 300.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining <= _prefetchExtent) controller.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PortalTopBar(title: 'Teacher Portal', onBell: () => Get.back<void>()),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return _firstLoad();
              }
              return RefreshIndicator(
                onRefresh: controller.fetch,
                child: CustomScrollView(
                  controller: _scroll,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.containerPaddingMobile,
                          0,
                          AppSpacing.containerPaddingMobile,
                          AppSpacing.stackMd),
                      sliver: SliverToBoxAdapter(child: _header(context)),
                    ),
                    _list(),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// First paint: header skeleton plus shimmer rows, so the screen never shows
  /// a bare spinner.
  Widget _firstLoad() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerPaddingMobile,
          0,
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Shimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 220, height: 26),
                SizedBox(height: AppSpacing.stackSm),
                SkeletonBox(width: 260, height: 13),
                SizedBox(height: AppSpacing.stackMd),
                SkeletonBox(height: 46, radius: AppRadius.button),
                SizedBox(height: AppSpacing.stackLg),
                SkeletonBox(height: 48, radius: AppRadius.button),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.stackLg),
          Expanded(child: SkeletonThreadList()),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Communication\nCenter',
            style:
                AppTypography.headlineLg.copyWith(color: AppColors.primary)),
        const SizedBox(height: AppSpacing.stackSm),
        Text('Manage conversations with parents, students, and staff.',
            style: AppTypography.bodyLg),
        const SizedBox(height: AppSpacing.stackMd),
        PrimaryButton(
          label: 'New Announcement',
          leadingIcon: Icons.campaign_outlined,
          trailingIcon: null,
          onPressed: () async {
            final sent = await Get.toNamed(TeacherRoutes.createAnnouncement);
            // A published announcement becomes a new thread — pull it in.
            if (sent == true) await controller.fetch();
          },
        ),
        const SizedBox(height: AppSpacing.stackLg),
        Row(
          children: [
            // Filter moved off the page into a sheet, reached from this icon.
            Obx(() => PortalFilterButton(
                  onTap: () => _showFilterSheet(context),
                  count: controller.activeFilterCount,
                )),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: PortalSearchField(
                hint: 'Search messages…',
                onChanged: controller.onSearch,
              ),
            ),
          ],
        ),
        // Shows which filter is applied now that the chip row is gone.
        Obx(() {
          if (controller.activeFilterCount == 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.stackSm),
            child: Row(
              children: [
                Text('Showing: ${controller.filterLabel}',
                    style: AppTypography.bodySm),
                const SizedBox(width: AppSpacing.stackSm),
                GestureDetector(
                  onTap: () => controller.selectFilter(0),
                  child: Text('Clear',
                      style: AppTypography.labelMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _list() {
    return Obx(() {
      final pad = const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerPaddingMobile);

      // Filter/search in flight — shimmer the list only.
      if (controller.listLoading.value) {
        return SliverPadding(
          padding: pad.copyWith(bottom: AppSpacing.stackXl),
          sliver: const SliverToBoxAdapter(child: SkeletonThreadList()),
        );
      }

      final visible = controller.visible;
      if (visible.isEmpty) {
        return SliverPadding(
          padding: pad,
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackXl),
              child: Center(
                child: Text('No conversations match your filters.',
                    style: AppTypography.bodyLg),
              ),
            ),
          ),
        );
      }

      return SliverPadding(
        padding: pad.copyWith(bottom: AppSpacing.stackXl),
        sliver: SliverList.separated(
          // +1 for the paging footer.
          itemCount: visible.length + 1,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.stackSm),
          itemBuilder: (context, i) {
            if (i < visible.length) {
              return MessageThreadRow(thread: visible[i], onTap: () {});
            }
            return _footer(visible.length);
          },
        ),
      );
    });
  }

  Widget _footer(int shown) {
    if (controller.loadingMore.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (!controller.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
        child: Center(
          child: Text("That's all $shown conversations.",
              style: AppTypography.bodySm),
        ),
      );
    }
    return const SizedBox(height: AppSpacing.stackLg);
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackMd,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Filter conversations',
                  style: AppTypography.displayLg.copyWith(fontSize: 22)),
              const SizedBox(height: AppSpacing.stackMd),
              Obx(() => Column(
                    children: [
                      for (var i = 0;
                          i < CommunicationController.filters.length;
                          i++)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            controller.filterIndex.value == i
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: controller.filterIndex.value == i
                                ? AppColors.primary
                                : AppColors.outline,
                          ),
                          title: Text(CommunicationController.filters[i],
                              style: AppTypography.bodyLg),
                          onTap: () {
                            controller.selectFilter(i);
                            Navigator.of(sheet).pop();
                          },
                        ),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
