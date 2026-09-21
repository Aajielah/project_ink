import 'package:drift/drift.dart';
import 'connection/connection.dart' as c;

part 'app_database.g.dart';

class Universes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get genre => text()();
  TextColumn get logline => text().nullable()();
  TextColumn get synopsis => text().nullable()();
  TextColumn get coverColor => text().withDefault(const Constant('amber'))();
  TextColumn get linkedProjectInkId => text().nullable()();
  TextColumn get linkedProjectInkName => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Characters extends Table {
  TextColumn get id => text()();
  TextColumn get universeId => text().references(Universes, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get alias => text().nullable()();
  TextColumn get role => text()(); // Protagonist, Antagonist, Supporting, Mentor, Foil
  TextColumn get archetype => text().nullable()(); // The Rebel, The Chosen, The Sage, etc.
  TextColumn get age => text().nullable()();
  TextColumn get occupation => text().nullable()();
  TextColumn get motivation => text().nullable()();
  TextColumn get flaw => text().nullable()();
  TextColumn get internalConflict => text().nullable()();
  TextColumn get backstory => text().nullable()();
  TextColumn get arcStage => text().withDefault(const Constant('Introduction'))();
  TextColumn get notes => text().nullable()();
  TextColumn get avatarColor => text().withDefault(const Constant('teal'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CharacterRelationships extends Table {
  TextColumn get id => text()();
  TextColumn get universeId => text().references(Universes, #id, onDelete: KeyAction.cascade)();
  TextColumn get sourceCharacterId => text().references(Characters, #id, onDelete: KeyAction.cascade)();
  TextColumn get targetCharacterId => text().references(Characters, #id, onDelete: KeyAction.cascade)();
  TextColumn get relationType => text()(); // Ally, Rival, Family, Sibling, Enemy, Mentor, Secret Crush, Bound By Oath, Betrayed By
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Chapters extends Table {
  TextColumn get id => text()();
  TextColumn get universeId => text().references(Universes, #id, onDelete: KeyAction.cascade)();
  IntColumn get chapterNumber => integer()();
  TextColumn get act => text().withDefault(const Constant('Act I'))(); // Act I, Act IIA, Act IIB, Act III, Prologue, Epilogue
  TextColumn get title => text()();
  TextColumn get objective => text().nullable()(); // Core chapter goal / what changes
  IntColumn get estimatedWordCount => integer().withDefault(const Constant(2500))();
  TextColumn get status => text().withDefault(const Constant('Outlined'))(); // Idea, Outlined, Drafting, Revised, Done
  IntColumn get orderIndex => integer()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Scenes extends Table {
  TextColumn get id => text()();
  TextColumn get chapterId => text().references(Chapters, #id, onDelete: KeyAction.cascade)();
  TextColumn get universeId => text().references(Universes, #id, onDelete: KeyAction.cascade)();
  IntColumn get sceneNumber => integer()();
  TextColumn get title => text()();
  TextColumn get summary => text().nullable()();
  TextColumn get povCharacterId => text().nullable().references(Characters, #id, onDelete: KeyAction.setNull)();
  TextColumn get locationName => text().nullable()();
  IntColumn get tensionLevel => integer().withDefault(const Constant(5))(); // 1 to 10
  TextColumn get status => text().withDefault(const Constant('Outlined'))(); // Idea, Outlined, Written
  IntColumn get orderIndex => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LoreEntries extends Table {
  TextColumn get id => text()();
  TextColumn get universeId => text().references(Universes, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get category => text()(); // Faction, Location, Magic/Tech, History, Culture, Artifact, Religion
  TextColumn get summary => text().nullable()();
  TextColumn get content => text().nullable()();
  TextColumn get tags => text().nullable()(); // comma-separated tags
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class IdeaSparks extends Table {
  TextColumn get id => text()();
  TextColumn get universeId => text().references(Universes, #id, onDelete: KeyAction.cascade)();
  TextColumn get content => text()();
  TextColumn get category => text().withDefault(const Constant('General'))(); // Dialogue, Scene Idea, Character Quirk, World Lore
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isConverted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Universes,
  Characters,
  CharacterRelationships,
  Chapters,
  Scenes,
  LoreEntries,
  IdeaSparks,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? c.connect());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
