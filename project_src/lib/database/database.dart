import 'package:drift/drift.dart';

part 'database.g.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get themeMode => text()(); // light, dark, system
  BoolColumn get notificationsEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get dailyQuotesEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text()(); // Upcoming, Active, Paused, Frozen, Completed
  IntColumn get targetWords => integer()();
  IntColumn get writtenWords => integer().withDefault(const Constant(0))();
  IntColumn get remainingWords => integer()();
  IntColumn get dailyWordTarget => integer()();
  IntColumn get backlogWords => integer().withDefault(const Constant(0))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get expectedFinishDate => dateTime()();
  DateTimeColumn get actualFinishDate => dateTime().nullable()();
  TextColumn get restMode => text()(); // Fixed, Flexible, Random
  IntColumn get allowedRestDays => integer().withDefault(const Constant(0))();
  IntColumn get remainingRestDays => integer().withDefault(const Constant(0))();
  IntColumn get projectStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestProjectStreak => integer().withDefault(const Constant(0))();
  IntColumn get currentWeek => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get coverImagePath => text().nullable()();
  TextColumn get coverType => text().nullable()();
  TextColumn get projectType => text().withDefault(const Constant('fixed'))();
  IntColumn get pendingCarryForward => integer().withDefault(const Constant(0))();
  TextColumn get ongoingStyle => text().nullable().withDefault(const Constant('daily'))();
  TextColumn get writingSession => text().nullable().withDefault(const Constant('none'))();
  DateTimeColumn get frozenDate => dateTime().nullable()();
  DateTimeColumn get freezeActivatedAt => dateTime().nullable()();
  TextColumn get groupId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}


class Schedules extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().customConstraint('REFERENCES projects(id) ON DELETE CASCADE')();
  DateTimeColumn get date => dateTime()();
  IntColumn get plannedWords => integer()();
  BoolColumn get isRestDay => boolean().withDefault(const Constant(false))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  BoolColumn get automaticRestDay => boolean().withDefault(const Constant(false))();
  BoolColumn get locked => boolean().withDefault(const Constant(false))();
  BoolColumn get isRecoveryDay => boolean().withDefault(const Constant(false))();
  BoolColumn get isShielded => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {projectId, date},
      ];
}

class DailyLogs extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().customConstraint('REFERENCES projects(id) ON DELETE CASCADE')();
  TextColumn get scheduleId => text().nullable().customConstraint('REFERENCES schedules(id) ON DELETE CASCADE')();
  DateTimeColumn get date => dateTime()();
  IntColumn get plannedWords => integer()();
  IntColumn get actualWords => integer()();
  IntColumn get carryForwardWords => integer().withDefault(const Constant(0))();
  IntColumn get backlogCreated => integer().withDefault(const Constant(0))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get loggedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class StatisticsTable extends Table {
  TextColumn get id => text()();
  IntColumn get lifetimeWords => integer().withDefault(const Constant(0))();
  RealColumn get averageWordsPerDay => real().withDefault(const Constant(0.0))();
  IntColumn get currentGlobalStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestGlobalStreak => integer().withDefault(const Constant(0))();
  IntColumn get projectsCompleted => integer().withDefault(const Constant(0))();
  IntColumn get writingDays => integer().withDefault(const Constant(0))();
  IntColumn get restDaysUsed => integer().withDefault(const Constant(0))();
  IntColumn get currentBacklog => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Achievements extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  DateTimeColumn get earnedDate => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

}

class Quotes extends Table {
  TextColumn get id => text()();
  TextColumn get textContent => text()();
  TextColumn get author => text()();
  TextColumn get category => text()(); // Discipline, Consistency, Writing, Success, Failure, Focus, Creativity, Persistence
  TextColumn get mood => text()(); // Encouraging, Tough Love, Inspirational, Funny, Calm

  @override
  Set<Column> get primaryKey => {id};
}

class SettingsTable extends Table {
  TextColumn get id => text()();
  TextColumn get theme => text().withDefault(const Constant('system'))();
  BoolColumn get notifications => boolean().withDefault(const Constant(true))();
  BoolColumn get dailyQuotes => boolean().withDefault(const Constant(true))();
  BoolColumn get backupReminder => boolean().withDefault(const Constant(true))();
  BoolColumn get vibration => boolean().withDefault(const Constant(true))();
  IntColumn get streakShields => integer().withDefault(const Constant(2))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Users,
  Projects,
  Schedules,
  DailyLogs,
  StatisticsTable,
  Achievements,
  Quotes,
  SettingsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(projects, projects.coverImagePath);
          await m.addColumn(projects, projects.coverType);
        }
        if (from < 3) {
          await m.addColumn(projects, projects.projectType);
        }
        if (from < 4) {
          await m.addColumn(projects, projects.pendingCarryForward);
        }
        if (from < 5) {
          await m.addColumn(projects, projects.ongoingStyle);
          await m.addColumn(schedules, schedules.isRecoveryDay);
        }
        if (from < 6) {
          await m.addColumn(projects, projects.writingSession);
        }
        if (from < 7) {
          await m.addColumn(schedules, schedules.isShielded);
          await m.addColumn(settingsTable, settingsTable.streakShields);
          await m.addColumn(projects, projects.frozenDate);
          await m.addColumn(projects, projects.freezeActivatedAt);
        }
        if (from < 8) {
          await m.addColumn(projects, projects.groupId);
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys in SQLite
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
