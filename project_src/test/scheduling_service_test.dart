import 'package:flutter_test/flutter_test.dart';
import '../lib/models/project.dart';
import '../lib/models/schedule.dart';
import '../lib/services/scheduling_service.dart';

void main() {
  late SchedulingService schedulingService;

  setUp(() {
    schedulingService = const SchedulingService();
  });

  group('SchedulingService - Input Validation', () {
    test('rejects negative target words', () {
      final err = schedulingService.validateInputs(
        targetWords: -100,
        dailyWordTarget: 500,
        durationDays: 10,
        restMode: RestMode.flexible,
        allowedRestDays: 1,
      );
      expect(err, isNotNull);
      expect(err, contains('Target words must be greater than zero'));
    });

    test('rejects impossible target words given duration and daily target', () {
      final err = schedulingService.validateInputs(
        targetWords: 1000,
        dailyWordTarget: 100,
        durationDays: 10,
        restMode: RestMode.adaptive,
        allowedRestDays: 1,
      );
      expect(err, isNotNull);
      expect(err, contains('This configuration cannot complete your project. Reduce your total rest days, increase your daily target, or extend the project duration.'));
    });

    test('accepts valid schedule parameters', () {
      final err = schedulingService.validateInputs(
        targetWords: 1000,
        dailyWordTarget: 200,
        durationDays: 10,
        restMode: RestMode.flexible,
        allowedRestDays: 1,
      );
      expect(err, isNull);
    });
  });

  group('SchedulingService - Initial Schedule Generation', () {
    test('correctly configures Fixed rest days', () {
      final start = DateTime(2026, 7, 6); // Monday
      // 7 days, Monday to Sunday. Fixed rest days: Saturday (6) and Sunday (7).
      final list = schedulingService.generateInitialSchedule(
        projectId: 'test_project',
        startDate: start,
        targetWords: 1000,
        dailyWordTarget: 200,
        durationDays: 7,
        restMode: RestMode.fixed,
        fixedRestWeekdays: const [6, 7],
        allowedRestDays: 0,
      );

      expect(list.length, 7);
      // Sat/Sun should be rest days
      expect(list[5].isRestDay, isTrue); // Sat
      expect(list[6].isRestDay, isTrue); // Sun
      // Mon-Fri should be writing days
      for (int i = 0; i < 5; i++) {
        expect(list[i].isRestDay, isFalse);
        expect(list[i].plannedWords, 200);
      }
    });

    test('correctly distributes Random rest days', () {
      final start = DateTime(2026, 7, 6); // Monday
      // 10 days, Random rest days: 2 days allowed per week block.
      final list = schedulingService.generateInitialSchedule(
        projectId: 'test_project',
        startDate: start,
        targetWords: 1000,
        dailyWordTarget: 250,
        durationDays: 10,
        restMode: RestMode.adaptive,
        fixedRestWeekdays: const [],
        allowedRestDays: 2,
      );

      expect(list.length, 10);
      
      // Count rest days in first week (first 7 days)
      final week1Rest = list.sublist(0, 7).where((s) => s.isRestDay).length;
      expect(week1Rest, 0);

      // Count rest days in second week block (remaining 3 days)
      final week2Rest = list.sublist(7, 10).where((s) => s.isRestDay).length;
      expect(week2Rest, 0);
    });
  });

  group('SchedulingService - Future Recalculation', () {
    test('preserves locked schedules and recalculates unlocked future ones', () {
      final start = DateTime(2026, 7, 6);
      final list = <ScheduleModel>[
        ScheduleModel(
          id: '1', projectId: 'p', date: start, plannedWords: 200,
          isRestDay: false, completed: true, automaticRestDay: false, locked: true,
        ),
        ScheduleModel(
          id: '2', projectId: 'p', date: start.add(const Duration(days: 1)), plannedWords: 200,
          isRestDay: false, completed: false, automaticRestDay: false, locked: false,
        ),
        ScheduleModel(
          id: '3', projectId: 'p', date: start.add(const Duration(days: 2)), plannedWords: 200,
          isRestDay: false, completed: false, automaticRestDay: false, locked: false,
        ),
      ];

      final recalculated = schedulingService.recalculateFutureSchedule(
        existingSchedules: list,
        recalculateFromDate: start.add(const Duration(days: 1)),
        newDailyTarget: 300,
        totalRemainingWords: 600,
        fixedRestWeekdays: const [],
        restMode: RestMode.flexible,
        allowedRestDaysBudget: 0,
        restDaysUsed: 0,
      );

      expect(recalculated.length, 3);
      expect(recalculated[0].locked, isTrue);
      expect(recalculated[0].plannedWords, 200); // untouched

      expect(recalculated[1].plannedWords, 300); // updated
      expect(recalculated[2].plannedWords, 300); // updated
    });
  });
}
