import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:plot_weaver/database/app_database.dart';
import 'package:plot_weaver/repositories/universe_repository.dart';
import 'package:plot_weaver/repositories/character_repository.dart';

void main() {
  late AppDatabase db;
  late UniverseRepository universeRepo;
  late CharacterRepository characterRepo;
  late Universe universe;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    universeRepo = UniverseRepository(db);
    characterRepo = CharacterRepository(db);

    universe = await universeRepo.createUniverse(
      title: 'The Gilded Crown',
      genre: 'Historical Fantasy',
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('CharacterRepository Tests (Phase 3)', () {
    test('Can create character dossier and retrieve it', () async {
      final character = await characterRepo.createCharacter(
        universeId: universe.id,
        name: 'Aria Sterling',
        alias: 'The Ghost of Ardor',
        role: 'Protagonist',
        archetype: 'The Rebel',
        age: '24',
        occupation: 'Master Cipherist',
        motivation: 'Decipher the stolen imperial ledger',
        flaw: 'Crippling inability to ask for help',
        internalConflict: 'Wants vengeance but needs forgiveness',
        backstory: 'Orphaned during the Siege of Solis...',
        arcStage: 'Introduction',
        avatarColor: 'crimson',
      );

      expect(character.id, isNotEmpty);
      expect(character.name, 'Aria Sterling');
      expect(character.alias, 'The Ghost of Ardor');
      expect(character.role, 'Protagonist');
      expect(character.archetype, 'The Rebel');
      expect(character.flaw, 'Crippling inability to ask for help');
      expect(character.avatarColor, 'crimson');

      final fetched = await characterRepo.getCharacter(character.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Aria Sterling');
    });

    test('Can update character dossier', () async {
      final character = await characterRepo.createCharacter(
        universeId: universe.id,
        name: 'Marcus Vance',
        role: 'Mentor',
      );

      await characterRepo.updateCharacter(
        id: character.id,
        name: 'Marcus Vance',
        role: 'Mentor',
        arcStage: 'Transformation',
        motivation: 'Protect the final heir',
        flaw: 'Guilt over past failures',
      );

      final updated = await characterRepo.getCharacter(character.id);
      expect(updated!.arcStage, 'Transformation');
      expect(updated.motivation, 'Protect the final heir');
      expect(updated.flaw, 'Guilt over past failures');
    });

    test('Can establish and query relationships between characters', () async {
      final aria = await characterRepo.createCharacter(
        universeId: universe.id,
        name: 'Aria',
        role: 'Protagonist',
      );
      final marcus = await characterRepo.createCharacter(
        universeId: universe.id,
        name: 'Marcus',
        role: 'Mentor',
      );
      final vance = await characterRepo.createCharacter(
        universeId: universe.id,
        name: 'Lord Vance',
        role: 'Antagonist',
      );

      // Aria and Marcus: Mentor/Student
      await characterRepo.createRelationship(
        universeId: universe.id,
        sourceCharacterId: marcus.id,
        targetCharacterId: aria.id,
        relationType: 'Mentor',
        description: 'Trained Aria in the arts of espionage',
      );

      // Aria and Lord Vance: Nemesis
      await characterRepo.createRelationship(
        universeId: universe.id,
        sourceCharacterId: aria.id,
        targetCharacterId: vance.id,
        relationType: 'Nemesis',
        description: 'Vance ordered the purge of Aria\'s clan',
      );

      // Query Aria's relationships (Aria is target in one, source in another)
      final ariaRels = await characterRepo.getRelationshipsForCharacter(aria.id);
      expect(ariaRels.length, 2);

      final mentorRel = ariaRels.firstWhere((r) => r.relationship.relationType == 'Mentor');
      expect(mentorRel.otherCharacter.name, 'Marcus');

      final nemesisRel = ariaRels.firstWhere((r) => r.relationship.relationType == 'Nemesis');
      expect(nemesisRel.otherCharacter.name, 'Lord Vance');
    });

    test('Deleting character cascades and removes their relationships', () async {
      final c1 = await characterRepo.createCharacter(universeId: universe.id, name: 'Alice', role: 'Protagonist');
      final c2 = await characterRepo.createCharacter(universeId: universe.id, name: 'Bob', role: 'Rival');

      await characterRepo.createRelationship(
        universeId: universe.id,
        sourceCharacterId: c1.id,
        targetCharacterId: c2.id,
        relationType: 'Rival',
      );

      // Delete Alice
      await characterRepo.deleteCharacter(c1.id);

      final remainingChars = await characterRepo.getCharacters(universe.id);
      expect(remainingChars.length, 1);
      expect(remainingChars.first.id, c2.id);

      // Verify relationships involving Alice are cleanly gone
      final bobRels = await characterRepo.getRelationshipsForCharacter(c2.id);
      expect(bobRels, isEmpty);
    });
  });
}
