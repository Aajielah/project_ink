import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:daily_counter/core/services/database_service.dart';
import 'package:daily_counter/core/services/database_providers.dart';
import 'package:daily_counter/main.dart';
import 'package:daily_counter/shared/models/project.dart';
import 'package:daily_counter/shared/models/daily_record.dart';
import 'package:daily_counter/shared/models/pause.dart';
import 'package:daily_counter/shared/models/target_change_log.dart';
import 'package:daily_counter/shared/models/settings.dart';
import 'package:daily_counter/features/home/presentation/home_controller.dart';

void main() {
  late Directory tempDir;
  late Isar isar;
  late DatabaseService dbService;

  setUpAll(() async {
    try {
      await Isar.initializeIsarCore(download: true);
    } catch (_) {}
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('isar_widget_test');
    isar = await Isar.open(
      [
        ProjectSchema,
        DailyRecordSchema,
        PauseSchema,
        TargetChangeLogSchema,
        SettingsSchema,
      ],
      directory: tempDir.path,
    );
    dbService = DatabaseService(isar);
  });

  tearDown(() async {
    await isar.close();
    tempDir.deleteSync(recursive: true);
  });

  testWidgets('Daily Counter basic app smoke test', (WidgetTester tester) async {
    // Run the widget test inside runAsync because Isar uses native FFI database threads
    // which cannot resolve within the standard FakeAsync zone of testWidgets.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseServiceProvider.overrideWithValue(dbService),
          ],
          child: const MyApp(),
        ),
      );

      // Pump once to start routing
      await tester.pump();

      // Resolve the HomeController's initial async load from Isar
      final Element element = tester.element(find.byType(MyApp));
      final container = ProviderScope.containerOf(element);
      await container.read(homeControllerProvider.future);

      // Pump another frame to update UI from Loading to Empty State
      await tester.pump();

      // Verify that the home page displays the app title
      expect(find.text('Daily Counter'), findsOneWidget);

      // Verify that the empty state is displayed
      expect(find.text('No active trackers today. Create a new promise to yourself to begin.'), findsOneWidget);
    });
  });
}
