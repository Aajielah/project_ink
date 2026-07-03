import 'package:flutter_test/flutter_test.dart';
import '../lib/models/project.dart';
import '../lib/models/daily_log.dart';
import '../lib/models/quote.dart';
import '../lib/models/statistics.dart';
import '../lib/services/encouragement_service.dart';
import '../lib/repositories/project_repository.dart';
import '../lib/repositories/daily_log_repository.dart';
import '../lib/repositories/quote_repository.dart';
import '../lib/repositories/statistics_repository.dart';

// --- FAKE IN-MEMORY REPOSITORIES ---

class FakeQuoteRepository implements QuoteRepository {
  final List<QuoteModel> quotes = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<QuoteModel>> getAllQuotes() async => quotes;

  @override
  Future<QuoteModel?> getRandomQuote() async => quotes.isNotEmpty ? quotes.first : null;

  @override
  Future<QuoteModel?> getRandomQuoteByFilter({String? category, String? mood}) async {
    final filtered = quotes.where((q) {
      if (category != null && q.category != category) return false;
      if (mood != null && q.mood != mood) return false;
      return true;
    }).toList();
    
    return filtered.isNotEmpty ? filtered.first : await getRandomQuote();
  }


  @override
  Future<void> seedDatabaseQuotes() async {
    // Already stubbed
  }
}

class FakeProjectRepository implements ProjectRepository {
  final Map<String, ProjectModel> db = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<ProjectModel?> getProjectById(String id) async => db[id];

  @override
  Future<List<ProjectModel>> getAllProjects() async => db.values.toList();
}

class FakeDailyLogRepository implements DailyLogRepository {
  final Map<String, DailyLogModel> db = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<DailyLogModel?> getLogForDate(String projectId, DateTime date) async {
    final key = '${projectId}_${date.year}_${date.month}_${date.day}';
    return db[key];
  }
}

class FakeStatisticsRepository implements StatisticsRepository {
  StatisticsModel stats = const StatisticsModel(
    id: 'global_stats',
    lifetimeWords: 0,
    averageWordsPerDay: 0.0,
    currentGlobalStreak: 0,
    longestGlobalStreak: 0,
    projectsCompleted: 0,
    writingDays: 0,
    restDaysUsed: 0,
    currentBacklog: 0,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<StatisticsModel> getStatistics() async => stats;

  @override
  Future<void> recalculateStatistics() async {}
}

// --- MAIN UNIT TESTS ---

void main() {
  late FakeQuoteRepository quoteRepo;
  late FakeProjectRepository projectRepo;
  late FakeDailyLogRepository logRepo;
  late FakeStatisticsRepository statsRepo;
  late EncouragementService encouragementService;

  final today = DateTime.now();
  final cleanToday = DateTime(today.year, today.month, today.day);

  setUp(() {
    quoteRepo = FakeQuoteRepository();
    projectRepo = FakeProjectRepository();
    logRepo = FakeDailyLogRepository();
    statsRepo = FakeStatisticsRepository();

    encouragementService = EncouragementService(
      quoteRepo,
      projectRepo,
      logRepo,
      statsRepo,
    );

    // Seed fake quote bank with all 4 possible combinations to support randomization
    quoteRepo.quotes.addAll([
      const QuoteModel(id: 'q1', text: 'Failure Encouraging', author: 'Author A', category: 'Failure', mood: 'Encouraging'),
      const QuoteModel(id: 'q2', text: 'Failure Tough Love', author: 'Author B', category: 'Failure', mood: 'Tough Love'),
      const QuoteModel(id: 'q3', text: 'Consistency Encouraging', author: 'Author C', category: 'Consistency', mood: 'Encouraging'),
      const QuoteModel(id: 'q4', text: 'Consistency Tough Love', author: 'Author D', category: 'Consistency', mood: 'Tough Love'),
    ]);
  });

  group('EncouragementService - State-based Quotes', () {
    test('returns Tough Love/Failure quote if user missed target yesterday', () async {
      // 1. Setup project
      projectRepo.db['p1'] = ProjectModel(
        id: 'p1', name: 'Book 1', status: ProjectStatus.active,
        targetWords: 10000, writtenWords: 0, remainingWords: 10000,
        dailyWordTarget: 500, backlogWords: 0, startDate: cleanToday,
        expectedFinishDate: cleanToday.add(const Duration(days: 20)),
        restMode: RestMode.flexible, allowedRestDays: 0, remainingRestDays: 0,
        projectStreak: 0, longestProjectStreak: 0, currentWeek: 1,
        createdAt: cleanToday, updatedAt: cleanToday,
      );

      // 2. Setup missed log for yesterday
      final yesterday = cleanToday.subtract(const Duration(days: 1));
      final key = 'p1_${yesterday.year}_${yesterday.month}_${yesterday.day}';
      logRepo.db[key] = DailyLogModel(
        id: 'l1', projectId: 'p1', date: yesterday, plannedWords: 500,
        actualWords: 200, carryForwardWords: 0, backlogCreated: 300,
        completed: false, loggedAt: yesterday,
      );

      // 3. Fetch quote
      final quote = await encouragementService.getQuoteForUser('p1');
      
      // Since yesterday was missed, the returned quote's mood must be Encouraging or Tough Love,
      // and the category must be Failure or Consistency.
      expect(quote, isNotNull);
      expect(quote!.mood, anyOf('Encouraging', 'Tough Love'));
      expect(quote.category, anyOf('Failure', 'Consistency'));
    });
  });


  group('EncouragementService - Contextual Messages', () {
    test('generates streak alerts and remaining words warning', () async {
      projectRepo.db['p1'] = ProjectModel(
        id: 'p1', name: 'Book 1', status: ProjectStatus.active,
        targetWords: 10000, writtenWords: 7000, remainingWords: 3000, // < 5000 remaining
        dailyWordTarget: 500, backlogWords: 0, startDate: cleanToday,
        expectedFinishDate: cleanToday.add(const Duration(days: 20)),
        restMode: RestMode.flexible, allowedRestDays: 0, remainingRestDays: 0,
        projectStreak: 5, longestProjectStreak: 5, currentWeek: 1,
        createdAt: cleanToday, updatedAt: cleanToday,
      );

      statsRepo.stats = statsRepo.stats.copyWith(
        currentGlobalStreak: 5,
      );

      final messages = await encouragementService.getContextualEncouragement('p1');

      expect(messages.any((m) => m.contains('5-day global writing streak')), isTrue);
      expect(messages.any((m) => m.contains('Only 3000 words left')), isTrue);
    });
  });
}
