import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:plot_weaver/database/app_database.dart';
import 'package:plot_weaver/repositories/universe_repository.dart';
import 'package:plot_weaver/repositories/lore_repository.dart';

void main() {
  late AppDatabase db;
  late UniverseRepository universeRepo;
  late LoreRepository loreRepo;
  late Universe universe;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    universeRepo = UniverseRepository(db);
    loreRepo = LoreRepository(db);

    universe = await universeRepo.createUniverse(
      title: 'Aethelgard Chronicles',
      genre: 'High Fantasy',
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('LoreRepository Tests (Phase 4)', () {
    test('Can create and retrieve lore entries in universe', () async {
      final faction = await loreRepo.createLoreEntry(
        universeId: universe.id,
        title: 'The Silent Vanguard',
        category: 'Faction',
        summary: 'An elite clandestine order sworn to protect the High King in shadow.',
        content: 'Founded in the Third Age. Members undergo rigorous sensory deprivation training.',
        tags: 'faction, shadow, military',
      );

      await loreRepo.createLoreEntry(
        universeId: universe.id,
        title: 'The Spire of Whispers',
        category: 'Location',
        summary: 'A crystalline tower that amplifies magical reverberations.',
        content: 'Rises 800 feet above the Mist Sea. Accessible only during low tide.',
        tags: 'landmark, tower, dangerous',
      );

      final entries = await loreRepo.getLoreEntries(universe.id);
      expect(entries.length, 2);
      expect(entries.map((e) => e.title), containsAll(['The Silent Vanguard', 'The Spire of Whispers']));

      final fetched = await loreRepo.getLoreEntry(faction.id);
      expect(fetched, isNotNull);
      expect(fetched!.category, 'Faction');
      expect(fetched.tags, 'faction, shadow, military');
    });

    test('Can update lore entry details', () async {
      final entry = await loreRepo.createLoreEntry(
        universeId: universe.id,
        title: 'Sunfire Magic',
        category: 'Magic/Tech',
        summary: 'Old magic drawn from dawn rays.',
      );

      await loreRepo.updateLoreEntry(
        id: entry.id,
        title: 'Solar Radiance Weaving',
        category: 'Magic/Tech',
        summary: 'Refined sunfire magic mastered by the Solari Monks.',
        content: 'Requires uninterrupted focus and a gold prism focus.',
        tags: 'solar, spells, light',
      );

      final updated = await loreRepo.getLoreEntry(entry.id);
      expect(updated!.title, 'Solar Radiance Weaving');
      expect(updated.summary, 'Refined sunfire magic mastered by the Solari Monks.');
      expect(updated.tags, 'solar, spells, light');
    });

    test('Can delete lore entry', () async {
      final entry = await loreRepo.createLoreEntry(
        universeId: universe.id,
        title: 'Temp Lore',
        category: 'History',
      );

      var list = await loreRepo.getLoreEntries(universe.id);
      expect(list.length, 1);

      await loreRepo.deleteLoreEntry(entry.id);

      list = await loreRepo.getLoreEntries(universe.id);
      expect(list.isEmpty, isTrue);
    });

    test('watchLoreEntries emits updates reactively', () async {
      final stream = loreRepo.watchLoreEntries(universe.id);
      final expectation = expectLater(
        stream,
        emitsThrough(hasLength(2)),
      );

      await loreRepo.createLoreEntry(
        universeId: universe.id,
        title: 'Entry 1',
        category: 'Artifact',
      );

      await loreRepo.createLoreEntry(
        universeId: universe.id,
        title: 'Entry 2',
        category: 'Culture',
      );

      await expectation;
    });

    test('Cascading deletion when Universe is deleted', () async {
      await loreRepo.createLoreEntry(
        universeId: universe.id,
        title: 'Kingdom of Vael',
        category: 'Faction',
      );

      await universeRepo.deleteUniverse(universe.id);

      final entries = await db.select(db.loreEntries).get();
      expect(entries.isEmpty, isTrue);
    });
  });
}
