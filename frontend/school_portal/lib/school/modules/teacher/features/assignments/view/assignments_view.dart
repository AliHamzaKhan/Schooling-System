import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/filter_chips.dart';
import '../../../../../widgets/portal_search_field.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../components/assignment_card.dart';
import '../models/assignment.dart';
import '../components/assignment_stat_card.dart';
import '../controller/assignments_controller.dart';
import '../../../../../widgets/skeletons.dart';

/// Assignments Management — Tasks tab content. KPI stats, search, class
/// filter chips, list of assignments. FAB opens the New Assignment menu.
class AssignmentsView extends GetView<TeacherAssignmentsController> {
  final VoidCallback? onCreateHomework;
  final VoidCallback? onCreateExam;
  final VoidCallback? onCreateQuiz;
  final VoidCallback? onOpenGradebook;
  final VoidCallback? onOpenQuizzes;

  /// Opens the Performance tab — the turn-in-rate stat drills into it.
  final VoidCallback? onOpenPerformance;

  const AssignmentsView({
    super.key,
    this.onCreateHomework,
    this.onCreateExam,
    this.onCreateQuiz,
    this.onOpenGradebook,
    this.onOpenQuizzes,
    this.onOpenPerformance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PortalTopBar(title: 'Teacher Portal'),
        Expanded(
          child: Obx(() {
            // Only the very first load takes over the screen. Filter/search
            // re-fetches keep the list mounted so the scroll position — and
            // the filter row the user just tapped — stay where they were.
            if (controller.loading.value) {
              return const SkeletonPage(body: Column(children: [SkeletonStatRow(), SizedBox(height: AppSpacing.stackLg), SkeletonCardList(count: 4, height: 120)]));
            }
            final data = controller.data.value;
            if (data == null) {
              return Center(
                  child: Text(controller.error.value ?? 'No data',
                      style: AppTypography.bodyLg));
            }
            return _AssignmentsList(
              controller: controller,
              onCreate: () => _showCreatePicker(context),
              onOpenGradebook: onOpenGradebook,
              onOpenQuizzes: onOpenQuizzes,
              onOpenPerformance: onOpenPerformance,
            );
          }),
        ),
      ],
    );
  }

  Future<void> _showCreatePicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.stackMd),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppSpacing.stackMd),
            ListTile(
              leading: const Icon(Icons.assignment_add, color: AppColors.primary),
              title: const Text('Homework'),
              subtitle: const Text('A quick task for students'),
              onTap: () {
                Navigator.of(context).pop();
                onCreateHomework?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.fact_check_outlined, color: AppColors.primary),
              title: const Text('Exam'),
              subtitle: const Text('A graded assessment with logistics'),
              onTap: () {
                Navigator.of(context).pop();
                onCreateExam?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz_outlined, color: AppColors.primary),
              title: const Text('Quiz'),
              subtitle: const Text('Auto-graded multiple-choice questions'),
              onTap: () {
                Navigator.of(context).pop();
                onCreateQuiz?.call();
              },
            ),
            const SizedBox(height: AppSpacing.stackMd),
          ],
        ),
      ),
    );
  }
}

/// The scrolling body. Stateful so it can own a [ScrollController] and page in
/// more rows as the user approaches the bottom — no "Load More" button.
class _AssignmentsList extends StatefulWidget {
  final TeacherAssignmentsController controller;
  final VoidCallback onCreate;
  final VoidCallback? onOpenGradebook;
  final VoidCallback? onOpenQuizzes;
  final VoidCallback? onOpenPerformance;

  const _AssignmentsList({
    required this.controller,
    required this.onCreate,
    this.onOpenGradebook,
    this.onOpenQuizzes,
    this.onOpenPerformance,
  });

  @override
  State<_AssignmentsList> createState() => _AssignmentsListState();
}

class _AssignmentsListState extends State<_AssignmentsList> {
  final _scroll = ScrollController();

  /// Distance from the bottom at which the next page starts loading, so rows
  /// are already there by the time the user reaches them.
  static const _prefetchExtent = 400.0;

  /// Key on the list heading, used to scroll the list into view when the
  /// "Active Assignments" stat is tapped.
  final _listAnchor = GlobalKey();

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
    if (remaining <= _prefetchExtent) widget.controller.loadMore();
  }

  void _scrollToList() {
    final ctx = _listAnchor.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: AppMotion.normal, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return RefreshIndicator(
      onRefresh: c.fetch,
      child: Obx(() {
        final stats = c.data.value!.stats;
        final visible = c.visible;
        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              0,
              AppSpacing.containerPaddingMobile,
              120),
          // header + rows + footer
          itemCount: visible.length + 2,
          itemBuilder: (context, i) {
            if (i == 0) return _header(c, stats);
            if (i <= visible.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.stackLg),
                child: AssignmentCard(
                  assignment: visible[i - 1],
                  onTap: widget.onOpenGradebook,
                ),
              );
            }
            return _footer(c, visible.length);
          },
        );
      }),
    );
  }

  Widget _header(TeacherAssignmentsController c, AssignmentStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assignments', style: AppTypography.headlineLg),
        const SizedBox(height: AppSpacing.stackSm),
        Text('Manage and track student coursework across all your classes.',
            style: AppTypography.bodyLg),
        const SizedBox(height: AppSpacing.stackMd),
        PrimaryButton(
          label: 'New Assignment',
          leadingIcon: Icons.add,
          trailingIcon: null,
          onPressed: widget.onCreate,
        ),
        const SizedBox(height: AppSpacing.stackSm),
        GhostButton(
          label: 'Quizzes',
          leadingIcon: Icons.quiz_outlined,
          trailingIcon: Icons.chevron_right_rounded,
          expanded: true,
          onPressed: widget.onOpenQuizzes,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        // Three tappable KPI tiles instead of one stacked panel.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AssignmentStatCard(
                  label: 'To Grade',
                  value: '${stats.toGrade}',
                  trend: '+${stats.toGradeDelta} today',
                  icon: Icons.menu_book_outlined,
                  accent: const Color(0xFFE8A317),
                  trendColor: AppColors.error,
                  onTap: widget.onOpenGradebook,
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Expanded(
                child: AssignmentStatCard(
                  label: 'Active',
                  value: '${stats.activeCount}',
                  trend: '${stats.activeAcrossClasses} classes',
                  icon: Icons.assignment_outlined,
                  accent: AppColors.primary,
                  trendColor: AppColors.onSurfaceVariant,
                  onTap: _scrollToList,
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Expanded(
                child: AssignmentStatCard(
                  label: 'Turn-in Rate',
                  value:
                      '${(stats.averageTurnInRate * 100).toStringAsFixed(0)}%',
                  trend:
                      '+${(stats.averageTurnInDelta * 100).toStringAsFixed(0)}% wk',
                  icon: Icons.group_outlined,
                  accent: AppColors.aiAccent,
                  trendColor: AppColors.tertiary,
                  onTap: widget.onOpenPerformance,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        PortalSearchField(
          hint: 'Search assignments…',
          onChanged: c.onSearch,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Obx(() => FilterChips(
              options: TeacherAssignmentsController.classFilters,
              selectedIndex: c.classFilterIndex.value,
              onSelected: c.selectClass,
            )),
        const SizedBox(height: AppSpacing.stackMd),
        // A thin bar rather than a full-screen spinner, so a filter change
        // never unmounts the list underneath it.
        SizedBox(
          key: _listAnchor,
          height: 2,
          child: c.refreshing.value
              ? const LinearProgressIndicator(minHeight: 2)
              : null,
        ),
        const SizedBox(height: AppSpacing.stackMd),
      ],
    );
  }

  Widget _footer(TeacherAssignmentsController c, int shown) {
    if (c.matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackXl),
        child: Center(
          child: Text('No assignments match your filters.',
              style: AppTypography.bodyLg),
        ),
      );
    }
    if (c.loadingMore.value) {
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
    if (!c.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
        child: Center(
          child: Text("That's all $shown assignments.",
              style: AppTypography.bodySm),
        ),
      );
    }
    return const SizedBox(height: AppSpacing.stackLg);
  }
}
