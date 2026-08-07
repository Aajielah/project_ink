import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/database/database.dart';
import '../lib/models/project.dart';
import '../lib/models/schedule.dart';
import '../lib/models/daily_log.dart';
import '../lib/repositories/project_repository.dart';
import '../lib/repositories/schedule_repository.dart';
import '../lib/repositories/daily_log_repository.dart';
import '../lib/repositories/statistics_repository.dart';
import '../lib/services/ongoing_sync_service.dart';
import '../lib/services/scheduling_service.dart';
import '../lib/shared/providers.dart';
import '../lib/shared/date_utils.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository projectRepo;
  late ScheduleRepository scheduleRepo;
  late DailyLogRepository dailyLogRepo;
  late StatisticsRepository statsRepo;
  late OngoingSyncService syncService;
  late SchedulingService schedulingService;
  late ProviderContainer container;

  final today = getLogicalToday();
  final cleanToday = DateTime(today.year, today.month, today.day);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    projectRepo = ProjectRepository(db);
    scheduleRepo = ScheduleRepository(db);
    dailyLogRepo = DailyLogRepository(db);
    statsRepo = StatisticsRepository(db);

    container = ProviderContainer(
      overrides: [
        dbProvider.overrideWithValue(db),
        projectRepositoryProvider.overrideWithValue(projectRepo),
        scheduleRepositoryProvider.overrideWithValue(scheduleRepo),
        dailyLogRepositoryProvider.overrideWithValue(dailyLogRepo),
        statisticsRepositoryProvider.overrideWithValue(statsRepo),
      ],
    );

    syncService = container.read(ongoingSyncServiceProvider);
    schedulingService = container.read(schedulingServiceProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('Run 200+ Matrix of Rest Mode, Rollover, and Edit Edge Cases', () async {
    final restModes = [RestMode.fixed, RestMode.flexible, RestMode.adaptive, RestMode.sprint];
    final startOffsets = [-14, -10, -7, -4, -1, 0];
    final durations = [3, 7, 10, 14, 30];
    final budgets = [1, 2, 4];
    final behaviors = [1, 2, 3, 4]; // 1: Perfect, 2: Miss all, 3: Under target, 4: Alternate

    int runCount = 0;

    for (final restMode in restModes) {
      for (final offset in startOffsets) {
        for (final duration in durations) {
          for (final budget in budgets) {
            for (final behavior in behaviors) {
              // Exclude sprint mode invalid durations (>10 days) or 0 budgets
              if (restMode == RestMode.sprint && duration > 10) continue;

              final startDate = cleanToday.add(Duration(days: offset));
              final expectedFinishDate = startDate.add(Duration(days: duration - 1));

              // If expected finish date is in the past, or start date is after today, we skip to keep it active
              if (expectedFinishDate.isBefore(cleanToday) || startDate.isAfter(cleanToday)) continue;

              runCount++;
              final projectId = 'p_matrix_$runCount';
              final targetWords = duration * 500;
              final dailyTarget = 500;

              // Create project model
              final project = ProjectModel(
                id: projectId,
                name: 'Matrix Project $runCount',
                status: ProjectStatus.active,
                projectType: ProjectType.fixed,
                targetWords: targetWords,
                writtenWords: 0,
                remainingWords: targetWords,
                dailyWordTarget: dailyTarget,
                backlogWords: 0,
                startDate: startDate,
                expectedFinishDate: expectedFinishDate,
                restMode: restMode,
                allowedRestDays: budget,
                remainingRestDays: budget,
                projectStreak: 0,
                longestProjectStreak: 0,
                currentWeek: 1,
                createdAt: startDate,
                updatedAt: startDate,
              );

              await projectRepo.insertProject(project);

              // Generate schedules
              final initialSchedules = schedulingService.generateInitialSchedule(
                projectId: projectId,
                startDate: startDate,
                targetWords: targetWords,
                dailyWordTarget: dailyTarget,
                durationDays: duration,
                restMode: restMode,
                fixedRestWeekdays: const [],
                allowedRestDays: budget,
              );
              await scheduleRepo.insertSchedules(initialSchedules);

              // Simulate logging history up to yesterday
              var tempDate = startDate;
              while (tempDate.isBefore(cleanToday)) {
                final s = await scheduleRepo.getScheduleForDate(projectId, tempDate);
                if (s != null && !s.isRestDay) {
                  int actual = 0;
                  if (behavior == 1) {
                    actual = s.plannedWords;
                  } else if (behavior == 2) {
                    actual = 0;
                  } else if (behavior == 3) {
                    actual = s.plannedWords ~/ 2;
                  } else if (behavior == 4) {
                    // Alternate 0 and target*2
                    actual = (tempDate.day % 2 == 0) ? 0 : s.plannedWords * 2;
                  }

                  if (actual > 0) {
                    await dailyLogRepo.insertLog(DailyLogModel(
                      id: 'log_${projectId}_${tempDate.millisecondsSinceEpoch}',
                      projectId: projectId,
                      scheduleId: s.id,
                      date: tempDate,
                      plannedWords: s.plannedWords,
                      actualWords: actual,
                      carryForwardWords: 0,
                      backlogCreated: 0,
                      completed: actual >= s.plannedWords,
                      loggedAt: tempDate,
                    ));
                  }
                }
                tempDate = tempDate.add(const Duration(days: 1));
              }

              // Run database sync
              await syncService.syncFixedGoalBacklogs([project]);

              // Verify the synchronized project record
              final syncedProj = await projectRepo.getProjectById(projectId);
              if (syncedProj == null) {
                fail('Project not found after sync: $projectId');
              }

              // Assert weekly transitions occurred
              final expectedWeek = (getDaysDifference(startDate, cleanToday) ~/ 7) + 1;
              expect(syncedProj.currentWeek, expectedWeek);

              // Verify remaining rest days bounds
              if (syncedProj.remainingRestDays > syncedProj.allowedRestDays) {
                print('FAILING CASE: restMode=${project.restMode}, offset=$offset, duration=$duration, budget=$budget, behavior=$behavior');
                print('syncedProj.remainingRestDays=${syncedProj.remainingRestDays}, allowedRestDays=${syncedProj.allowedRestDays}');
              }
              expect(syncedProj.remainingRestDays >= 0, isTrue);
              expect(syncedProj.remainingRestDays <= syncedProj.allowedRestDays, isTrue);

              // Assert no negative targets in schedules
              final schedulesAfterSync = await scheduleRepo.getSchedulesForProject(projectId);
              for (final s in schedulesAfterSync) {
                expect(s.plannedWords >= 0, isTrue);
              }

              // --- TEST TRANSITION (Adaptive <-> Flexible) ---
              final currentMode = syncedProj.restMode;
              final targetMode = currentMode == RestMode.adaptive ? RestMode.flexible : RestMode.adaptive;

              final updatedProjectTemp = syncedProj.copyWith(
                restMode: targetMode,
              );

              final dynamicRemainingRestDays = schedulingService.getAvailableRestDays(
                project: updatedProjectTemp,
                schedules: schedulesAfterSync,
                logicalToday: cleanToday,
              );

              expect(dynamicRemainingRestDays >= 0, isTrue);
              expect(dynamicRemainingRestDays <= updatedProjectTemp.allowedRestDays, isTrue);
            }
          }
        }
      }
    }

    print('Successfully completed $runCount matrix edge cases!');
    expect(runCount >= 200, isTrue);
  });
}
