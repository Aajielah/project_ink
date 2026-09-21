import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:plot_weaver/database/app_database.dart';
import 'package:plot_weaver/repositories/universe_repository.dart';

void main() {
  late AppDatabase db;
  late UniverseRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = UniverseRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UniverseRepository Tests (Phase 1)', () {
    test('Can create a new universe and read it back', () async {
      final universe = await repo.createUniverse(
        title: 'The Obsidian Spire',
        genre: 'Dark Fantasy',
        logline: 'An outcast archivist uncovers a forgotten sigil that unravels the empire.',
        synopsis: 'Deep in the catacombs of the capital city, a forbidden grimoire awakens...',
        coverColor: 'crimson',
        linkedProjectInkName: 'Spire Book 1',
      );

      expect(universe.id, isNotEmpty);
      expect(universe.title, 'The Obsidian Spire');
      expect(universe.genre, 'Dark Fantasy');
      expect(universe.coverColor, 'crimson');
      expect(universe.linkedProjectInkName, 'Spire Book 1');

      final fetched = await repo.getUniverse(universe.id);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'The Obsidian Spire');
    });

    test('Can update an existing universe', () async {
      final universe = await repo.createUniverse(
        title: 'Starbound Voyager',
        genre: 'Sci-Fi',
      );

      await repo.updateUniverse(
        id: universe.id,
        title: 'Starbound Voyager: Genesis',
        genre: 'Hard Sci-Fi',
        logline: 'A generation ship discovers an anomaly in deep space.',
      );

      final updated = await repo.getUniverse(universe.id);
      expect(updated!.title, 'Starbound Voyager: Genesis');
      expect(updated.genre, 'Hard Sci-Fi');
      expect(updated.logline, 'A generation ship discovers an anomaly in deep space.');
    });

    test('Can compute stats for a universe', () async {
      final universe = await repo.createUniverse(
        title: 'Cyberpunk Syndicate',
        genre: 'Cyberpunk',
      );

      final stats = await repo.getUniverseStats(universe.id);
      expect(stats.characterCount, 0);
      expect(stats.chapterCount, 0);
      expect(stats.sceneCount, 0);
      expect(stats.loreCount, 0);
      expect(stats.sparkCount, 0);
    });

    test('Can delete a universe', () async {
      final universe = await repo.createUniverse(
        title: 'Temporary World',
        genre: 'Mystery',
      );

      await repo.deleteUniverse(universe.id);

      final fetched = await repo.getUniverse(universe.id);
      expect(fetched, isNull);
    });
  });
}
