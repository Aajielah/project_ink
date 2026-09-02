import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_ink/database/database.dart';
import 'package:project_ink/models/project.dart';
import 'package:project_ink/models/schedule.dart';
import 'package:project_ink/models/daily_log.dart';
import 'package:project_ink/repositories/project_repository.dart';
import 'package:project_ink/repositories/schedule_repository.dart';
import 'package:project_ink/repositories/daily_log_repository.dart';
import 'package:project_ink/repositories/settings_repository.dart';
import 'package:project_ink/repositories/statistics_repository.dart';
import 'package:project_ink/shared/providers.dart';
import 'package:project_ink/shared/date_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProjectRepository projectRepo;
  late ScheduleRepository scheduleRepo;
  late DailyLogRepository dailyLogRepo;
  late SettingsRepository settingsRepo;
  late StatisticsRepository statsRepo;
  late ProviderContainer container;

  final today = getLogicalToday();
  final cleanToday = DateTime(today.year, today.month, today.day);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    projectRepo = ProjectRepository(db);
    scheduleRepo = ScheduleRepository(db);
    dailyLogRepo = DailyLogRepository(db);
    settingsRepo = SettingsRepository(db);
    statsRepo = StatisticsRepository(db);

    container = ProviderContainer(
      overrides: [
        dbProvider.overrideWithValue(db),
        projectRepositoryProvider.overrideWithValue(projectRepo),
        scheduleRepositoryProvider.overrideWithValue(scheduleRepo),
        dailyLogRepositoryProvider.overrideWithValue(dailyLogRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        statisticsRepositoryProvider.overrideWithValue(statsRepo),
      ],
    );

    await settingsRepo.getSettings();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Project Cloning & Group ID Tests', () {
    test('fresh project gets groupId equal to its own id', () async {
      final notifier = container.read(projectsProvider.notifier);

      final err = await notifier.addProject(
        name: 'Novel 1',
        projectType: ProjectType.fixed,
        targetWords: 10000,
        dailyWordTarget: 500,
        durationDays: 30,
        startDate: cleanToday,
        restMode: RestMode.flexible,
        fixedRestWeekdays: const [],
        allowedRestDays: 2,
      );

      expect(err, isNull);
      final projects = await projectRepo.getAllProjects();
      expect(projects.length, 1);
      final project = projects.first;
      expect(project.groupId, project.id);
    });

    test('cloned project inherits parent groupId and links them together', () async {
      final notifier = container.read(projectsProvider.notifier);

      // 1. Create parent project (Run 1)
      await notifier.addProject(
        name: 'Epic Fantasy Vol 1',
        projectType: ProjectType.fixed,
        targetWords: 50000,
        dailyWordTarget: 1000,
        durationDays: 60,
        startDate: cleanToday.subtract(const Duration(days: 60)),
        restMode: RestMode.flexible,
        fixedRestWeekdays: const [],
        allowedRestDays: 5,
        coverType: 'default',
        coverImagePath: 'fantasy_cover_1',
        writingSession: 'morning',
      );

      final all1 = await projectRepo.getAllProjects();
      final parent = all1.first;
      expect(parent.groupId, parent.id);

      // 2. Clone to start Run 2 with explicit parent groupId
      final tomorrow = cleanToday.add(const Duration(days: 1));
      await notifier.addProject(
        name: 'Epic Fantasy Vol 2',
        projectType: ProjectType.fixed,
        targetWords: 60000,
        dailyWordTarget: 1200,
        durationDays: 60,
        startDate: tomorrow,
        restMode: RestMode.flexible,
        fixedRestWeekdays: const [],
        allowedRestDays: 5,
        coverType: parent.coverType,
        coverImagePath: parent.coverImagePath,
        writingSession: parent.writingSession,
        groupId: parent.groupId, // Cloned group inheritance!
      );

      final all2 = await projectRepo.getAllProjects();
      expect(all2.length, 2);

      final clone = all2.firstWhere((p) => p.name == 'Epic Fantasy Vol 2');
      expect(clone.id, isNot(parent.id));
      expect(clone.groupId, parent.groupId);
      expect(clone.writingSession, 'morning');
      expect(clone.coverImagePath, 'fantasy_cover_1');
      expect(clone.startDate, tomorrow);
    });

    test('ongoing habit clone inherits ongoing style and group ID', () async {
      final notifier = container.read(projectsProvider.notifier);

      // 1. Create parent ongoing project
      await notifier.addProject(
        name: 'Daily Morning Journal',
        projectType: ProjectType.ongoing,
        targetWords: 0,
        dailyWordTarget: 300,
        durationDays: 0,
        startDate: cleanToday.subtract(const Duration(days: 30)),
        restMode: RestMode.flexible,
        fixedRestWeekdays: const [],
        allowedRestDays: 0,
        ongoingStyle: 'rhythm',
        writingSession: 'evening',
      );

      final parent = (await projectRepo.getAllProjects()).first;

      // 2. Clone ongoing habit
      final tomorrow = cleanToday.add(const Duration(days: 1));
      await notifier.addProject(
        name: 'Daily Morning Journal (Season 2)',
        projectType: ProjectType.ongoing,
        targetWords: 0,
        dailyWordTarget: 400,
        durationDays: 0,
        startDate: tomorrow,
        restMode: RestMode.flexible,
        fixedRestWeekdays: const [],
        allowedRestDays: 0,
        ongoingStyle: 'rhythm',
        writingSession: 'evening',
        groupId: parent.groupId,
      );

      final all = await projectRepo.getAllProjects();
      expect(all.length, 2);

      final clone = all.firstWhere((p) => p.name == 'Daily Morning Journal (Season 2)');
      expect(clone.groupId, parent.groupId);
      expect(clone.ongoingStyle, 'rhythm');
      expect(clone.writingSession, 'evening');
      expect(clone.startDate, tomorrow);
    });
  });
}
