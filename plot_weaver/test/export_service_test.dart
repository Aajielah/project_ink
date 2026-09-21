import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:plot_weaver/database/app_database.dart';
import 'package:plot_weaver/repositories/universe_repository.dart';
import 'package:plot_weaver/repositories/outline_repository.dart';
import 'package:plot_weaver/repositories/character_repository.dart';
import 'package:plot_weaver/repositories/lore_repository.dart';
import 'package:plot_weaver/repositories/spark_repository.dart';
import 'package:plot_weaver/services/export_service.dart';

void main() {
  late AppDatabase db;
  late UniverseRepository universeRepo;
  late OutlineRepository outlineRepo;
  late CharacterRepository characterRepo;
  late LoreRepository loreRepo;
  late SparkRepository sparkRepo;
  late ExportService exportService;
  late Universe universe;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    universeRepo = UniverseRepository(db);
    outlineRepo = OutlineRepository(db);
    characterRepo = CharacterRepository(db);
    loreRepo = LoreRepository(db);
    sparkRepo = SparkRepository(db);
    exportService = ExportService(db);

    universe = await universeRepo.createUniverse(
      title: 'Chronicles of Solaria',
      genre: 'Solar Fantasy',
      logline: 'When the eternal sun flickers, an exile and an empress must rekindle the sky core.',
      synopsis: 'Deep in the desert empire, the ancient solar reactors begin to stall...',
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ExportService Tests (Phase 5)', () {
    test('Generates comprehensive Markdown Story Bible with all modules', () async {
      // 1. Chapter and Scene
      final ch = await outlineRepo.createChapter(
        universeId: universe.id,
        title: 'The Eclipse Approaches',
        act: 'Act I',
        objective: 'Establish the failing sky towers and trigger exile.',
        estimatedWordCount: 3500,
      );

      final charA = await characterRepo.createCharacter(
        universeId: universe.id,
        name: 'Kaelen Vance',
        alias: 'The Solar Smith',
        role: 'Protagonist',
        archetype: 'The Hero',
        motivation: 'Restore honor to his exiled house',
        flaw: 'Hot-headed impulsiveness',
        internalConflict: 'Loyalty to his clan vs survival of the empire',
        backstory: 'Banished after the reactor meltdown in Sector 4.',
      );

      final charB = await characterRepo.createCharacter(
        universeId: universe.id,
        name: 'Empress Maya',
        role: 'Deuteragonist',
        archetype: 'The Ruler',
      );

      await characterRepo.createRelationship(
        universeId: universe.id,
        sourceCharacterId: charA.id,
        targetCharacterId: charB.id,
        relationType: 'Rival',
        description: 'Blames her for his banishment but shares the same goal',
      );

      await outlineRepo.createScene(
        chapterId: ch.id,
        universeId: universe.id,
        title: 'The Shattered Core',
        summary: 'Kaelen inspects the failing prism lens before royal guards arrive.',
        povCharacterId: charA.id,
        locationName: 'Apex Spire',
        tensionLevel: 8,
      );

      // 2. Lore
      await loreRepo.createLoreEntry(
        universeId: universe.id,
        title: 'The Solari Core',
        category: 'Magic/Tech',
        summary: 'A perpetual fusion sphere powering the floating continent.',
        content: 'Constructed by the First Builders using crystallized starlight.',
        tags: 'tech, power-source, ancient',
      );

      // 3. Sparks
      await sparkRepo.createSpark(
        universeId: universe.id,
        content: '"If the sun dies today, we burn what remains."',
        category: 'Dialogue',
        isPinned: true,
      );

      final markdown = await exportService.generateMarkdownBible(universe.id);

      // Verifications
      expect(markdown, contains('# Story Bible: Chronicles of Solaria'));
      expect(markdown, contains('**Genre:** Solar Fantasy'));
      expect(markdown, contains('When the eternal sun flickers'));
      expect(markdown, contains('## 1. Chapter & Scene Outline'));
      expect(markdown, contains('Chapter 1: The Eclipse Approaches'));
      expect(markdown, contains('The Shattered Core'));
      expect(markdown, contains('Kaelen Vance'));
      expect(markdown, contains('8/10'));
      expect(markdown, contains('## 2. Character Dossiers'));
      expect(markdown, contains('The Solar Smith'));
      expect(markdown, contains('Fatal Flaw / Blindspot:** Hot-headed impulsiveness'));
      expect(markdown, contains('**Rival** with **Empress Maya**'));
      expect(markdown, contains('## 3. World Lore Codex'));
      expect(markdown, contains('Category: Magic/Tech'));
      expect(markdown, contains('The Solari Core'));
      expect(markdown, contains('## 4. Idea Sparks & Scratchpad'));
      expect(markdown, contains('📌 **[DIALOGUE]**: "If the sun dies today, we burn what remains."'));
    });
  });
}
