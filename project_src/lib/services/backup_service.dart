import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database.dart';
import '../repositories/statistics_repository.dart';

class BackupService {
  final AppDatabase _db;

  const BackupService(this._db);

  /// Exports the entire database into a compressed ZIP file with .projectink extension.
  /// Returns the path of the exported file, or null if it failed.
  Future<String?> exportBackup() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final backupFolder = Directory('${tempDir.path}/projectink_backup');
      if (backupFolder.existsSync()) {
        backupFolder.deleteSync(recursive: true);
      }
      backupFolder.createSync();

      // Fetch all tables data
      final users = await _db.select(_db.users).get();
      final projects = await _db.select(_db.projects).get();
      final schedules = await _db.select(_db.schedules).get();
      final logs = await _db.select(_db.dailyLogs).get();
      final stats = await _db.select(_db.statisticsTable).get();
      final achievements = await _db.select(_db.achievements).get();
      final quotes = await _db.select(_db.quotes).get();
      final settings = await _db.select(_db.settingsTable).get();

      // Helper to serialize rows to JSON list
      void writeJsonFile(String name, List<dynamic> list) {
        final file = File('${backupFolder.path}/$name');
        final jsonString = jsonEncode(list);
        file.writeAsStringSync(jsonString);
      }

      writeJsonFile('user.json', users.map((u) => {
        'id': u.id, 'name': u.name, 'createdAt': u.createdAt.toIso8601String(),
        'themeMode': u.themeMode, 'notificationsEnabled': u.notificationsEnabled,
        'dailyQuotesEnabled': u.dailyQuotesEnabled
      }).toList());

      // Copy all referenced cover files to backupFolder/covers
      final coversFolder = Directory('${backupFolder.path}/covers');
      coversFolder.createSync(recursive: true);

      for (final p in projects) {
        if (p.coverImagePath != null) {
          final coverFile = File(p.coverImagePath!);
          if (coverFile.existsSync()) {
            final filename = p.coverImagePath!.split('/').last.split('\\').last;
            coverFile.copySync('${coversFolder.path}/$filename');
          }
        }
      }

      writeJsonFile('projects.json', projects.map((p) => {
        'id': p.id, 'name': p.name, 'description': p.description, 'status': p.status,
        'targetWords': p.targetWords, 'writtenWords': p.writtenWords, 'remainingWords': p.remainingWords,
        'dailyWordTarget': p.dailyWordTarget, 'backlogWords': p.backlogWords,
        'startDate': p.startDate.toIso8601String(), 'expectedFinishDate': p.expectedFinishDate.toIso8601String(),
        'actualFinishDate': p.actualFinishDate?.toIso8601String(), 'restMode': p.restMode,
        'allowedRestDays': p.allowedRestDays, 'remainingRestDays': p.remainingRestDays,
        'projectStreak': p.projectStreak, 'longestProjectStreak': p.longestProjectStreak,
        'currentWeek': p.currentWeek, 'createdAt': p.createdAt.toIso8601String(),
        'updatedAt': p.updatedAt.toIso8601String(),
        // Save relative path inside covers/ folder
        'coverImagePath': (p.coverImagePath != null && File(p.coverImagePath!).existsSync())
            ? 'covers/${p.coverImagePath!.split('/').last.split('\\').last}'
            : p.coverImagePath,
        'coverType': p.coverType,
        'projectType': p.projectType, 'pendingCarryForward': p.pendingCarryForward,
        'ongoingStyle': p.ongoingStyle,
        'writingSession': p.writingSession
      }).toList());


      writeJsonFile('schedule.json', schedules.map((s) => {
        'id': s.id, 'projectId': s.projectId, 'date': s.date.toIso8601String(),
        'plannedWords': s.plannedWords, 'isRestDay': s.isRestDay, 'completed': s.completed,
        'automaticRestDay': s.automaticRestDay, 'locked': s.locked, 'isRecoveryDay': s.isRecoveryDay
      }).toList());

      writeJsonFile('logs.json', logs.map((l) => {
        'id': l.id, 'projectId': l.projectId, 'scheduleId': l.scheduleId,
        'date': l.date.toIso8601String(), 'plannedWords': l.plannedWords,
        'actualWords': l.actualWords, 'carryForwardWords': l.carryForwardWords,
        'backlogCreated': l.backlogCreated, 'completed': l.completed,
        'loggedAt': l.loggedAt.toIso8601String()
      }).toList());

      writeJsonFile('statistics.json', stats.map((s) => {
        'id': s.id, 'lifetimeWords': s.lifetimeWords, 'averageWordsPerDay': s.averageWordsPerDay,
        'currentGlobalStreak': s.currentGlobalStreak, 'longestGlobalStreak': s.longestGlobalStreak,
        'projectsCompleted': s.projectsCompleted, 'writingDays': s.writingDays,
        'restDaysUsed': s.restDaysUsed, 'currentBacklog': s.currentBacklog
      }).toList());

      writeJsonFile('achievements.json', achievements.map((a) => {
        'id': a.id, 'title': a.title, 'description': a.description, 'earnedDate': a.earnedDate.toIso8601String()
      }).toList());

      writeJsonFile('quotes.json', quotes.map((q) => {
        'id': q.id, 'textContent': q.textContent, 'author': q.author, 'category': q.category, 'mood': q.mood
      }).toList());

      writeJsonFile('settings.json', settings.map((s) => {
        'id': s.id, 'theme': s.theme, 'notifications': s.notifications, 'dailyQuotes': s.dailyQuotes,
        'backupReminder': s.backupReminder, 'vibration': s.vibration
      }).toList());

      // Zip the folder recursively using the archive library
      final archive = Archive();
      final files = backupFolder.listSync(recursive: true);
      for (final file in files) {
        if (file is File) {
          final relativePath = file.path.replaceFirst('${backupFolder.path}/', '').replaceFirst('${backupFolder.path}\\', '');
          final bytes = file.readAsBytesSync();
          archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
        }
      }

      final encoder = ZipEncoder();
      final zipData = encoder.encode(archive);
      if (zipData == null) return null;

      final documentsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${documentsDir.path}/project_ink_backup_$timestamp.projectink');
      await backupFile.writeAsBytes(zipData);

      // Clean up temp directory
      backupFolder.deleteSync(recursive: true);

      return backupFile.path;
    } catch (e) {
      return null;
    }
  }

  /// Restores the database from a ZIP archive file path.
  /// Runs inside a Drift database transaction to ensure safety.
  Future<bool> importBackup(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      if (!zipFile.existsSync()) return false;

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      Map<String, dynamic>? decodedUser;
      List<dynamic>? decodedProjects;
      List<dynamic>? decodedSchedules;
      List<dynamic>? decodedLogs;
      List<dynamic>? decodedStats;
      List<dynamic>? decodedAchievements;
      List<dynamic>? decodedQuotes;
      List<dynamic>? decodedSettings;

      for (final file in archive) {
        if (file.isFile) {
          if (file.name.endsWith('.json')) {
            final content = utf8.decode(file.content as List<int>);
            final json = jsonDecode(content);
            
            if (file.name == 'user.json') {
              decodedUser = (json as List).isNotEmpty ? json.first : null;
            } else if (file.name == 'projects.json') {
              decodedProjects = json as List;
            } else if (file.name == 'schedule.json') {
              decodedSchedules = json as List;
            } else if (file.name == 'logs.json') {
              decodedLogs = json as List;
            } else if (file.name == 'statistics.json') {
              decodedStats = json as List;
            } else if (file.name == 'achievements.json') {
              decodedAchievements = json as List;
            } else if (file.name == 'quotes.json') {
              decodedQuotes = json as List;
            } else if (file.name == 'settings.json') {
              decodedSettings = json as List;
            }
          } else {
            // Restore cover image flatly to private documents directory
            final appDir = await getApplicationDocumentsDirectory();
            final bytes = file.content as List<int>;
            final filename = file.name.split('/').last.split('\\').last;
            final outFile = File('${appDir.path}/$filename');
            await outFile.writeAsBytes(bytes);
          }
        }
      }

      // Perform atomic database replacement
      await _db.transaction(() async {
        // Clear all tables
        await _db.delete(_db.users).go();
        await _db.delete(_db.projects).go();
        await _db.delete(_db.schedules).go();
        await _db.delete(_db.dailyLogs).go();
        await _db.delete(_db.statisticsTable).go();
        await _db.delete(_db.achievements).go();
        await _db.delete(_db.quotes).go();
        await _db.delete(_db.settingsTable).go();

        // Restore User
        if (decodedUser != null) {
          await _db.into(_db.users).insert(UsersCompanion.insert(
            id: decodedUser['id'],
            name: decodedUser['name'],
            createdAt: DateTime.parse(decodedUser['createdAt']),
            themeMode: decodedUser['themeMode'],
            notificationsEnabled: Value(decodedUser['notificationsEnabled'] ?? true),
            dailyQuotesEnabled: Value(decodedUser['dailyQuotesEnabled'] ?? true),
          ));
        }

        // Restore Projects
        if (decodedProjects != null) {
          final appDir = await getApplicationDocumentsDirectory();
          for (final p in decodedProjects) {
            String? restoredCoverPath = p['coverImagePath'];
            if (p['coverType'] == 'uploaded' && restoredCoverPath != null) {
              final filename = restoredCoverPath.split('/').last.split('\\').last;
              restoredCoverPath = '${appDir.path}/$filename';
            }

            await _db.into(_db.projects).insert(ProjectsCompanion.insert(
              id: p['id'],
              name: p['name'],
              description: Value(p['description']),
              status: p['status'],
              targetWords: p['targetWords'],
              writtenWords: Value(p['writtenWords'] ?? 0),
              remainingWords: p['remainingWords'],
              dailyWordTarget: p['dailyWordTarget'],
              backlogWords: Value(p['backlogWords'] ?? 0),
              startDate: DateTime.parse(p['startDate']),
              expectedFinishDate: DateTime.parse(p['expectedFinishDate']),
              actualFinishDate: Value(p['actualFinishDate'] != null ? DateTime.parse(p['actualFinishDate']) : null),
              restMode: p['restMode'],
              allowedRestDays: Value(p['allowedRestDays'] ?? 0),
              remainingRestDays: Value(p['remainingRestDays'] ?? 0),
              projectStreak: Value(p['projectStreak'] ?? 0),
              longestProjectStreak: Value(p['longestProjectStreak'] ?? 0),
              currentWeek: Value(p['currentWeek'] ?? 1),
              createdAt: DateTime.parse(p['createdAt']),
              updatedAt: DateTime.parse(p['updatedAt']),
              coverImagePath: Value(restoredCoverPath),
              coverType: Value(p['coverType']),
              projectType: Value(p['projectType'] ?? 'fixed'),
              pendingCarryForward: Value(p['pendingCarryForward'] ?? 0),
              ongoingStyle: Value(p['ongoingStyle'] ?? 'daily'),
              writingSession: Value(p['writingSession'] ?? 'none'),
            ));
          }
        }


        // Restore Schedules
        if (decodedSchedules != null) {
          for (final s in decodedSchedules) {
            await _db.into(_db.schedules).insert(SchedulesCompanion.insert(
              id: s['id'],
              projectId: s['projectId'],
              date: DateTime.parse(s['date']),
              plannedWords: s['plannedWords'],
              isRestDay: Value(s['isRestDay'] ?? false),
              completed: Value(s['completed'] ?? false),
              automaticRestDay: Value(s['automaticRestDay'] ?? false),
              locked: Value(s['locked'] ?? false),
              isRecoveryDay: Value(s['isRecoveryDay'] ?? false),
            ));
          }
        }

        // Restore Logs
        if (decodedLogs != null) {
          for (final l in decodedLogs) {
            await _db.into(_db.dailyLogs).insert(DailyLogsCompanion.insert(
              id: l['id'],
              projectId: l['projectId'],
              scheduleId: Value(l['scheduleId']),
              date: DateTime.parse(l['date']),
              plannedWords: l['plannedWords'],
              actualWords: l['actualWords'],
              carryForwardWords: Value(l['carryForwardWords'] ?? 0),
              backlogCreated: Value(l['backlogCreated'] ?? 0),
              completed: Value(l['completed'] ?? false),
              loggedAt: DateTime.parse(l['loggedAt']),
            ));
          }
        }

        // Restore Statistics
        if (decodedStats != null) {
          for (final s in decodedStats) {
            await _db.into(_db.statisticsTable).insert(StatisticsTableCompanion.insert(
              id: s['id'],
              lifetimeWords: Value(s['lifetimeWords'] ?? 0),
              averageWordsPerDay: Value(s['averageWordsPerDay'] ?? 0.0),
              currentGlobalStreak: Value(s['currentGlobalStreak'] ?? 0),
              longestGlobalStreak: Value(s['longestGlobalStreak'] ?? 0),
              projectsCompleted: Value(s['projectsCompleted'] ?? 0),
              writingDays: Value(s['writingDays'] ?? 0),
              restDaysUsed: Value(s['restDaysUsed'] ?? 0),
              currentBacklog: Value(s['currentBacklog'] ?? 0),
            ));
          }
        }

        // Restore Achievements
        if (decodedAchievements != null) {
          for (final a in decodedAchievements) {
            await _db.into(_db.achievements).insert(AchievementsCompanion.insert(
              id: a['id'],
              title: a['title'],
              description: a['description'],
              earnedDate: DateTime.parse(a['earnedDate']),
            ));
          }
        }

        // Restore Quotes
        if (decodedQuotes != null) {
          for (final q in decodedQuotes) {
            await _db.into(_db.quotes).insert(QuotesCompanion.insert(
              id: q['id'],
              textContent: q['textContent'],
              author: q['author'],
              category: q['category'],
              mood: q['mood'],
            ));
          }
        }

        // Restore Settings
        if (decodedSettings != null) {
          for (final s in decodedSettings) {
            await _db.into(_db.settingsTable).insert(SettingsTableCompanion.insert(
              id: s['id'],
              theme: Value(s['theme'] ?? 'system'),
              notifications: Value(s['notifications'] ?? true),
              dailyQuotes: Value(s['dailyQuotes'] ?? true),
              backupReminder: Value(s['backupReminder'] ?? true),
              vibration: Value(s['vibration'] ?? true),
            ));
          }
        }
      });

      await StatisticsRepository(_db).recalculateStatistics();
      return true;
    } catch (e) {
      return false;
    }
  }
}
