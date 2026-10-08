import 'package:drift/drift.dart';
import 'connection/connection.dart' as c;

part 'app_database.g.dart';

/// Books: Folders / collections that group multiple project drafts / volumes
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get genre => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Projects: Individual book / story drafts
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().nullable().references(Books, #id, onDelete: KeyAction.setNull)();
  TextColumn get name => text()();
  TextColumn get genre => text()();
  TextColumn get generalIdea => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Arcs: Major narrative arcs in the project (starts with Arc 1)
class Arcs extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()(); // e.g. "Arc 1" - editable
  TextColumn get content => text().withDefault(const Constant(''))();
  IntColumn get orderIndex => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Chapters: Structured chapter outlines with 3-beat template (starts with Chapter 1)
class Chapters extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()(); // e.g. "Chapter 1" - editable
  IntColumn get orderIndex => integer()();
  TextColumn get startBeat => text().withDefault(const Constant(''))(); // Hook + situation setup
  TextColumn get middleBeat => text().withDefault(const Constant(''))(); // Main conflict + development
  TextColumn get endBeat => text().withDefault(const Constant(''))(); // Turning point or hook / cliffhanger
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// CustomSections: Additional writer-defined sections with custom editable headings
class CustomSections extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()(); // Custom user-defined heading
  TextColumn get content => text().withDefault(const Constant(''))();
  IntColumn get orderIndex => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Books, Projects, Arcs, Chapters, CustomSections])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(c.connect());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
      );
}
