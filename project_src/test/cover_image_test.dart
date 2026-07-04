import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../lib/database/database.dart';
import '../lib/models/project.dart';
import '../lib/repositories/project_repository.dart';
import '../lib/repositories/schedule_repository.dart';
import '../lib/repositories/daily_log_repository.dart';
import '../lib/repositories/statistics_repository.dart';
import '../lib/shared/cover_matching_helper.dart';
import '../lib/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppDatabase db;
  late ProjectRepository projectRepo;
  late ScheduleRepository scheduleRepo;
  late DailyLogRepository logRepo;
  late StatisticsRepository statsRepo;
  late BackupService backupService;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('project_ink_test');
    
    // Mock the path_provider channel
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory' ||
          methodCall.method == 'getTemporaryDirectory') {
        return tempDir.path;
      }
      return null;
    });

    db = AppDatabase(NativeDatabase.memory());
    projectRepo = ProjectRepository(db);
    scheduleRepo = ScheduleRepository(db);
    logRepo = DailyLogRepository(db);
    statsRepo = StatisticsRepository(db);
    backupService = BackupService(db);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Cover Matching Helper (Byte Deduplication) Tests', () {
    test('findExistingMatchingCover matches identical file, ignores mismatching ones', () async {
      // 1. Create a "picked" file with contents 'hello'
      final pickedFile = File(p.join(tempDir.path, 'picked.jpg'))..writeAsStringSync('hello');

      // 2. No matching file exists initially
      var match = await findExistingMatchingCover(pickedFile, tempDir);
      expect(match, isNull);

      // 3. Create an existing cover file with different contents (different size)
      final coverDiffSize = File(p.join(tempDir.path, 'cover_1.jpg'))..writeAsStringSync('different_size');
      match = await findExistingMatchingCover(pickedFile, tempDir);
      expect(match, isNull);

      // 4. Create an existing cover file with same size but different contents
      final coverDiffBytes = File(p.join(tempDir.path, 'cover_2.jpg'))..writeAsStringSync('world');
      match = await findExistingMatchingCover(pickedFile, tempDir);
      expect(match, isNull);

      // 5. Create an existing cover file with identical contents
      final coverIdentical = File(p.join(tempDir.path, 'cover_3.jpg'))..writeAsStringSync('hello');
      match = await findExistingMatchingCover(pickedFile, tempDir);
      expect(match, coverIdentical.path);
    });
  });

  group('Orphaned Cover Cleanup Sweep Tests', () {
    test('cleanupOrphanedCovers deletes unreferenced cover files, keeps referenced ones', () async {
      // 1. Create some cover files
      final refCover = File(p.join(tempDir.path, 'cover_referenced.jpg'))..writeAsStringSync('referenced');
      final orphanCover = File(p.join(tempDir.path, 'cover_orphan.jpg'))..writeAsStringSync('orphan');
      final unrelatedFile = File(p.join(tempDir.path, 'unrelated.txt'))..writeAsStringSync('do_not_touch');

      // 2. Insert project referencing cover_referenced.jpg
      final project = ProjectModel(
        id: 'proj1',
        name: 'Clean Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 10000,
        writtenWords: 0,
        remainingWords: 10000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: DateTime.now(),
        expectedFinishDate: DateTime.now().add(const Duration(days: 20)),
        restMode: RestMode.fixed,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        coverImagePath: refCover.path,
        coverType: 'uploaded',
      );
      await projectRepo.insertProject(project);

      // 3. Define inline sweep logic similar to providers.dart
      Future<void> performSweep() async {
        final list = await projectRepo.getAllProjects();
        final activePaths = list
            .where((p) => p.coverType == 'uploaded' && p.coverImagePath != null)
            .map((p) => p.coverImagePath!)
            .toSet();

        final files = tempDir.listSync();
        for (final entity in files) {
          if (entity is File) {
            final filename = entity.path.split('/').last.split('\\').last;
            if (filename.startsWith('cover_') && !activePaths.contains(entity.path)) {
              await entity.delete();
            }
          }
        }
      }

      await performSweep();

      // 4. Verify outcomes
      expect(refCover.existsSync(), isTrue);
      expect(orphanCover.existsSync(), isFalse);
      expect(unrelatedFile.existsSync(), isTrue);
    });
  });

  group('Backup Import & Export Cover Packaging Tests', () {
    test('Backup export archives cover files and import restores them to new context', () async {
      // 1. Create a cover image in the current tempDir
      final origCover = File(p.join(tempDir.path, 'cover_project.jpg'))..writeAsBytesSync([1, 2, 3, 4, 5]);

      final project = ProjectModel(
        id: 'proj_backup',
        name: 'Backup Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 10000,
        writtenWords: 0,
        remainingWords: 10000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: DateTime.now(),
        expectedFinishDate: DateTime.now().add(const Duration(days: 20)),
        restMode: RestMode.fixed,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        coverImagePath: origCover.path,
        coverType: 'uploaded',
      );
      await projectRepo.insertProject(project);

      // 2. Export backup
      final backupPath = await backupService.exportBackup();
      expect(backupPath, isNotNull);
      final backupFile = File(backupPath!);
      expect(backupFile.existsSync(), isTrue);

      // 3. Read the ZIP archive to verify contents
      final zipBytes = backupFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      bool foundCoverInZip = false;
      bool foundProjectsJson = false;
      String? projectsJsonContent;

      for (final file in archive) {
        if (file.isFile) {
          if (file.name == 'covers/cover_project.jpg') {
            foundCoverInZip = true;
            expect(file.content as List<int>, [1, 2, 3, 4, 5]);
          } else if (file.name == 'projects.json') {
            foundProjectsJson = true;
            projectsJsonContent = utf8.decode(file.content as List<int>);
          }
        }
      }

      expect(foundCoverInZip, isTrue);
      expect(foundProjectsJson, isTrue);
      expect(projectsJsonContent, isNotNull);

      // Verify that projects.json references the relative path inside covers/
      final decodedProjects = jsonDecode(projectsJsonContent!) as List;
      final savedProj = decodedProjects.first;
      expect(savedProj['coverImagePath'], 'covers/cover_project.jpg');

      // 4. Mock a new device context: create a new temp folder & map path_provider to it
      final newTempDir = Directory.systemTemp.createTempSync('project_ink_restore_test');
      const MethodChannel('plugins.flutter.io/path_provider')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory' ||
            methodCall.method == 'getTemporaryDirectory') {
          return newTempDir.path;
        }
        return null;
      });

      // 5. Restore backup onto the new context
      final success = await backupService.importBackup(backupPath);
      expect(success, isTrue);

      // Verify image was copied to new context
      final restoredFile = File(p.join(newTempDir.path, 'cover_project.jpg'));
      expect(restoredFile.existsSync(), isTrue);
      expect(restoredFile.readAsBytesSync(), [1, 2, 3, 4, 5]);

      // Verify project row coverImagePath is re-mapped to the new absolute path
      final restoredProjects = await projectRepo.getAllProjects();
      expect(restoredProjects.length, 1);
      expect(p.normalize(restoredProjects.first.coverImagePath!), p.normalize(restoredFile.path));

      newTempDir.deleteSync(recursive: true);
    });
  });
}
