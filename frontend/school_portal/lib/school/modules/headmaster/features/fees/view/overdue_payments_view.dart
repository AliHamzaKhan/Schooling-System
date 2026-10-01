import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../data/headmaster_repository.dart';
import '../models/student_fee_snapshot.dart';
import '../../../../../widgets/skeletons.dart';

/// A single class option shown across the top tab bar.
class _ClassTab {
  final String? id; // null = All
  final String label;
  const _ClassTab({required this.id, required this.label});
}

/// Full "Overdue Payments" listing — class tabs across the top, paginated
/// server-side, one row per student who has at least one overdue invoice.
class OverduePaymentsView extends StatefulWidget {
  const OverduePaymentsView({super.key});

  @override
  State<OverduePaymentsView> createState() => _OverduePaymentsViewState();
}

class _OverduePaymentsViewState extends State<OverduePaymentsView> {
  static const _pageSize = 25;

  final _repo = Get.find<HeadmasterRepository>();

  final _tabs = <_ClassTab>[const _ClassTab(id: null, label: 'All')].obs;
  final _selectedTab = 0.obs;

  final _items = <StudentFeeSnapshot>[].obs;
  final _total = 0.obs;
  final _offset = 0.obs;
  final _loading = false.obs;
  final _error = RxnString();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Populate class tabs from the academic classes endpoint.
    final classesRes = await _repo.loadClasses();
    if (classesRes.success && classesRes.data != null) {
      _tabs.value = [
        const _ClassTab(id: null, label: 'All'),
        for (final g in classesRes.data!.grades)
          _ClassTab(
            id: g.classId,
            label: g.className.isNotEmpty ? g.className : 'Grade ${g.grade}',
          ),
      ];
    }
    await _fetch(reset: true);
  }

  Future<void> _fetch({bool reset = false}) async {
    if (reset) {
      _offset.value = 0;
      _items.clear();
      _total.value = 0;
    }
    _loading.value = true;
    _error.value = null;
    final tab = _tabs[_selectedTab.value];
    final res = await _repo.searchStudentFees(
      classId: tab.id,
      feeStatus: 'overdue',
      limit: _pageSize,
      offset: _offset.value,
    );
    if (res.success && res.data != null) {
      _items.addAll(res.data!.items);
      _total.value = res.data!.total;
    } else {
      _error.value = res.error ?? 'Could not load overdue students';
    }
    _loading.value = false;
  }

  Future<void> _loadMore() async {
    if (_loading.value) return;
    if (_items.length >= _total.value) return;
    _offset.value += _pageSize;
    await _fetch();
  }

  void _onTabSelected(int index) {
    if (index == _selectedTab.value) return;
    _selectedTab.value = index;
    _fetch(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Overdue Payments'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Obx(() => _ClassTabBar(
                tabs: _tabs,
                selectedIndex: _selectedTab.value,
                onSelected: _onTabSelected,
              )),
          Expanded(
            child: Obx(() {
              if (_loading.value && _items.isEmpty) {
                return const SkeletonPage(body: SkeletonRosterList());
              }
              if (_error.value != null && _items.isEmpty) {
                return Center(
                    child: Text(_error.value!, style: AppTypography.bodyLg));
              }
              if (_items.isEmpty) {
                return Center(
                  child: Text('No overdue payments in this class.',
                      style: AppTypography.bodyLg),
                );
              }
              return NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                    _loadMore();
                  }
                  return false;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackMd,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl,
                  ),
                  itemCount: _items.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.stackSm),
                  itemBuilder: (_, i) {
                    if (i == _items.length) {
                      if (_items.length >= _total.value) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'Showing ${_items.length} of ${_total.value}',
                              style: AppTypography.bodySm.copyWith(
                                  color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        );
                      }
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                            child: SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )),
                      );
                    }
                    return _OverdueStudentRow(
                      snapshot: _items[i],
                      onTap: () =>
                          Get.toNamed(HeadmasterRoutes.recordPayment),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ClassTabBar extends StatelessWidget {
  final List<_ClassTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const _ClassTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerPaddingMobile, vertical: 8),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == selectedIndex;
          return InkWell(
            onTap: () => onSelected(i),
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color:
                      selected ? AppColors.primary : AppColors.outlineVariant,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                tabs[i].label,
                style: AppTypography.labelMd.copyWith(
                  color:
                      selected ? AppColors.onPrimary : AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _money(double v) =>
    '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

class _OverdueStudentRow extends StatelessWidget {
  final StudentFeeSnapshot snapshot;
  final VoidCallback onTap;
  const _OverdueStudentRow({required this.snapshot, required this.onTap});

  int get _overdueCount =>
      snapshot.invoices.where((i) => i.isOverdue).length;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.error.withValues(alpha: 0.14),
              child: Text(
                snapshot.fullName.isNotEmpty
                    ? snapshot.fullName[0].toUpperCase()
                    : '?',
                style: AppTypography.titleMd
                    .copyWith(color: AppColors.error),
              ),
            ),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(snapshot.fullName, style: AppTypography.bodyLg),
                  Text(
                    [
                      if (snapshot.className != null &&
                          snapshot.className!.isNotEmpty)
                        '${snapshot.className}${snapshot.sectionName != null ? " · ${snapshot.sectionName}" : ""}',
                      '$_overdueCount overdue',
                    ].join(' · '),
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(_money(snapshot.outstandingTotal),
                style: AppTypography.titleMd
                    .copyWith(color: AppColors.error, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
