import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_portal/school/widgets/attachment_download_dialog.dart';

void main() {
  testWidgets(
    'prepares before a separate download gesture and handles launch failure',
    (tester) async {
      final ready = Completer<Uri>();
      var launches = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AttachmentDownloadDialog(
            resolve: () => ready.future,
            launch: (_) async {
              launches++;
              return false;
            },
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      ready.complete(
        Uri.parse('https://school.example/api/v1/file-download?ticket=test'),
      );
      await tester.pumpAndSettle();
      expect(launches, 0);
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();
      expect(launches, 1);
      expect(
        find.text('Could not open the download. Please retry.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    },
  );

  testWidgets(
    'access error can retry without exposing backend exception or ticket',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AttachmentDownloadDialog(
            resolve: () async {
              if (++calls == 1) throw StateError('sensitive-token');
              return Uri.parse(
                'https://school.example/api/v1/file-download?ticket=test',
              );
            },
            launch: (_) async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('sensitive-token'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(
        find.text('Your download is ready. This link expires shortly.'),
        findsOneWidget,
      );
    },
  );
}
