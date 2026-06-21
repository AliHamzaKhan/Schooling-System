import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../ui/admin_widgets/admin_search_field.dart';
import '../../../ui/admin_widgets/filter_chips.dart';
import '../components/headmaster_card.dart';
import '../controller/headmasters_controller.dart';

/// Headmaster Management — manage school leadership and administrative access.
class HeadmastersView extends GetView<HeadmastersController> {
  const HeadmastersView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      safeArea: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _Header(),
                  const SizedBox(height: AppSpacing.stackMd),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.containerPaddingMobile),
                    child: GlassSurface(
                      padding: const EdgeInsets.all(AppSpacing.stackMd),
                      child: Column(
                        children: [
                          AdminSearchField(
                            hint: 'Search by name, email, or school',
                            onChanged: controller.onSearch,
                          ),
                          const SizedBox(height: AppSpacing.stackMd),
                          Obx(() => FilterChips(
                                options: HeadmastersController.filters,
                                selectedIndex: controller.filterIndex.value,
                                onSelected: controller.selectFilter,
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.containerPaddingMobile),
                    child: _list(),
                  ),
                  const SizedBox(height: AppSpacing.stackXl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    return Obx(() {
      if (controller.loading.value) {
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.stackXl),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final items = controller.pageItems;
      if (items.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.stackXl),
          child: Center(
            child: Text('No headmasters match your filters.',
                style: AppTypography.bodyLg),
          ),
        );
      }
      return Column(
        children: [
          for (final h in items) ...[
            HeadmasterCard(headmaster: h, onMenu: () {}),
            const SizedBox(height: AppSpacing.stackLg),
          ],
          const SizedBox(height: AppSpacing.stackSm),
          _Pager(
            page: controller.page.value,
            total: controller.totalPages,
            onPrev: controller.prevPage,
            onNext: controller.nextPage,
          ),
        ],
      );
    });
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackSm,
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackLg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFCEAD6), Color(0xFFF3DCE6), Color(0xFFD9CDEF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back<void>(),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.person, color: AppColors.onPrimary, size: 20),
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Text('EduMaster Admin',
                  style: AppTypography.titleLg.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
              const Spacer(),
              const Icon(Icons.notifications_none_rounded, color: AppColors.onSurface),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Headmasters',
              style: AppTypography.displayLg.copyWith(color: AppColors.primary, fontSize: 34)),
          const SizedBox(height: AppSpacing.stackSm),
          Text('Manage school leadership and administrative access.',
              style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: AppSpacing.stackLg),
          PrimaryButton(
            label: 'New Headmaster',
            leadingIcon: Icons.add,
            trailingIcon: null,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  final int page;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _Pager({
    required this.page,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page > 1 ? onPrev : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text('Page $page of $total', style: AppTypography.labelMd),
        IconButton(
          onPressed: page < total ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
