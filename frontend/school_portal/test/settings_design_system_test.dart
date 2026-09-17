import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import 'package:school_portal/school/modules/headmaster/data/headmaster_api_service.dart';
import 'package:school_portal/school/modules/headmaster/data/headmaster_repository.dart';
import 'package:school_portal/school/modules/headmaster/features/settings/controller/settings_controller.dart';
import 'package:school_portal/school/modules/headmaster/features/settings/models/school_profile.dart';
import 'package:school_portal/school/modules/headmaster/features/settings/view/settings_view.dart';

class _SettingsRepository extends HeadmasterRepository {
  _SettingsRepository()
    : super(
        api: HeadmasterApiService(api: ApiService(store: DataStoreService())),
      );

  @override
  Future<ApiResponse<SchoolProfile>> loadSchoolProfile() async {
    return ApiResponse.ok(
      const SchoolProfile(
        id: 'school-1',
        name: 'Meri Taleem School',
        code: 'MTS',
        uniformColor: '#3F51B5',
        feeDueDay: 5,
        salaryDay: 1,
      ),
    );
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  for (final width in [320.0, 1200.0]) {
    testWidgets('settings uses shared components at 200% text on $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repo = _SettingsRepository();
      Get.put<HeadmasterRepository>(repo);
      Get.put<SettingsController>(SettingsController(repo: repo));

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const SettingsView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AppCard), findsAtLeastNWidgets(3));
      expect(find.byType(AppTextField), findsAtLeastNWidgets(1));
      expect(find.text('Meri Taleem School'), findsOneWidget);
      expect(find.bySemanticsLabel('Choose school logo'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Salary payout day'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(find.text('Salary payout day'), findsOneWidget);
    });
  }

  testWidgets('settings fields participate in keyboard focus traversal', (
    tester,
  ) async {
    final repo = _SettingsRepository();
    Get.put<HeadmasterRepository>(repo);
    Get.put<SettingsController>(SettingsController(repo: repo));

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light(), home: const SettingsView()),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final focusedInputs = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .where((input) => input.focusNode.hasFocus);
    expect(focusedInputs, hasLength(1));
  });
}
