import 'dart:math';
import '../models/project.dart';
import '../models/quote.dart';
import '../models/statistics.dart';
import '../repositories/project_repository.dart';
import '../repositories/daily_log_repository.dart';
import '../repositories/quote_repository.dart';
import '../repositories/statistics_repository.dart';

class EncouragementService {
  final QuoteRepository _quoteRepo;
  final ProjectRepository _projectRepo;
  final DailyLogRepository _logRepo;
  final StatisticsRepository _statsRepo;

  const EncouragementService(
    this._quoteRepo,
    this._projectRepo,
    this._logRepo,
    this._statsRepo,
  );

  /// Intelligently selects a motivational quote based on user state.
  Future<QuoteModel?> getQuoteForUser(String? activeProjectId) async {
    // Ensure database is seeded
    await _quoteRepo.seedDatabaseQuotes();

    if (activeProjectId == null) {
      // Fetch random inspirational/calm quote for the home dashboard
      return _quoteRepo.getRandomQuoteByFilter(mood: 'Inspirational');
    }

    final project = await _projectRepo.getProjectById(activeProjectId);
    if (project == null) {
      return _quoteRepo.getRandomQuote();
    }

    // 1. Check if user missed target yesterday
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final cleanYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final yesterdayLog = await _logRepo.getLogForDate(activeProjectId, cleanYesterday);

    if (yesterdayLog != null && !yesterdayLog.completed) {
      // Missed yesterday's target -> Give them Encouragement or Tough Love
      final mood = Random().nextBool() ? 'Encouraging' : 'Tough Love';
      final category = Random().nextBool() ? 'Failure' : 'Consistency';
      return _quoteRepo.getRandomQuoteByFilter(category: category, mood: mood);
    }

    // 2. Check if project is on a streak
    if (project.projectStreak >= 3) {
      // On a streak -> Give them Inspirational or discipline persistence
      final categories = ['Discipline', 'Persistence', 'Focus'];
      final randomCategory = categories[Random().nextInt(categories.length)];
      return _quoteRepo.getRandomQuoteByFilter(category: randomCategory, mood: 'Inspirational');
    }

    // Default: return a random writing-related quote
    return _quoteRepo.getRandomQuoteByFilter(category: 'Writing');
  }

  /// Generates contextual, personal encouragement messages separate from quotes.
  Future<List<String>> getContextualEncouragement(String? activeProjectId) async {
    final List<String> messages = [];
    final stats = await _statsRepo.getStatistics();

    // 1. Global streak check
    if (stats.currentGlobalStreak >= 3) {
      messages.add('🔥 ${stats.currentGlobalStreak}-day global writing streak! You\'re building an incredible writing habit.');
    }

    if (activeProjectId != null) {
      final project = await _projectRepo.getProjectById(activeProjectId);
      if (project != null) {
        // 2. Project streak check
        if (project.projectStreak >= 3 && project.projectStreak != stats.currentGlobalStreak) {
          messages.add('✍️ ${project.projectStreak}-day streak on "${project.name}"! Outstanding focus.');
        }

        // 3. Remaining words countdown
        if (project.remainingWords <= 5000 && project.remainingWords > 0) {
          messages.add('🏁 Only ${project.remainingWords} words left on "${project.name}"! You are so close to the finish line. One more push!');
        }

        // 4. Milestone progress
        final progressPct = (project.writtenWords / project.targetWords) * 100;
        if (progressPct >= 50 && progressPct < 60) {
          messages.add('🌓 Halfway there! You have written ${project.writtenWords} words of your ${project.targetWords} target.');
        } else if (progressPct >= 75 && progressPct < 85) {
          messages.add('🚀 Over 75% complete! "${project.name}" is coming together beautifully.');
        }
      }
    }

    // 5. General backup reminder
    if (stats.writingDays > 0 && stats.writingDays % 5 == 0) {
      messages.add('💾 Don\'t forget to export a backup in Settings to keep your writing logs safe!');
    }

    // If no context-specific messages, provide a general welcoming one
    if (messages.isEmpty) {
      messages.add('Welcome back! Every word you write today is progress. Let\'s get to writing!');
    }

    return messages;
  }
}
