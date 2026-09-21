import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class CharacterRelationshipWithTarget {
  final CharacterRelationship relationship;
  final Character otherCharacter;
  final bool isSource;

  const CharacterRelationshipWithTarget({
    required this.relationship,
    required this.otherCharacter,
    required this.isSource,
  });
}

class CharacterRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  CharacterRepository(this._db);

  Stream<List<Character>> watchCharacters(String universeId) {
    return (_db.select(_db.characters)
          ..where((c) => c.universeId.equals(universeId))
          ..orderBy([
            (c) => OrderingTerm(expression: c.updatedAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<List<Character>> getCharacters(String universeId) {
    return (_db.select(_db.characters)
          ..where((c) => c.universeId.equals(universeId))
          ..orderBy([
            (c) => OrderingTerm(expression: c.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<Character?> getCharacter(String id) {
    return (_db.select(_db.characters)..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  Future<Character> createCharacter({
    required String universeId,
    required String name,
    String? alias,
    required String role,
    String? archetype,
    String? age,
    String? occupation,
    String? motivation,
    String? flaw,
    String? internalConflict,
    String? backstory,
    String arcStage = 'Introduction',
    String? notes,
    String avatarColor = 'teal',
  }) async {
    final now = DateTime.now();
    final companion = CharactersCompanion(
      id: Value(_uuid.v4()),
      universeId: Value(universeId),
      name: Value(name.trim()),
      alias: Value(alias?.trim()),
      role: Value(role.trim()),
      archetype: Value(archetype?.trim()),
      age: Value(age?.trim()),
      occupation: Value(occupation?.trim()),
      motivation: Value(motivation?.trim()),
      flaw: Value(flaw?.trim()),
      internalConflict: Value(internalConflict?.trim()),
      backstory: Value(backstory?.trim()),
      arcStage: Value(arcStage),
      notes: Value(notes?.trim()),
      avatarColor: Value(avatarColor),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    return await _db.into(_db.characters).insertReturning(companion);
  }

  Future<void> updateCharacter({
    required String id,
    required String name,
    String? alias,
    required String role,
    String? archetype,
    String? age,
    String? occupation,
    String? motivation,
    String? flaw,
    String? internalConflict,
    String? backstory,
    required String arcStage,
    String? notes,
    String? avatarColor,
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.characters)..where((c) => c.id.equals(id))).write(
      CharactersCompanion(
        name: Value(name.trim()),
        alias: Value(alias?.trim()),
        role: Value(role.trim()),
        archetype: Value(archetype?.trim()),
        age: Value(age?.trim()),
        occupation: Value(occupation?.trim()),
        motivation: Value(motivation?.trim()),
        flaw: Value(flaw?.trim()),
        internalConflict: Value(internalConflict?.trim()),
        backstory: Value(backstory?.trim()),
        arcStage: Value(arcStage),
        notes: Value(notes?.trim()),
        avatarColor: avatarColor != null ? Value(avatarColor) : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deleteCharacter(String id) async {
    await (_db.delete(_db.characters)..where((c) => c.id.equals(id))).go();
  }

  Stream<List<CharacterRelationship>> watchRelationships(String universeId) {
    return (_db.select(_db.characterRelationships)
          ..where((r) => r.universeId.equals(universeId)))
        .watch();
  }

  Future<List<CharacterRelationshipWithTarget>> getRelationshipsForCharacter(
    String characterId,
  ) async {
    final rels = await (_db.select(_db.characterRelationships)
          ..where(
            (r) =>
                r.sourceCharacterId.equals(characterId) |
                r.targetCharacterId.equals(characterId),
          ))
        .get();

    final result = <CharacterRelationshipWithTarget>[];
    for (final rel in rels) {
      final isSource = rel.sourceCharacterId == characterId;
      final targetId = isSource ? rel.targetCharacterId : rel.sourceCharacterId;
      final other = await getCharacter(targetId);
      if (other != null) {
        result.add(
          CharacterRelationshipWithTarget(
            relationship: rel,
            otherCharacter: other,
            isSource: isSource,
          ),
        );
      }
    }
    return result;
  }

  Future<CharacterRelationship> createRelationship({
    required String universeId,
    required String sourceCharacterId,
    required String targetCharacterId,
    required String relationType,
    String? description,
  }) async {
    final companion = CharacterRelationshipsCompanion(
      id: Value(_uuid.v4()),
      universeId: Value(universeId),
      sourceCharacterId: Value(sourceCharacterId),
      targetCharacterId: Value(targetCharacterId),
      relationType: Value(relationType.trim()),
      description: Value(description?.trim()),
      createdAt: Value(DateTime.now()),
    );

    return await _db.into(_db.characterRelationships).insertReturning(companion);
  }

  Future<void> deleteRelationship(String id) async {
    await (_db.delete(_db.characterRelationships)..where((r) => r.id.equals(id))).go();
  }
}
