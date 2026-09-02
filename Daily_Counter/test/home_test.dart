import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:daily_counter/core/services/database_service.dart';
import 'package:daily_counter/core/services/database_providers.dart';
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
    tempDir = Directory.systemTemp.createTempSync('isar_home_test');
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

  test('HomeController active projects listing and check-off disappear logic test', () async {
    // 1. Create one active project and one future project
    final activeProject = Project()
      ..title = 'Active Novel'
      ..category = 'Reading'
      ..motivation = 'Write every day'
      ..targetDays = 90
      ..completedDays = 10
      ..trackingMode = 'strict'
      ..status = 'active'
      ..startDate = DateTime.now().subtract(const Duration(days: 10))
      ..endDate = DateTime.now().add(const Duration(days: 80))
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..reminderEnabled = true;

    final futureProject = Project()
      ..title = 'Future Project'
      ..category = 'Fitness'
      ..motivation = 'Starts next week'
      ..targetDays = 30
      ..completedDays = 0
      ..trackingMode = 'strict'
      ..status = 'active'
      ..startDate = DateTime.now().add(const Duration(days: 7))
      ..endDate = DateTime.now().add(const Duration(days: 37))
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..reminderEnabled = true;

    await dbService.saveProject(activeProject);
    await dbService.saveProject(futureProject);

    // 2. Set up Riverpod Container and override providers
    final container = ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
      ],
    );

    // Read homeControllerProvider and await initial loading
    final initialData = await container.read(homeControllerProvider.future);

    // Verify only the active project due today is returned in dueToday
    expect(initialData.dueToday.length, equals(1));
    expect(initialData.dueToday.first.title, equals('Active Novel'));
    expect(initialData.completedToday, isEmpty);
    expect(initialData.totalActive, equals(2));

    // 3. Complete the active project for today
    await container.read(homeControllerProvider.notifier).completeProject(activeProject.id);

    // Await the new dashboard state
    final updatedData = await container.read(homeControllerProvider.future);

    // Verify the project disappears from dueToday and appears in completedToday
    expect(updatedData.dueToday, isEmpty);
    expect(updatedData.completedToday.length, equals(1));
    expect(updatedData.completedToday.first.title, equals('Active Novel'));

    // 4. Verify database state is updated correctly
    final savedRecord = await dbService.getRecordForDate(activeProject.id, DateTime.now());
    expect(savedRecord, isNotNull);
    expect(savedRecord!.status, equals('completed'));

    final updatedProject = await dbService.getProject(activeProject.id);
    expect(updatedProject, isNotNull);
    expect(updatedProject!.completedDays, equals(11));
  });
}
