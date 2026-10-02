import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../config/headmaster_routes.dart';

/// Home screen for finance staff. Every destination is a fee or payroll screen
/// shared with the Headmaster; refunds, credits, waivers and payroll
/// corrections made here are requests that the Headmaster approves.
class AccountantShell extends StatelessWidget {
  const AccountantShell({super.key});

  static const _destinations = <_Destination>[
    _Destination(
      'Record a payment',
      'Find a student and record a fee payment',
      AppIcons.paymentsOutlined,
      HeadmasterRoutes.recordPayment,
    ),
    _Destination(
      'Student fees',
      'Every student\'s invoices and balance',
      AppIcons.receiptLongOutlined,
      HeadmasterRoutes.feesRoster,
    ),
    _Destination(
      'Overdue payments',
      'Invoices past their due date',
      AppIcons.warningAmberRounded,
      HeadmasterRoutes.overduePayments,
    ),
    _Destination(
      'Refunds, credits and waivers',
      'Your requests and the Headmaster\'s decisions',
      AppIcons.tuneRounded,
      HeadmasterRoutes.financialAdjustments,
    ),
    _Destination(
      'Salaries and payslips',
      'Generate payslips and mark them paid',
      AppIcons.accountBalanceOutlined,
      HeadmasterRoutes.salary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final name =
        Get.find<AuthService>().currentUser.value?['full_name']?.toString() ??
        '';
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Finance'),
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
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.containerPaddingMobile),
        children: [
          Text(
            name.isEmpty ? 'Welcome' : 'Welcome, $name',
            style: AppTypography.titleLg,
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            'Refunds, credits, waivers and salary corrections you submit are '
            'sent to the Headmaster for approval.',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          for (final destination in _destinations)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
              child: ListTile(
                leading: Icon(destination.icon, color: AppColors.primary),
                title: Text(destination.title),
                subtitle: Text(destination.subtitle),
                trailing: const Icon(AppIcons.chevronRightRounded),
                onTap: () => Get.toNamed(destination.route),
              ),
            ),
        ],
      ),
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

class _Destination {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  const _Destination(this.title, this.subtitle, this.icon, this.route);
}
