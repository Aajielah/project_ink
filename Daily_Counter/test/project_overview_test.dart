import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:daily_counter/core/services/database_service.dart';
import 'package:daily_counter/core/services/database_providers.dart';
import 'package:daily_counter/core/utils/duration_utils.dart';
import 'package:daily_counter/shared/models/project.dart';
import 'package:daily_counter/shared/models/daily_record.dart';
import 'package:daily_counter/shared/models/pause.dart';
import 'package:daily_counter/shared/models/target_change_log.dart';
import 'package:daily_counter/shared/models/settings.dart';
import 'package:daily_counter/features/projects/presentation/project_overview_controller.dart';

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
    tempDir = Directory.systemTemp.createTempSync('isar_overview_test');
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

  test('ProjectOverviewController loads state and handles check-in for today', () async {
    final today = DurationUtils.normalizeDate(DateTime.now());
    final project = Project()
      ..title = 'Daily Study'
      ..category = 'Study'
      ..motivation = 'Knowledge is power'
      ..targetDays = 100
      ..completedDays = 10
      ..trackingMode = 'strict'
      ..status = 'active'
      ..startDate = today.subtract(const Duration(days: 10))
      ..endDate = today.add(const Duration(days: 90))
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..reminderEnabled = true;

    final id = await dbService.saveProject(project);

    final container = ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
      ],
    );

    // Initial load
    final state = await container.read(projectOverviewControllerProvider(id).future);
    expect(state.project, isNotNull);
    expect(state.project!.title, equals('Daily Study'));
    expect(state.completedDaysCount, equals(0)); // No explicit DailyRecord yet

    // Check in today
    await container.read(projectOverviewControllerProvider(id).notifier).checkInToday();

    final updatedState = await container.read(projectOverviewControllerProvider(id).future);
    expect(updatedState.completedDaysCount, equals(1));
    expect(updatedState.project!.completedDays, equals(11));

    final record = await dbService.getRecordForDate(id, today);
    expect(record, isNotNull);
    expect(record!.status, equals('completed'));
  });

  test('Trust Mode Option 1: Marking past day as missed updates record and decrements completed count', () async {
    final today = DurationUtils.normalizeDate(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    final project = Project()
      ..title = 'Trust Coding'
      ..category = 'Work'
      ..motivation = 'Code daily'
      ..targetDays = 50
      ..completedDays = 5
      ..trackingMode = 'trust'
      ..status = 'active'
      ..startDate = today.subtract(const Duration(days: 5))
      ..endDate = today.add(const Duration(days: 45))
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..reminderEnabled = true;

    final id = await dbService.saveProject(project);

    // Save a completed record for yesterday
    final completedRecord = DailyRecord()
      ..projectId = id
      ..date = yesterday
      ..status = 'completed'
      ..automatic = true
      ..modified = false
      ..createdAt = DateTime.now();
    await dbService.saveRecord(completedRecord);

    final container = ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
      ],
    );

    var state = await container.read(projectOverviewControllerProvider(id).future);
    expect(state.completedDaysCount, equals(1));

    // Mark yesterday as missed (User changes mind in Trust Mode)
    await container.read(projectOverviewControllerProvider(id).notifier).markDayAsMissed(yesterday);

    state = await container.read(projectOverviewControllerProvider(id).future);
    expect(state.missedDaysCount, equals(1));
    expect(state.completedDaysCount, equals(0));
    expect(state.project!.completedDays, equals(4)); // Decremented from 5 to 4

    final updatedRecord = await dbService.getRecordForDate(id, yesterday);
    expect(updatedRecord, isNotNull);
    expect(updatedRecord!.status, equals('missed'));
  });

  test('Week pagination advances and rewinds currentWeekMonday', () async {
    final today = DurationUtils.normalizeDate(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final project = Project()
      ..title = 'Pagination Test'
      ..category = 'Fitness'
      ..motivation = 'Move'
      ..targetDays = 30
      ..completedDays = 0
      ..trackingMode = 'strict'
      ..status = 'active'
      ..startDate = today
      ..endDate = today.add(const Duration(days: 30))
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..reminderEnabled = true;

    final id = await dbService.saveProject(project);

    final container = ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
      ],
    );

    var state = await container.read(projectOverviewControllerProvider(id).future);
    expect(state.currentWeekMonday, equals(monday));

    // Next week
    container.read(projectOverviewControllerProvider(id).notifier).nextWeek();
    state = await container.read(projectOverviewControllerProvider(id).future);
    expect(state.currentWeekMonday, equals(monday.add(const Duration(days: 7))));

    // Prev week
    container.read(projectOverviewControllerProvider(id).notifier).previousWeek();
    state = await container.read(projectOverviewControllerProvider(id).future);
    expect(state.currentWeekMonday, equals(monday));
  });
}
