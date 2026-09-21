import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:plot_weaver/database/app_database.dart';
import 'package:plot_weaver/repositories/universe_repository.dart';
import 'package:plot_weaver/repositories/outline_repository.dart';

void main() {
  late AppDatabase db;
  late UniverseRepository universeRepo;
  late OutlineRepository outlineRepo;
  late Universe universe;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    universeRepo = UniverseRepository(db);
    outlineRepo = OutlineRepository(db);

    universe = await universeRepo.createUniverse(
      title: 'Echoes of the Void',
      genre: 'Sci-Fi',
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('OutlineRepository Tests (Phase 2)', () {
    test('Can create a chapter and fetch it', () async {
      final chapter = await outlineRepo.createChapter(
        universeId: universe.id,
        title: 'The Awakening Signal',
        act: 'Act I',
        objective: 'Discovers the ancient beacon and sounds the distress horn.',
        estimatedWordCount: 3000,
        status: 'Outlined',
      );

      expect(chapter.id, isNotEmpty);
      expect(chapter.title, 'The Awakening Signal');
      expect(chapter.act, 'Act I');
      expect(chapter.chapterNumber, 1);
      expect(chapter.estimatedWordCount, 3000);

      final chapters = await outlineRepo.getChapters(universe.id);
      expect(chapters.length, 1);
      expect(chapters.first.title, 'The Awakening Signal');
    });

    test('Can update a chapter', () async {
      final chapter = await outlineRepo.createChapter(
        universeId: universe.id,
        title: 'Old Title',
        act: 'Act I',
        estimatedWordCount: 2000,
        status: 'Idea',
      );

      await outlineRepo.updateChapter(
        id: chapter.id,
        title: 'New Chapter Title',
        act: 'Act IIA',
        objective: 'Updated objective',
        estimatedWordCount: 3500,
        status: 'Drafting',
      );

      final chapters = await outlineRepo.getChapters(universe.id);
      expect(chapters.first.title, 'New Chapter Title');
      expect(chapters.first.act, 'Act IIA');
      expect(chapters.first.estimatedWordCount, 3500);
      expect(chapters.first.status, 'Drafting');
    });

    test('Can create scene in chapter and calculate tension', () async {
      final chapter = await outlineRepo.createChapter(
        universeId: universe.id,
        title: 'The Catacombs',
      );

      final scene = await outlineRepo.createScene(
        chapterId: chapter.id,
        universeId: universe.id,
        title: 'Torchlight in the Dark',
        summary: 'Protagonist navigates the flooded ruins.',
        locationName: 'Lower Crypts',
        tensionLevel: 8,
      );

      expect(scene.id, isNotEmpty);
      expect(scene.chapterId, chapter.id);
      expect(scene.tensionLevel, 8);
      expect(scene.locationName, 'Lower Crypts');
    });

    test('Can reorder chapters and maintain sequential chapter numbers', () async {
      final c1 = await outlineRepo.createChapter(universeId: universe.id, title: 'Chapter 1');
      final c2 = await outlineRepo.createChapter(universeId: universe.id, title: 'Chapter 2');

      // Reverse order
      await outlineRepo.reorderChapters(universe.id, [c2.id, c1.id]);

      final chapters = await outlineRepo.getChapters(universe.id);
      expect(chapters[0].id, c2.id);
      expect(chapters[0].chapterNumber, 1);
      expect(chapters[1].id, c1.id);
      expect(chapters[1].chapterNumber, 2);
    });

    test('Can apply Save the Cat template (15 beats)', () async {
      await outlineRepo.applyTemplate(universe.id, 'save_the_cat');

      final chapters = await outlineRepo.getChapters(universe.id);
      expect(chapters.length, 15);
      expect(chapters.first.title, 'Opening Image');
      expect(chapters.last.title, 'Final Image');

      final stats = await universeRepo.getUniverseStats(universe.id);
      expect(stats.chapterCount, 15);
      expect(stats.totalEstimatedWords, greaterThan(30000));
    });

    test('Deleting chapter cascades and deletes its scenes', () async {
      final chapter = await outlineRepo.createChapter(universeId: universe.id, title: 'Doomed Chapter');
      await outlineRepo.createScene(chapterId: chapter.id, universeId: universe.id, title: 'Scene 1');
      await outlineRepo.createScene(chapterId: chapter.id, universeId: universe.id, title: 'Scene 2');

      await outlineRepo.deleteChapter(chapter.id);

      final chapters = await outlineRepo.getChapters(universe.id);
      expect(chapters, isEmpty);

      // Verify scenes for this universe are also gone
      final remainingScenes = await (db.select(db.scenes)..where((s) => s.chapterId.equals(chapter.id))).get();
      expect(remainingScenes, isEmpty);
    });
  });
}
