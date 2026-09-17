import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/student_routes.dart';
import '../../../../../widgets/dashboard_kit.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../../widgets/student_gradient_header.dart';
import '../../../../../widgets/section_header.dart';
import '../../assignments/components/assignment_card.dart';
import '../../assignments/models/assignment.dart';
import '../../attendance/components/monthly_average_card.dart';
import '../controller/dashboard_controller.dart';
import '../../../../../widgets/skeletons.dart';

/// Student Dashboard — the shared dashboard shape (identity, four numbers, the
/// primary action, then shortcuts) over the student's own live data, followed
/// by the two things only this module has: what is due soon, and the month's
/// attendance detail.
///
/// It used to open with a greeting and a column of eight action rows, which
/// meant the numbers a student actually opens the app for — how is my
/// attendance, what do I owe, when is the next exam — were below the fold.
/// The bell on the top bar opens the Notifications Center.
class DashboardView extends GetView<StudentDashboardController> {
  final VoidCallback? onNotifications;
  final ValueChanged<StudentAssignment>? onOpenAssignment;
  final VoidCallback? onOpenQuizzes;
  const DashboardView({
    super.key,
    this.onNotifications,
    this.onOpenAssignment,
    this.onOpenQuizzes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PortalTopBar(title: 'Meri Taleem', onBell: onNotifications),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const SkeletonPage(
                body: Column(
                  children: [
                    SkeletonStatGrid(count: 4),
                    SizedBox(height: AppSpacing.stackLg),
                    SkeletonCardList(count: 3),
                  ],
                ),
              );
            }
            if (controller.error.value != null) {
              return Center(
                child: Text(
                  controller.error.value!,
                  style: AppTypography.bodyLg,
                ),
              );
            }
            final nextExam = controller.nextExam;
            final dueSoon = controller.dueSoon;
            final attendance = controller.attendance.value;
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  0,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl,
                ),
                children: [
                  const SizedBox(height: AppSpacing.stackSm),
                  StudentGradientHeader(
                    name: controller.fullName,
                    subtitle: controller.roleLine,
                    avatarUrl: controller.avatarUrl,
                  ),
                  const SizedBox(height: AppSpacing.stackLg),

                  const SectionHeader(title: 'Your progress'),
                  const SizedBox(height: AppSpacing.stackMd),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: DashboardStatGrid(
                      stats: [
                        DashboardStat(
                          icon: AppIcons.eventAvailableRounded,
                          accent: AppColors.tertiary,
                          value: '${controller.attendancePercent}%',
                          label: 'Attendance',
                          sub: 'This month',
                        ),
                        DashboardStat(
                          icon: AppIcons.assignmentOutlined,
                          accent: const Color(0xFFE8A317),
                          value: '${controller.toDoCount}',
                          label: 'Pending homework',
                          sub: controller.toDoCount == 0
                              ? 'All clear'
                              : 'Due soon',
                        ),
                        DashboardStat(
                          icon: AppIcons.factCheckOutlined,
                          accent: AppColors.primary,
                          value: '${controller.examsThisMonth}',
                          label: 'Exams',
                          sub: 'This month',
                        ),
                        DashboardStat(
                          icon: AppIcons.timerOutlined,
                          accent: AppColors.secondary,
                          // An em dash rather than "0d": no exam scheduled and an
                          // exam today are not the same thing, and "0" reads as
                          // the second one.
                          value: controller.daysToNextExam == null
                              ? '—'
                              : '${controller.daysToNextExam}d',
                          label: 'Next exam',
                          sub: nextExam?.title ?? 'None scheduled',
                          onTap: controller.nextExamEntry == null
                              ? null
                              : () => Get.toNamed(
                                  StudentRoutes.examDetail,
                                  arguments: controller.nextExamEntry,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),

                  const SectionHeader(title: 'Explore & learn'),
                  const SizedBox(height: AppSpacing.stackMd),
                  DashboardQuickLinks(
                    links: [
                      DashboardLink(
                        icon: AppIcons.gradingRounded,
                        label: 'My Results',
                        onTap: () => Get.toNamed(StudentRoutes.results),
                      ),
                      DashboardLink(
                        icon: AppIcons.calendarMonthOutlined,
                        label: 'Timetable',
                        onTap: () => Get.toNamed(StudentRoutes.timetable),
                      ),
                      DashboardLink(
                        icon: AppIcons.quizRounded,
                        label: 'Quizzes',
                        onTap: onOpenQuizzes,
                      ),
                      DashboardLink(
                        icon: AppIcons.menuBookRounded,
                        label: 'Courses',
                        onTap: () => Get.toNamed(StudentRoutes.courses),
                      ),
                      DashboardLink(
                        icon: AppIcons.forumOutlined,
                        label: 'Messages',
                        onTap: () => Get.toNamed(StudentRoutes.messages),
                      ),
                      DashboardLink(
                        icon: AppIcons.apartmentRounded,
                        label: 'My School',
                        onTap: () => Get.toNamed(StudentRoutes.schoolInfo),
                      ),
                      DashboardLink(
                        icon: AppIcons.directionsBusOutlined,
                        label: 'Transport',
                        onTap: () => Get.toNamed(StudentRoutes.transport),
                      ),
                      DashboardLink(
                        icon: AppIcons.eventBusyRounded,
                        label: 'Apply for leave',
                        onTap: () => Get.toNamed(StudentRoutes.leave),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackLg),

                  // Assignments due soon.
                  const SectionHeader(title: 'Due Soon'),
                  const SizedBox(height: AppSpacing.stackMd),
                  if (dueSoon.isEmpty)
                    _EmptyHint(text: "You're all caught up — nothing due.")
                  else
                    for (final a in dueSoon) ...[
                      FadeSlideIn(
                        child: AssignmentCard(
                          assignment: a,
                          onTap: () => onOpenAssignment?.call(a),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                    ],
                  const SizedBox(height: AppSpacing.stackSm),

                  // Attendance detail.
                  if (attendance != null)
                    AttendanceRingCard(
                      percent: attendance.monthlyAverage,
                      delta: attendance.deltaPercent,
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Row(
        children: [
          const Icon(
            AppIcons.checkCircleOutlineRounded,
            color: AppColors.tertiary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(child: Text(text, style: AppTypography.bodyMd)),
        ],
      ),
    );
  }
}
