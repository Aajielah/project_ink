// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _themeModeMeta =
      const VerificationMeta('themeMode');
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
      'theme_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
      'notifications_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notifications_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _dailyQuotesEnabledMeta =
      const VerificationMeta('dailyQuotesEnabled');
  @override
  late final GeneratedColumn<bool> dailyQuotesEnabled = GeneratedColumn<bool>(
      'daily_quotes_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("daily_quotes_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        createdAt,
        themeMode,
        notificationsEnabled,
        dailyQuotesEnabled
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('theme_mode')) {
      context.handle(_themeModeMeta,
          themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta));
    } else if (isInserting) {
      context.missing(_themeModeMeta);
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
          _notificationsEnabledMeta,
          notificationsEnabled.isAcceptableOrUnknown(
              data['notifications_enabled']!, _notificationsEnabledMeta));
    }
    if (data.containsKey('daily_quotes_enabled')) {
      context.handle(
          _dailyQuotesEnabledMeta,
          dailyQuotesEnabled.isAcceptableOrUnknown(
              data['daily_quotes_enabled']!, _dailyQuotesEnabledMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      themeMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme_mode'])!,
      notificationsEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}notifications_enabled'])!,
      dailyQuotesEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}daily_quotes_enabled'])!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String name;
  final DateTime createdAt;
  final String themeMode;
  final bool notificationsEnabled;
  final bool dailyQuotesEnabled;
  const User(
      {required this.id,
      required this.name,
      required this.createdAt,
      required this.themeMode,
      required this.notificationsEnabled,
      required this.dailyQuotesEnabled});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['theme_mode'] = Variable<String>(themeMode);
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    map['daily_quotes_enabled'] = Variable<bool>(dailyQuotesEnabled);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      themeMode: Value(themeMode),
      notificationsEnabled: Value(notificationsEnabled),
      dailyQuotesEnabled: Value(dailyQuotesEnabled),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      notificationsEnabled:
          serializer.fromJson<bool>(json['notificationsEnabled']),
      dailyQuotesEnabled: serializer.fromJson<bool>(json['dailyQuotesEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'themeMode': serializer.toJson<String>(themeMode),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
      'dailyQuotesEnabled': serializer.toJson<bool>(dailyQuotesEnabled),
    };
  }

  User copyWith(
          {String? id,
          String? name,
          DateTime? createdAt,
          String? themeMode,
          bool? notificationsEnabled,
          bool? dailyQuotesEnabled}) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        themeMode: themeMode ?? this.themeMode,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        dailyQuotesEnabled: dailyQuotesEnabled ?? this.dailyQuotesEnabled,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      dailyQuotesEnabled: data.dailyQuotesEnabled.present
          ? data.dailyQuotesEnabled.value
          : this.dailyQuotesEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('themeMode: $themeMode, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('dailyQuotesEnabled: $dailyQuotesEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, createdAt, themeMode, notificationsEnabled, dailyQuotesEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.themeMode == this.themeMode &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.dailyQuotesEnabled == this.dailyQuotesEnabled);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<String> themeMode;
  final Value<bool> notificationsEnabled;
  final Value<bool> dailyQuotesEnabled;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.dailyQuotesEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    required String themeMode,
    this.notificationsEnabled = const Value.absent(),
    this.dailyQuotesEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        themeMode = Value(themeMode);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<String>? themeMode,
    Expression<bool>? notificationsEnabled,
    Expression<bool>? dailyQuotesEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (themeMode != null) 'theme_mode': themeMode,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (dailyQuotesEnabled != null)
        'daily_quotes_enabled': dailyQuotesEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<DateTime>? createdAt,
      Value<String>? themeMode,
      Value<bool>? notificationsEnabled,
      Value<bool>? dailyQuotesEnabled,
      Value<int>? rowid}) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyQuotesEnabled: dailyQuotesEnabled ?? this.dailyQuotesEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (dailyQuotesEnabled.present) {
      map['daily_quotes_enabled'] = Variable<bool>(dailyQuotesEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('themeMode: $themeMode, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('dailyQuotesEnabled: $dailyQuotesEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetWordsMeta =
      const VerificationMeta('targetWords');
  @override
  late final GeneratedColumn<int> targetWords = GeneratedColumn<int>(
      'target_words', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _writtenWordsMeta =
      const VerificationMeta('writtenWords');
  @override
  late final GeneratedColumn<int> writtenWords = GeneratedColumn<int>(
      'written_words', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _remainingWordsMeta =
      const VerificationMeta('remainingWords');
  @override
  late final GeneratedColumn<int> remainingWords = GeneratedColumn<int>(
      'remaining_words', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dailyWordTargetMeta =
      const VerificationMeta('dailyWordTarget');
  @override
  late final GeneratedColumn<int> dailyWordTarget = GeneratedColumn<int>(
      'daily_word_target', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _backlogWordsMeta =
      const VerificationMeta('backlogWords');
  @override
  late final GeneratedColumn<int> backlogWords = GeneratedColumn<int>(
      'backlog_words', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _expectedFinishDateMeta =
      const VerificationMeta('expectedFinishDate');
  @override
  late final GeneratedColumn<DateTime> expectedFinishDate =
      GeneratedColumn<DateTime>('expected_finish_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _actualFinishDateMeta =
      const VerificationMeta('actualFinishDate');
  @override
  late final GeneratedColumn<DateTime> actualFinishDate =
      GeneratedColumn<DateTime>('actual_finish_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _restModeMeta =
      const VerificationMeta('restMode');
  @override
  late final GeneratedColumn<String> restMode = GeneratedColumn<String>(
      'rest_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _allowedRestDaysMeta =
      const VerificationMeta('allowedRestDays');
  @override
  late final GeneratedColumn<int> allowedRestDays = GeneratedColumn<int>(
      'allowed_rest_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _remainingRestDaysMeta =
      const VerificationMeta('remainingRestDays');
  @override
  late final GeneratedColumn<int> remainingRestDays = GeneratedColumn<int>(
      'remaining_rest_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _projectStreakMeta =
      const VerificationMeta('projectStreak');
  @override
  late final GeneratedColumn<int> projectStreak = GeneratedColumn<int>(
      'project_streak', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _longestProjectStreakMeta =
      const VerificationMeta('longestProjectStreak');
  @override
  late final GeneratedColumn<int> longestProjectStreak = GeneratedColumn<int>(
      'longest_project_streak', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentWeekMeta =
      const VerificationMeta('currentWeek');
  @override
  late final GeneratedColumn<int> currentWeek = GeneratedColumn<int>(
      'current_week', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        description,
        status,
        targetWords,
        writtenWords,
        remainingWords,
        dailyWordTarget,
        backlogWords,
        startDate,
        expectedFinishDate,
        actualFinishDate,
        restMode,
        allowedRestDays,
        remainingRestDays,
        projectStreak,
        longestProjectStreak,
        currentWeek,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(Insertable<Project> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('target_words')) {
      context.handle(
          _targetWordsMeta,
          targetWords.isAcceptableOrUnknown(
              data['target_words']!, _targetWordsMeta));
    } else if (isInserting) {
      context.missing(_targetWordsMeta);
    }
    if (data.containsKey('written_words')) {
      context.handle(
          _writtenWordsMeta,
          writtenWords.isAcceptableOrUnknown(
              data['written_words']!, _writtenWordsMeta));
    }
    if (data.containsKey('remaining_words')) {
      context.handle(
          _remainingWordsMeta,
          remainingWords.isAcceptableOrUnknown(
              data['remaining_words']!, _remainingWordsMeta));
    } else if (isInserting) {
      context.missing(_remainingWordsMeta);
    }
    if (data.containsKey('daily_word_target')) {
      context.handle(
          _dailyWordTargetMeta,
          dailyWordTarget.isAcceptableOrUnknown(
              data['daily_word_target']!, _dailyWordTargetMeta));
    } else if (isInserting) {
      context.missing(_dailyWordTargetMeta);
    }
    if (data.containsKey('backlog_words')) {
      context.handle(
          _backlogWordsMeta,
          backlogWords.isAcceptableOrUnknown(
              data['backlog_words']!, _backlogWordsMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('expected_finish_date')) {
      context.handle(
          _expectedFinishDateMeta,
          expectedFinishDate.isAcceptableOrUnknown(
              data['expected_finish_date']!, _expectedFinishDateMeta));
    } else if (isInserting) {
      context.missing(_expectedFinishDateMeta);
    }
    if (data.containsKey('actual_finish_date')) {
      context.handle(
          _actualFinishDateMeta,
          actualFinishDate.isAcceptableOrUnknown(
              data['actual_finish_date']!, _actualFinishDateMeta));
    }
    if (data.containsKey('rest_mode')) {
      context.handle(_restModeMeta,
          restMode.isAcceptableOrUnknown(data['rest_mode']!, _restModeMeta));
    } else if (isInserting) {
      context.missing(_restModeMeta);
    }
    if (data.containsKey('allowed_rest_days')) {
      context.handle(
          _allowedRestDaysMeta,
          allowedRestDays.isAcceptableOrUnknown(
              data['allowed_rest_days']!, _allowedRestDaysMeta));
    }
    if (data.containsKey('remaining_rest_days')) {
      context.handle(
          _remainingRestDaysMeta,
          remainingRestDays.isAcceptableOrUnknown(
              data['remaining_rest_days']!, _remainingRestDaysMeta));
    }
    if (data.containsKey('project_streak')) {
      context.handle(
          _projectStreakMeta,
          projectStreak.isAcceptableOrUnknown(
              data['project_streak']!, _projectStreakMeta));
    }
    if (data.containsKey('longest_project_streak')) {
      context.handle(
          _longestProjectStreakMeta,
          longestProjectStreak.isAcceptableOrUnknown(
              data['longest_project_streak']!, _longestProjectStreakMeta));
    }
    if (data.containsKey('current_week')) {
      context.handle(
          _currentWeekMeta,
          currentWeek.isAcceptableOrUnknown(
              data['current_week']!, _currentWeekMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      targetWords: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_words'])!,
      writtenWords: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}written_words'])!,
      remainingWords: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remaining_words'])!,
      dailyWordTarget: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}daily_word_target'])!,
      backlogWords: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}backlog_words'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      expectedFinishDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}expected_finish_date'])!,
      actualFinishDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}actual_finish_date']),
      restMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rest_mode'])!,
      allowedRestDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}allowed_rest_days'])!,
      remainingRestDays: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}remaining_rest_days'])!,
      projectStreak: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_streak'])!,
      longestProjectStreak: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}longest_project_streak'])!,
      currentWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_week'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final String id;
  final String name;
  final String? description;
  final String status;
  final int targetWords;
  final int writtenWords;
  final int remainingWords;
  final int dailyWordTarget;
  final int backlogWords;
  final DateTime startDate;
  final DateTime expectedFinishDate;
  final DateTime? actualFinishDate;
  final String restMode;
  final int allowedRestDays;
  final int remainingRestDays;
  final int projectStreak;
  final int longestProjectStreak;
  final int currentWeek;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Project(
      {required this.id,
      required this.name,
      this.description,
      required this.status,
      required this.targetWords,
      required this.writtenWords,
      required this.remainingWords,
      required this.dailyWordTarget,
      required this.backlogWords,
      required this.startDate,
      required this.expectedFinishDate,
      this.actualFinishDate,
      required this.restMode,
      required this.allowedRestDays,
      required this.remainingRestDays,
      required this.projectStreak,
      required this.longestProjectStreak,
      required this.currentWeek,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['status'] = Variable<String>(status);
    map['target_words'] = Variable<int>(targetWords);
    map['written_words'] = Variable<int>(writtenWords);
    map['remaining_words'] = Variable<int>(remainingWords);
    map['daily_word_target'] = Variable<int>(dailyWordTarget);
    map['backlog_words'] = Variable<int>(backlogWords);
    map['start_date'] = Variable<DateTime>(startDate);
    map['expected_finish_date'] = Variable<DateTime>(expectedFinishDate);
    if (!nullToAbsent || actualFinishDate != null) {
      map['actual_finish_date'] = Variable<DateTime>(actualFinishDate);
    }
    map['rest_mode'] = Variable<String>(restMode);
    map['allowed_rest_days'] = Variable<int>(allowedRestDays);
    map['remaining_rest_days'] = Variable<int>(remainingRestDays);
    map['project_streak'] = Variable<int>(projectStreak);
    map['longest_project_streak'] = Variable<int>(longestProjectStreak);
    map['current_week'] = Variable<int>(currentWeek);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      status: Value(status),
      targetWords: Value(targetWords),
      writtenWords: Value(writtenWords),
      remainingWords: Value(remainingWords),
      dailyWordTarget: Value(dailyWordTarget),
      backlogWords: Value(backlogWords),
      startDate: Value(startDate),
      expectedFinishDate: Value(expectedFinishDate),
      actualFinishDate: actualFinishDate == null && nullToAbsent
          ? const Value.absent()
          : Value(actualFinishDate),
      restMode: Value(restMode),
      allowedRestDays: Value(allowedRestDays),
      remainingRestDays: Value(remainingRestDays),
      projectStreak: Value(projectStreak),
      longestProjectStreak: Value(longestProjectStreak),
      currentWeek: Value(currentWeek),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Project.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      targetWords: serializer.fromJson<int>(json['targetWords']),
      writtenWords: serializer.fromJson<int>(json['writtenWords']),
      remainingWords: serializer.fromJson<int>(json['remainingWords']),
      dailyWordTarget: serializer.fromJson<int>(json['dailyWordTarget']),
      backlogWords: serializer.fromJson<int>(json['backlogWords']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      expectedFinishDate:
          serializer.fromJson<DateTime>(json['expectedFinishDate']),
      actualFinishDate:
          serializer.fromJson<DateTime?>(json['actualFinishDate']),
      restMode: serializer.fromJson<String>(json['restMode']),
      allowedRestDays: serializer.fromJson<int>(json['allowedRestDays']),
      remainingRestDays: serializer.fromJson<int>(json['remainingRestDays']),
      projectStreak: serializer.fromJson<int>(json['projectStreak']),
      longestProjectStreak:
          serializer.fromJson<int>(json['longestProjectStreak']),
      currentWeek: serializer.fromJson<int>(json['currentWeek']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'status': serializer.toJson<String>(status),
      'targetWords': serializer.toJson<int>(targetWords),
      'writtenWords': serializer.toJson<int>(writtenWords),
      'remainingWords': serializer.toJson<int>(remainingWords),
      'dailyWordTarget': serializer.toJson<int>(dailyWordTarget),
      'backlogWords': serializer.toJson<int>(backlogWords),
      'startDate': serializer.toJson<DateTime>(startDate),
      'expectedFinishDate': serializer.toJson<DateTime>(expectedFinishDate),
      'actualFinishDate': serializer.toJson<DateTime?>(actualFinishDate),
      'restMode': serializer.toJson<String>(restMode),
      'allowedRestDays': serializer.toJson<int>(allowedRestDays),
      'remainingRestDays': serializer.toJson<int>(remainingRestDays),
      'projectStreak': serializer.toJson<int>(projectStreak),
      'longestProjectStreak': serializer.toJson<int>(longestProjectStreak),
      'currentWeek': serializer.toJson<int>(currentWeek),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Project copyWith(
          {String? id,
          String? name,
          Value<String?> description = const Value.absent(),
          String? status,
          int? targetWords,
          int? writtenWords,
          int? remainingWords,
          int? dailyWordTarget,
          int? backlogWords,
          DateTime? startDate,
          DateTime? expectedFinishDate,
          Value<DateTime?> actualFinishDate = const Value.absent(),
          String? restMode,
          int? allowedRestDays,
          int? remainingRestDays,
          int? projectStreak,
          int? longestProjectStreak,
          int? currentWeek,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Project(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        status: status ?? this.status,
        targetWords: targetWords ?? this.targetWords,
        writtenWords: writtenWords ?? this.writtenWords,
        remainingWords: remainingWords ?? this.remainingWords,
        dailyWordTarget: dailyWordTarget ?? this.dailyWordTarget,
        backlogWords: backlogWords ?? this.backlogWords,
        startDate: startDate ?? this.startDate,
        expectedFinishDate: expectedFinishDate ?? this.expectedFinishDate,
        actualFinishDate: actualFinishDate.present
            ? actualFinishDate.value
            : this.actualFinishDate,
        restMode: restMode ?? this.restMode,
        allowedRestDays: allowedRestDays ?? this.allowedRestDays,
        remainingRestDays: remainingRestDays ?? this.remainingRestDays,
        projectStreak: projectStreak ?? this.projectStreak,
        longestProjectStreak: longestProjectStreak ?? this.longestProjectStreak,
        currentWeek: currentWeek ?? this.currentWeek,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      status: data.status.present ? data.status.value : this.status,
      targetWords:
          data.targetWords.present ? data.targetWords.value : this.targetWords,
      writtenWords: data.writtenWords.present
          ? data.writtenWords.value
          : this.writtenWords,
      remainingWords: data.remainingWords.present
          ? data.remainingWords.value
          : this.remainingWords,
      dailyWordTarget: data.dailyWordTarget.present
          ? data.dailyWordTarget.value
          : this.dailyWordTarget,
      backlogWords: data.backlogWords.present
          ? data.backlogWords.value
          : this.backlogWords,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      expectedFinishDate: data.expectedFinishDate.present
          ? data.expectedFinishDate.value
          : this.expectedFinishDate,
      actualFinishDate: data.actualFinishDate.present
          ? data.actualFinishDate.value
          : this.actualFinishDate,
      restMode: data.restMode.present ? data.restMode.value : this.restMode,
      allowedRestDays: data.allowedRestDays.present
          ? data.allowedRestDays.value
          : this.allowedRestDays,
      remainingRestDays: data.remainingRestDays.present
          ? data.remainingRestDays.value
          : this.remainingRestDays,
      projectStreak: data.projectStreak.present
          ? data.projectStreak.value
          : this.projectStreak,
      longestProjectStreak: data.longestProjectStreak.present
          ? data.longestProjectStreak.value
          : this.longestProjectStreak,
      currentWeek:
          data.currentWeek.present ? data.currentWeek.value : this.currentWeek,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('targetWords: $targetWords, ')
          ..write('writtenWords: $writtenWords, ')
          ..write('remainingWords: $remainingWords, ')
          ..write('dailyWordTarget: $dailyWordTarget, ')
          ..write('backlogWords: $backlogWords, ')
          ..write('startDate: $startDate, ')
          ..write('expectedFinishDate: $expectedFinishDate, ')
          ..write('actualFinishDate: $actualFinishDate, ')
          ..write('restMode: $restMode, ')
          ..write('allowedRestDays: $allowedRestDays, ')
          ..write('remainingRestDays: $remainingRestDays, ')
          ..write('projectStreak: $projectStreak, ')
          ..write('longestProjectStreak: $longestProjectStreak, ')
          ..write('currentWeek: $currentWeek, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      description,
      status,
      targetWords,
      writtenWords,
      remainingWords,
      dailyWordTarget,
      backlogWords,
      startDate,
      expectedFinishDate,
      actualFinishDate,
      restMode,
      allowedRestDays,
      remainingRestDays,
      projectStreak,
      longestProjectStreak,
      currentWeek,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.status == this.status &&
          other.targetWords == this.targetWords &&
          other.writtenWords == this.writtenWords &&
          other.remainingWords == this.remainingWords &&
          other.dailyWordTarget == this.dailyWordTarget &&
          other.backlogWords == this.backlogWords &&
          other.startDate == this.startDate &&
          other.expectedFinishDate == this.expectedFinishDate &&
          other.actualFinishDate == this.actualFinishDate &&
          other.restMode == this.restMode &&
          other.allowedRestDays == this.allowedRestDays &&
          other.remainingRestDays == this.remainingRestDays &&
          other.projectStreak == this.projectStreak &&
          other.longestProjectStreak == this.longestProjectStreak &&
          other.currentWeek == this.currentWeek &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> status;
  final Value<int> targetWords;
  final Value<int> writtenWords;
  final Value<int> remainingWords;
  final Value<int> dailyWordTarget;
  final Value<int> backlogWords;
  final Value<DateTime> startDate;
  final Value<DateTime> expectedFinishDate;
  final Value<DateTime?> actualFinishDate;
  final Value<String> restMode;
  final Value<int> allowedRestDays;
  final Value<int> remainingRestDays;
  final Value<int> projectStreak;
  final Value<int> longestProjectStreak;
  final Value<int> currentWeek;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.targetWords = const Value.absent(),
    this.writtenWords = const Value.absent(),
    this.remainingWords = const Value.absent(),
    this.dailyWordTarget = const Value.absent(),
    this.backlogWords = const Value.absent(),
    this.startDate = const Value.absent(),
    this.expectedFinishDate = const Value.absent(),
    this.actualFinishDate = const Value.absent(),
    this.restMode = const Value.absent(),
    this.allowedRestDays = const Value.absent(),
    this.remainingRestDays = const Value.absent(),
    this.projectStreak = const Value.absent(),
    this.longestProjectStreak = const Value.absent(),
    this.currentWeek = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required String status,
    required int targetWords,
    this.writtenWords = const Value.absent(),
    required int remainingWords,
    required int dailyWordTarget,
    this.backlogWords = const Value.absent(),
    required DateTime startDate,
    required DateTime expectedFinishDate,
    this.actualFinishDate = const Value.absent(),
    required String restMode,
    this.allowedRestDays = const Value.absent(),
    this.remainingRestDays = const Value.absent(),
    this.projectStreak = const Value.absent(),
    this.longestProjectStreak = const Value.absent(),
    this.currentWeek = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        status = Value(status),
        targetWords = Value(targetWords),
        remainingWords = Value(remainingWords),
        dailyWordTarget = Value(dailyWordTarget),
        startDate = Value(startDate),
        expectedFinishDate = Value(expectedFinishDate),
        restMode = Value(restMode),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? status,
    Expression<int>? targetWords,
    Expression<int>? writtenWords,
    Expression<int>? remainingWords,
    Expression<int>? dailyWordTarget,
    Expression<int>? backlogWords,
    Expression<DateTime>? startDate,
    Expression<DateTime>? expectedFinishDate,
    Expression<DateTime>? actualFinishDate,
    Expression<String>? restMode,
    Expression<int>? allowedRestDays,
    Expression<int>? remainingRestDays,
    Expression<int>? projectStreak,
    Expression<int>? longestProjectStreak,
    Expression<int>? currentWeek,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (targetWords != null) 'target_words': targetWords,
      if (writtenWords != null) 'written_words': writtenWords,
      if (remainingWords != null) 'remaining_words': remainingWords,
      if (dailyWordTarget != null) 'daily_word_target': dailyWordTarget,
      if (backlogWords != null) 'backlog_words': backlogWords,
      if (startDate != null) 'start_date': startDate,
      if (expectedFinishDate != null)
        'expected_finish_date': expectedFinishDate,
      if (actualFinishDate != null) 'actual_finish_date': actualFinishDate,
      if (restMode != null) 'rest_mode': restMode,
      if (allowedRestDays != null) 'allowed_rest_days': allowedRestDays,
      if (remainingRestDays != null) 'remaining_rest_days': remainingRestDays,
      if (projectStreak != null) 'project_streak': projectStreak,
      if (longestProjectStreak != null)
        'longest_project_streak': longestProjectStreak,
      if (currentWeek != null) 'current_week': currentWeek,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<String>? status,
      Value<int>? targetWords,
      Value<int>? writtenWords,
      Value<int>? remainingWords,
      Value<int>? dailyWordTarget,
      Value<int>? backlogWords,
      Value<DateTime>? startDate,
      Value<DateTime>? expectedFinishDate,
      Value<DateTime?>? actualFinishDate,
      Value<String>? restMode,
      Value<int>? allowedRestDays,
      Value<int>? remainingRestDays,
      Value<int>? projectStreak,
      Value<int>? longestProjectStreak,
      Value<int>? currentWeek,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      targetWords: targetWords ?? this.targetWords,
      writtenWords: writtenWords ?? this.writtenWords,
      remainingWords: remainingWords ?? this.remainingWords,
      dailyWordTarget: dailyWordTarget ?? this.dailyWordTarget,
      backlogWords: backlogWords ?? this.backlogWords,
      startDate: startDate ?? this.startDate,
      expectedFinishDate: expectedFinishDate ?? this.expectedFinishDate,
      actualFinishDate: actualFinishDate ?? this.actualFinishDate,
      restMode: restMode ?? this.restMode,
      allowedRestDays: allowedRestDays ?? this.allowedRestDays,
      remainingRestDays: remainingRestDays ?? this.remainingRestDays,
      projectStreak: projectStreak ?? this.projectStreak,
      longestProjectStreak: longestProjectStreak ?? this.longestProjectStreak,
      currentWeek: currentWeek ?? this.currentWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (targetWords.present) {
      map['target_words'] = Variable<int>(targetWords.value);
    }
    if (writtenWords.present) {
      map['written_words'] = Variable<int>(writtenWords.value);
    }
    if (remainingWords.present) {
      map['remaining_words'] = Variable<int>(remainingWords.value);
    }
    if (dailyWordTarget.present) {
      map['daily_word_target'] = Variable<int>(dailyWordTarget.value);
    }
    if (backlogWords.present) {
      map['backlog_words'] = Variable<int>(backlogWords.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (expectedFinishDate.present) {
      map['expected_finish_date'] =
          Variable<DateTime>(expectedFinishDate.value);
    }
    if (actualFinishDate.present) {
      map['actual_finish_date'] = Variable<DateTime>(actualFinishDate.value);
    }
    if (restMode.present) {
      map['rest_mode'] = Variable<String>(restMode.value);
    }
    if (allowedRestDays.present) {
      map['allowed_rest_days'] = Variable<int>(allowedRestDays.value);
    }
    if (remainingRestDays.present) {
      map['remaining_rest_days'] = Variable<int>(remainingRestDays.value);
    }
    if (projectStreak.present) {
      map['project_streak'] = Variable<int>(projectStreak.value);
    }
    if (longestProjectStreak.present) {
      map['longest_project_streak'] = Variable<int>(longestProjectStreak.value);
    }
    if (currentWeek.present) {
      map['current_week'] = Variable<int>(currentWeek.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('targetWords: $targetWords, ')
          ..write('writtenWords: $writtenWords, ')
          ..write('remainingWords: $remainingWords, ')
          ..write('dailyWordTarget: $dailyWordTarget, ')
          ..write('backlogWords: $backlogWords, ')
          ..write('startDate: $startDate, ')
          ..write('expectedFinishDate: $expectedFinishDate, ')
          ..write('actualFinishDate: $actualFinishDate, ')
          ..write('restMode: $restMode, ')
          ..write('allowedRestDays: $allowedRestDays, ')
          ..write('remainingRestDays: $remainingRestDays, ')
          ..write('projectStreak: $projectStreak, ')
          ..write('longestProjectStreak: $longestProjectStreak, ')
          ..write('currentWeek: $currentWeek, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SchedulesTable extends Schedules
    with TableInfo<$SchedulesTable, Schedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
      'project_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES projects(id) ON DELETE CASCADE');
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _plannedWordsMeta =
      const VerificationMeta('plannedWords');
  @override
  late final GeneratedColumn<int> plannedWords = GeneratedColumn<int>(
      'planned_words', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isRestDayMeta =
      const VerificationMeta('isRestDay');
  @override
  late final GeneratedColumn<bool> isRestDay = GeneratedColumn<bool>(
      'is_rest_day', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_rest_day" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _automaticRestDayMeta =
      const VerificationMeta('automaticRestDay');
  @override
  late final GeneratedColumn<bool> automaticRestDay = GeneratedColumn<bool>(
      'automatic_rest_day', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("automatic_rest_day" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lockedMeta = const VerificationMeta('locked');
  @override
  late final GeneratedColumn<bool> locked = GeneratedColumn<bool>(
      'locked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("locked" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        date,
        plannedWords,
        isRestDay,
        completed,
        automaticRestDay,
        locked
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedules';
  @override
  VerificationContext validateIntegrity(Insertable<Schedule> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('planned_words')) {
      context.handle(
          _plannedWordsMeta,
          plannedWords.isAcceptableOrUnknown(
              data['planned_words']!, _plannedWordsMeta));
    } else if (isInserting) {
      context.missing(_plannedWordsMeta);
    }
    if (data.containsKey('is_rest_day')) {
      context.handle(
          _isRestDayMeta,
          isRestDay.isAcceptableOrUnknown(
              data['is_rest_day']!, _isRestDayMeta));
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    }
    if (data.containsKey('automatic_rest_day')) {
      context.handle(
          _automaticRestDayMeta,
          automaticRestDay.isAcceptableOrUnknown(
              data['automatic_rest_day']!, _automaticRestDayMeta));
    }
    if (data.containsKey('locked')) {
      context.handle(_lockedMeta,
          locked.isAcceptableOrUnknown(data['locked']!, _lockedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {projectId, date},
      ];
  @override
  Schedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Schedule(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      plannedWords: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}planned_words'])!,
      isRestDay: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_rest_day'])!,
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
      automaticRestDay: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}automatic_rest_day'])!,
      locked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}locked'])!,
    );
  }

  @override
  $SchedulesTable createAlias(String alias) {
    return $SchedulesTable(attachedDatabase, alias);
  }
}

class Schedule extends DataClass implements Insertable<Schedule> {
  final String id;
  final String projectId;
  final DateTime date;
  final int plannedWords;
  final bool isRestDay;
  final bool completed;
  final bool automaticRestDay;
  final bool locked;
  const Schedule(
      {required this.id,
      required this.projectId,
      required this.date,
      required this.plannedWords,
      required this.isRestDay,
      required this.completed,
      required this.automaticRestDay,
      required this.locked});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['date'] = Variable<DateTime>(date);
    map['planned_words'] = Variable<int>(plannedWords);
    map['is_rest_day'] = Variable<bool>(isRestDay);
    map['completed'] = Variable<bool>(completed);
    map['automatic_rest_day'] = Variable<bool>(automaticRestDay);
    map['locked'] = Variable<bool>(locked);
    return map;
  }

  SchedulesCompanion toCompanion(bool nullToAbsent) {
    return SchedulesCompanion(
      id: Value(id),
      projectId: Value(projectId),
      date: Value(date),
      plannedWords: Value(plannedWords),
      isRestDay: Value(isRestDay),
      completed: Value(completed),
      automaticRestDay: Value(automaticRestDay),
      locked: Value(locked),
    );
  }

  factory Schedule.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Schedule(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      date: serializer.fromJson<DateTime>(json['date']),
      plannedWords: serializer.fromJson<int>(json['plannedWords']),
      isRestDay: serializer.fromJson<bool>(json['isRestDay']),
      completed: serializer.fromJson<bool>(json['completed']),
      automaticRestDay: serializer.fromJson<bool>(json['automaticRestDay']),
      locked: serializer.fromJson<bool>(json['locked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'date': serializer.toJson<DateTime>(date),
      'plannedWords': serializer.toJson<int>(plannedWords),
      'isRestDay': serializer.toJson<bool>(isRestDay),
      'completed': serializer.toJson<bool>(completed),
      'automaticRestDay': serializer.toJson<bool>(automaticRestDay),
      'locked': serializer.toJson<bool>(locked),
    };
  }

  Schedule copyWith(
          {String? id,
          String? projectId,
          DateTime? date,
          int? plannedWords,
          bool? isRestDay,
          bool? completed,
          bool? automaticRestDay,
          bool? locked}) =>
      Schedule(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        date: date ?? this.date,
        plannedWords: plannedWords ?? this.plannedWords,
        isRestDay: isRestDay ?? this.isRestDay,
        completed: completed ?? this.completed,
        automaticRestDay: automaticRestDay ?? this.automaticRestDay,
        locked: locked ?? this.locked,
      );
  Schedule copyWithCompanion(SchedulesCompanion data) {
    return Schedule(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      date: data.date.present ? data.date.value : this.date,
      plannedWords: data.plannedWords.present
          ? data.plannedWords.value
          : this.plannedWords,
      isRestDay: data.isRestDay.present ? data.isRestDay.value : this.isRestDay,
      completed: data.completed.present ? data.completed.value : this.completed,
      automaticRestDay: data.automaticRestDay.present
          ? data.automaticRestDay.value
          : this.automaticRestDay,
      locked: data.locked.present ? data.locked.value : this.locked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Schedule(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('date: $date, ')
          ..write('plannedWords: $plannedWords, ')
          ..write('isRestDay: $isRestDay, ')
          ..write('completed: $completed, ')
          ..write('automaticRestDay: $automaticRestDay, ')
          ..write('locked: $locked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, date, plannedWords, isRestDay,
      completed, automaticRestDay, locked);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Schedule &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.date == this.date &&
          other.plannedWords == this.plannedWords &&
          other.isRestDay == this.isRestDay &&
          other.completed == this.completed &&
          other.automaticRestDay == this.automaticRestDay &&
          other.locked == this.locked);
}

class SchedulesCompanion extends UpdateCompanion<Schedule> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<DateTime> date;
  final Value<int> plannedWords;
  final Value<bool> isRestDay;
  final Value<bool> completed;
  final Value<bool> automaticRestDay;
  final Value<bool> locked;
  final Value<int> rowid;
  const SchedulesCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.date = const Value.absent(),
    this.plannedWords = const Value.absent(),
    this.isRestDay = const Value.absent(),
    this.completed = const Value.absent(),
    this.automaticRestDay = const Value.absent(),
    this.locked = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchedulesCompanion.insert({
    required String id,
    required String projectId,
    required DateTime date,
    required int plannedWords,
    this.isRestDay = const Value.absent(),
    this.completed = const Value.absent(),
    this.automaticRestDay = const Value.absent(),
    this.locked = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        projectId = Value(projectId),
        date = Value(date),
        plannedWords = Value(plannedWords);
  static Insertable<Schedule> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<DateTime>? date,
    Expression<int>? plannedWords,
    Expression<bool>? isRestDay,
    Expression<bool>? completed,
    Expression<bool>? automaticRestDay,
    Expression<bool>? locked,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (date != null) 'date': date,
      if (plannedWords != null) 'planned_words': plannedWords,
      if (isRestDay != null) 'is_rest_day': isRestDay,
      if (completed != null) 'completed': completed,
      if (automaticRestDay != null) 'automatic_rest_day': automaticRestDay,
      if (locked != null) 'locked': locked,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchedulesCompanion copyWith(
      {Value<String>? id,
      Value<String>? projectId,
      Value<DateTime>? date,
      Value<int>? plannedWords,
      Value<bool>? isRestDay,
      Value<bool>? completed,
      Value<bool>? automaticRestDay,
      Value<bool>? locked,
      Value<int>? rowid}) {
    return SchedulesCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      plannedWords: plannedWords ?? this.plannedWords,
      isRestDay: isRestDay ?? this.isRestDay,
      completed: completed ?? this.completed,
      automaticRestDay: automaticRestDay ?? this.automaticRestDay,
      locked: locked ?? this.locked,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (plannedWords.present) {
      map['planned_words'] = Variable<int>(plannedWords.value);
    }
    if (isRestDay.present) {
      map['is_rest_day'] = Variable<bool>(isRestDay.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (automaticRestDay.present) {
      map['automatic_rest_day'] = Variable<bool>(automaticRestDay.value);
    }
    if (locked.present) {
      map['locked'] = Variable<bool>(locked.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchedulesCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('date: $date, ')
          ..write('plannedWords: $plannedWords, ')
          ..write('isRestDay: $isRestDay, ')
          ..write('completed: $completed, ')
          ..write('automaticRestDay: $automaticRestDay, ')
          ..write('locked: $locked, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyLogsTable extends DailyLogs
    with TableInfo<$DailyLogsTable, DailyLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
      'project_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES projects(id) ON DELETE CASCADE');
  static const VerificationMeta _scheduleIdMeta =
      const VerificationMeta('scheduleId');
  @override
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
      'schedule_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'REFERENCES schedules(id) ON DELETE SET NULL');
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _plannedWordsMeta =
      const VerificationMeta('plannedWords');
  @override
  late final GeneratedColumn<int> plannedWords = GeneratedColumn<int>(
      'planned_words', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _actualWordsMeta =
      const VerificationMeta('actualWords');
  @override
  late final GeneratedColumn<int> actualWords = GeneratedColumn<int>(
      'actual_words', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _carryForwardWordsMeta =
      const VerificationMeta('carryForwardWords');
  @override
  late final GeneratedColumn<int> carryForwardWords = GeneratedColumn<int>(
      'carry_forward_words', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _backlogCreatedMeta =
      const VerificationMeta('backlogCreated');
  @override
  late final GeneratedColumn<int> backlogCreated = GeneratedColumn<int>(
      'backlog_created', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _loggedAtMeta =
      const VerificationMeta('loggedAt');
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
      'logged_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        scheduleId,
        date,
        plannedWords,
        actualWords,
        carryForwardWords,
        backlogCreated,
        completed,
        loggedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_logs';
  @override
  VerificationContext validateIntegrity(Insertable<DailyLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('schedule_id')) {
      context.handle(
          _scheduleIdMeta,
          scheduleId.isAcceptableOrUnknown(
              data['schedule_id']!, _scheduleIdMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('planned_words')) {
      context.handle(
          _plannedWordsMeta,
          plannedWords.isAcceptableOrUnknown(
              data['planned_words']!, _plannedWordsMeta));
    } else if (isInserting) {
      context.missing(_plannedWordsMeta);
    }
    if (data.containsKey('actual_words')) {
      context.handle(
          _actualWordsMeta,
          actualWords.isAcceptableOrUnknown(
              data['actual_words']!, _actualWordsMeta));
    } else if (isInserting) {
      context.missing(_actualWordsMeta);
    }
    if (data.containsKey('carry_forward_words')) {
      context.handle(
          _carryForwardWordsMeta,
          carryForwardWords.isAcceptableOrUnknown(
              data['carry_forward_words']!, _carryForwardWordsMeta));
    }
    if (data.containsKey('backlog_created')) {
      context.handle(
          _backlogCreatedMeta,
          backlogCreated.isAcceptableOrUnknown(
              data['backlog_created']!, _backlogCreatedMeta));
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    }
    if (data.containsKey('logged_at')) {
      context.handle(_loggedAtMeta,
          loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta));
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {projectId, date},
      ];
  @override
  DailyLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
      scheduleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}schedule_id']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      plannedWords: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}planned_words'])!,
      actualWords: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}actual_words'])!,
      carryForwardWords: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}carry_forward_words'])!,
      backlogCreated: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}backlog_created'])!,
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
      loggedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}logged_at'])!,
    );
  }

  @override
  $DailyLogsTable createAlias(String alias) {
    return $DailyLogsTable(attachedDatabase, alias);
  }
}

class DailyLog extends DataClass implements Insertable<DailyLog> {
  final String id;
  final String projectId;
  final String? scheduleId;
  final DateTime date;
  final int plannedWords;
  final int actualWords;
  final int carryForwardWords;
  final int backlogCreated;
  final bool completed;
  final DateTime loggedAt;
  const DailyLog(
      {required this.id,
      required this.projectId,
      this.scheduleId,
      required this.date,
      required this.plannedWords,
      required this.actualWords,
      required this.carryForwardWords,
      required this.backlogCreated,
      required this.completed,
      required this.loggedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    if (!nullToAbsent || scheduleId != null) {
      map['schedule_id'] = Variable<String>(scheduleId);
    }
    map['date'] = Variable<DateTime>(date);
    map['planned_words'] = Variable<int>(plannedWords);
    map['actual_words'] = Variable<int>(actualWords);
    map['carry_forward_words'] = Variable<int>(carryForwardWords);
    map['backlog_created'] = Variable<int>(backlogCreated);
    map['completed'] = Variable<bool>(completed);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    return map;
  }

  DailyLogsCompanion toCompanion(bool nullToAbsent) {
    return DailyLogsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      scheduleId: scheduleId == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduleId),
      date: Value(date),
      plannedWords: Value(plannedWords),
      actualWords: Value(actualWords),
      carryForwardWords: Value(carryForwardWords),
      backlogCreated: Value(backlogCreated),
      completed: Value(completed),
      loggedAt: Value(loggedAt),
    );
  }

  factory DailyLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyLog(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      scheduleId: serializer.fromJson<String?>(json['scheduleId']),
      date: serializer.fromJson<DateTime>(json['date']),
      plannedWords: serializer.fromJson<int>(json['plannedWords']),
      actualWords: serializer.fromJson<int>(json['actualWords']),
      carryForwardWords: serializer.fromJson<int>(json['carryForwardWords']),
      backlogCreated: serializer.fromJson<int>(json['backlogCreated']),
      completed: serializer.fromJson<bool>(json['completed']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'scheduleId': serializer.toJson<String?>(scheduleId),
      'date': serializer.toJson<DateTime>(date),
      'plannedWords': serializer.toJson<int>(plannedWords),
      'actualWords': serializer.toJson<int>(actualWords),
      'carryForwardWords': serializer.toJson<int>(carryForwardWords),
      'backlogCreated': serializer.toJson<int>(backlogCreated),
      'completed': serializer.toJson<bool>(completed),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
    };
  }

  DailyLog copyWith(
          {String? id,
          String? projectId,
          Value<String?> scheduleId = const Value.absent(),
          DateTime? date,
          int? plannedWords,
          int? actualWords,
          int? carryForwardWords,
          int? backlogCreated,
          bool? completed,
          DateTime? loggedAt}) =>
      DailyLog(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        scheduleId: scheduleId.present ? scheduleId.value : this.scheduleId,
        date: date ?? this.date,
        plannedWords: plannedWords ?? this.plannedWords,
        actualWords: actualWords ?? this.actualWords,
        carryForwardWords: carryForwardWords ?? this.carryForwardWords,
        backlogCreated: backlogCreated ?? this.backlogCreated,
        completed: completed ?? this.completed,
        loggedAt: loggedAt ?? this.loggedAt,
      );
  DailyLog copyWithCompanion(DailyLogsCompanion data) {
    return DailyLog(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      scheduleId:
          data.scheduleId.present ? data.scheduleId.value : this.scheduleId,
      date: data.date.present ? data.date.value : this.date,
      plannedWords: data.plannedWords.present
          ? data.plannedWords.value
          : this.plannedWords,
      actualWords:
          data.actualWords.present ? data.actualWords.value : this.actualWords,
      carryForwardWords: data.carryForwardWords.present
          ? data.carryForwardWords.value
          : this.carryForwardWords,
      backlogCreated: data.backlogCreated.present
          ? data.backlogCreated.value
          : this.backlogCreated,
      completed: data.completed.present ? data.completed.value : this.completed,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyLog(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('date: $date, ')
          ..write('plannedWords: $plannedWords, ')
          ..write('actualWords: $actualWords, ')
          ..write('carryForwardWords: $carryForwardWords, ')
          ..write('backlogCreated: $backlogCreated, ')
          ..write('completed: $completed, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, scheduleId, date, plannedWords,
      actualWords, carryForwardWords, backlogCreated, completed, loggedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyLog &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.scheduleId == this.scheduleId &&
          other.date == this.date &&
          other.plannedWords == this.plannedWords &&
          other.actualWords == this.actualWords &&
          other.carryForwardWords == this.carryForwardWords &&
          other.backlogCreated == this.backlogCreated &&
          other.completed == this.completed &&
          other.loggedAt == this.loggedAt);
}

class DailyLogsCompanion extends UpdateCompanion<DailyLog> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String?> scheduleId;
  final Value<DateTime> date;
  final Value<int> plannedWords;
  final Value<int> actualWords;
  final Value<int> carryForwardWords;
  final Value<int> backlogCreated;
  final Value<bool> completed;
  final Value<DateTime> loggedAt;
  final Value<int> rowid;
  const DailyLogsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.scheduleId = const Value.absent(),
    this.date = const Value.absent(),
    this.plannedWords = const Value.absent(),
    this.actualWords = const Value.absent(),
    this.carryForwardWords = const Value.absent(),
    this.backlogCreated = const Value.absent(),
    this.completed = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyLogsCompanion.insert({
    required String id,
    required String projectId,
    this.scheduleId = const Value.absent(),
    required DateTime date,
    required int plannedWords,
    required int actualWords,
    this.carryForwardWords = const Value.absent(),
    this.backlogCreated = const Value.absent(),
    this.completed = const Value.absent(),
    required DateTime loggedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        projectId = Value(projectId),
        date = Value(date),
        plannedWords = Value(plannedWords),
        actualWords = Value(actualWords),
        loggedAt = Value(loggedAt);
  static Insertable<DailyLog> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? scheduleId,
    Expression<DateTime>? date,
    Expression<int>? plannedWords,
    Expression<int>? actualWords,
    Expression<int>? carryForwardWords,
    Expression<int>? backlogCreated,
    Expression<bool>? completed,
    Expression<DateTime>? loggedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (date != null) 'date': date,
      if (plannedWords != null) 'planned_words': plannedWords,
      if (actualWords != null) 'actual_words': actualWords,
      if (carryForwardWords != null) 'carry_forward_words': carryForwardWords,
      if (backlogCreated != null) 'backlog_created': backlogCreated,
      if (completed != null) 'completed': completed,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? projectId,
      Value<String?>? scheduleId,
      Value<DateTime>? date,
      Value<int>? plannedWords,
      Value<int>? actualWords,
      Value<int>? carryForwardWords,
      Value<int>? backlogCreated,
      Value<bool>? completed,
      Value<DateTime>? loggedAt,
      Value<int>? rowid}) {
    return DailyLogsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      scheduleId: scheduleId ?? this.scheduleId,
      date: date ?? this.date,
      plannedWords: plannedWords ?? this.plannedWords,
      actualWords: actualWords ?? this.actualWords,
      carryForwardWords: carryForwardWords ?? this.carryForwardWords,
      backlogCreated: backlogCreated ?? this.backlogCreated,
      completed: completed ?? this.completed,
      loggedAt: loggedAt ?? this.loggedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (scheduleId.present) {
      map['schedule_id'] = Variable<String>(scheduleId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (plannedWords.present) {
      map['planned_words'] = Variable<int>(plannedWords.value);
    }
    if (actualWords.present) {
      map['actual_words'] = Variable<int>(actualWords.value);
    }
    if (carryForwardWords.present) {
      map['carry_forward_words'] = Variable<int>(carryForwardWords.value);
    }
    if (backlogCreated.present) {
      map['backlog_created'] = Variable<int>(backlogCreated.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyLogsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('date: $date, ')
          ..write('plannedWords: $plannedWords, ')
          ..write('actualWords: $actualWords, ')
          ..write('carryForwardWords: $carryForwardWords, ')
          ..write('backlogCreated: $backlogCreated, ')
          ..write('completed: $completed, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StatisticsTableTable extends StatisticsTable
    with TableInfo<$StatisticsTableTable, StatisticsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StatisticsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lifetimeWordsMeta =
      const VerificationMeta('lifetimeWords');
  @override
  late final GeneratedColumn<int> lifetimeWords = GeneratedColumn<int>(
      'lifetime_words', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _averageWordsPerDayMeta =
      const VerificationMeta('averageWordsPerDay');
  @override
  late final GeneratedColumn<double> averageWordsPerDay =
      GeneratedColumn<double>('average_words_per_day', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  static const VerificationMeta _currentGlobalStreakMeta =
      const VerificationMeta('currentGlobalStreak');
  @override
  late final GeneratedColumn<int> currentGlobalStreak = GeneratedColumn<int>(
      'current_global_streak', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _longestGlobalStreakMeta =
      const VerificationMeta('longestGlobalStreak');
  @override
  late final GeneratedColumn<int> longestGlobalStreak = GeneratedColumn<int>(
      'longest_global_streak', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _projectsCompletedMeta =
      const VerificationMeta('projectsCompleted');
  @override
  late final GeneratedColumn<int> projectsCompleted = GeneratedColumn<int>(
      'projects_completed', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _writingDaysMeta =
      const VerificationMeta('writingDays');
  @override
  late final GeneratedColumn<int> writingDays = GeneratedColumn<int>(
      'writing_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _restDaysUsedMeta =
      const VerificationMeta('restDaysUsed');
  @override
  late final GeneratedColumn<int> restDaysUsed = GeneratedColumn<int>(
      'rest_days_used', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentBacklogMeta =
      const VerificationMeta('currentBacklog');
  @override
  late final GeneratedColumn<int> currentBacklog = GeneratedColumn<int>(
      'current_backlog', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        lifetimeWords,
        averageWordsPerDay,
        currentGlobalStreak,
        longestGlobalStreak,
        projectsCompleted,
        writingDays,
        restDaysUsed,
        currentBacklog
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'statistics_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<StatisticsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lifetime_words')) {
      context.handle(
          _lifetimeWordsMeta,
          lifetimeWords.isAcceptableOrUnknown(
              data['lifetime_words']!, _lifetimeWordsMeta));
    }
    if (data.containsKey('average_words_per_day')) {
      context.handle(
          _averageWordsPerDayMeta,
          averageWordsPerDay.isAcceptableOrUnknown(
              data['average_words_per_day']!, _averageWordsPerDayMeta));
    }
    if (data.containsKey('current_global_streak')) {
      context.handle(
          _currentGlobalStreakMeta,
          currentGlobalStreak.isAcceptableOrUnknown(
              data['current_global_streak']!, _currentGlobalStreakMeta));
    }
    if (data.containsKey('longest_global_streak')) {
      context.handle(
          _longestGlobalStreakMeta,
          longestGlobalStreak.isAcceptableOrUnknown(
              data['longest_global_streak']!, _longestGlobalStreakMeta));
    }
    if (data.containsKey('projects_completed')) {
      context.handle(
          _projectsCompletedMeta,
          projectsCompleted.isAcceptableOrUnknown(
              data['projects_completed']!, _projectsCompletedMeta));
    }
    if (data.containsKey('writing_days')) {
      context.handle(
          _writingDaysMeta,
          writingDays.isAcceptableOrUnknown(
              data['writing_days']!, _writingDaysMeta));
    }
    if (data.containsKey('rest_days_used')) {
      context.handle(
          _restDaysUsedMeta,
          restDaysUsed.isAcceptableOrUnknown(
              data['rest_days_used']!, _restDaysUsedMeta));
    }
    if (data.containsKey('current_backlog')) {
      context.handle(
          _currentBacklogMeta,
          currentBacklog.isAcceptableOrUnknown(
              data['current_backlog']!, _currentBacklogMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StatisticsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StatisticsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      lifetimeWords: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lifetime_words'])!,
      averageWordsPerDay: attachedDatabase.typeMapping.read(DriftSqlType.double,
          data['${effectivePrefix}average_words_per_day'])!,
      currentGlobalStreak: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_global_streak'])!,
      longestGlobalStreak: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}longest_global_streak'])!,
      projectsCompleted: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}projects_completed'])!,
      writingDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}writing_days'])!,
      restDaysUsed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rest_days_used'])!,
      currentBacklog: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_backlog'])!,
    );
  }

  @override
  $StatisticsTableTable createAlias(String alias) {
    return $StatisticsTableTable(attachedDatabase, alias);
  }
}

class StatisticsTableData extends DataClass
    implements Insertable<StatisticsTableData> {
  final String id;
  final int lifetimeWords;
  final double averageWordsPerDay;
  final int currentGlobalStreak;
  final int longestGlobalStreak;
  final int projectsCompleted;
  final int writingDays;
  final int restDaysUsed;
  final int currentBacklog;
  const StatisticsTableData(
      {required this.id,
      required this.lifetimeWords,
      required this.averageWordsPerDay,
      required this.currentGlobalStreak,
      required this.longestGlobalStreak,
      required this.projectsCompleted,
      required this.writingDays,
      required this.restDaysUsed,
      required this.currentBacklog});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lifetime_words'] = Variable<int>(lifetimeWords);
    map['average_words_per_day'] = Variable<double>(averageWordsPerDay);
    map['current_global_streak'] = Variable<int>(currentGlobalStreak);
    map['longest_global_streak'] = Variable<int>(longestGlobalStreak);
    map['projects_completed'] = Variable<int>(projectsCompleted);
    map['writing_days'] = Variable<int>(writingDays);
    map['rest_days_used'] = Variable<int>(restDaysUsed);
    map['current_backlog'] = Variable<int>(currentBacklog);
    return map;
  }

  StatisticsTableCompanion toCompanion(bool nullToAbsent) {
    return StatisticsTableCompanion(
      id: Value(id),
      lifetimeWords: Value(lifetimeWords),
      averageWordsPerDay: Value(averageWordsPerDay),
      currentGlobalStreak: Value(currentGlobalStreak),
      longestGlobalStreak: Value(longestGlobalStreak),
      projectsCompleted: Value(projectsCompleted),
      writingDays: Value(writingDays),
      restDaysUsed: Value(restDaysUsed),
      currentBacklog: Value(currentBacklog),
    );
  }

  factory StatisticsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StatisticsTableData(
      id: serializer.fromJson<String>(json['id']),
      lifetimeWords: serializer.fromJson<int>(json['lifetimeWords']),
      averageWordsPerDay:
          serializer.fromJson<double>(json['averageWordsPerDay']),
      currentGlobalStreak:
          serializer.fromJson<int>(json['currentGlobalStreak']),
      longestGlobalStreak:
          serializer.fromJson<int>(json['longestGlobalStreak']),
      projectsCompleted: serializer.fromJson<int>(json['projectsCompleted']),
      writingDays: serializer.fromJson<int>(json['writingDays']),
      restDaysUsed: serializer.fromJson<int>(json['restDaysUsed']),
      currentBacklog: serializer.fromJson<int>(json['currentBacklog']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lifetimeWords': serializer.toJson<int>(lifetimeWords),
      'averageWordsPerDay': serializer.toJson<double>(averageWordsPerDay),
      'currentGlobalStreak': serializer.toJson<int>(currentGlobalStreak),
      'longestGlobalStreak': serializer.toJson<int>(longestGlobalStreak),
      'projectsCompleted': serializer.toJson<int>(projectsCompleted),
      'writingDays': serializer.toJson<int>(writingDays),
      'restDaysUsed': serializer.toJson<int>(restDaysUsed),
      'currentBacklog': serializer.toJson<int>(currentBacklog),
    };
  }

  StatisticsTableData copyWith(
          {String? id,
          int? lifetimeWords,
          double? averageWordsPerDay,
          int? currentGlobalStreak,
          int? longestGlobalStreak,
          int? projectsCompleted,
          int? writingDays,
          int? restDaysUsed,
          int? currentBacklog}) =>
      StatisticsTableData(
        id: id ?? this.id,
        lifetimeWords: lifetimeWords ?? this.lifetimeWords,
        averageWordsPerDay: averageWordsPerDay ?? this.averageWordsPerDay,
        currentGlobalStreak: currentGlobalStreak ?? this.currentGlobalStreak,
        longestGlobalStreak: longestGlobalStreak ?? this.longestGlobalStreak,
        projectsCompleted: projectsCompleted ?? this.projectsCompleted,
        writingDays: writingDays ?? this.writingDays,
        restDaysUsed: restDaysUsed ?? this.restDaysUsed,
        currentBacklog: currentBacklog ?? this.currentBacklog,
      );
  StatisticsTableData copyWithCompanion(StatisticsTableCompanion data) {
    return StatisticsTableData(
      id: data.id.present ? data.id.value : this.id,
      lifetimeWords: data.lifetimeWords.present
          ? data.lifetimeWords.value
          : this.lifetimeWords,
      averageWordsPerDay: data.averageWordsPerDay.present
          ? data.averageWordsPerDay.value
          : this.averageWordsPerDay,
      currentGlobalStreak: data.currentGlobalStreak.present
          ? data.currentGlobalStreak.value
          : this.currentGlobalStreak,
      longestGlobalStreak: data.longestGlobalStreak.present
          ? data.longestGlobalStreak.value
          : this.longestGlobalStreak,
      projectsCompleted: data.projectsCompleted.present
          ? data.projectsCompleted.value
          : this.projectsCompleted,
      writingDays:
          data.writingDays.present ? data.writingDays.value : this.writingDays,
      restDaysUsed: data.restDaysUsed.present
          ? data.restDaysUsed.value
          : this.restDaysUsed,
      currentBacklog: data.currentBacklog.present
          ? data.currentBacklog.value
          : this.currentBacklog,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StatisticsTableData(')
          ..write('id: $id, ')
          ..write('lifetimeWords: $lifetimeWords, ')
          ..write('averageWordsPerDay: $averageWordsPerDay, ')
          ..write('currentGlobalStreak: $currentGlobalStreak, ')
          ..write('longestGlobalStreak: $longestGlobalStreak, ')
          ..write('projectsCompleted: $projectsCompleted, ')
          ..write('writingDays: $writingDays, ')
          ..write('restDaysUsed: $restDaysUsed, ')
          ..write('currentBacklog: $currentBacklog')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      lifetimeWords,
      averageWordsPerDay,
      currentGlobalStreak,
      longestGlobalStreak,
      projectsCompleted,
      writingDays,
      restDaysUsed,
      currentBacklog);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StatisticsTableData &&
          other.id == this.id &&
          other.lifetimeWords == this.lifetimeWords &&
          other.averageWordsPerDay == this.averageWordsPerDay &&
          other.currentGlobalStreak == this.currentGlobalStreak &&
          other.longestGlobalStreak == this.longestGlobalStreak &&
          other.projectsCompleted == this.projectsCompleted &&
          other.writingDays == this.writingDays &&
          other.restDaysUsed == this.restDaysUsed &&
          other.currentBacklog == this.currentBacklog);
}

class StatisticsTableCompanion extends UpdateCompanion<StatisticsTableData> {
  final Value<String> id;
  final Value<int> lifetimeWords;
  final Value<double> averageWordsPerDay;
  final Value<int> currentGlobalStreak;
  final Value<int> longestGlobalStreak;
  final Value<int> projectsCompleted;
  final Value<int> writingDays;
  final Value<int> restDaysUsed;
  final Value<int> currentBacklog;
  final Value<int> rowid;
  const StatisticsTableCompanion({
    this.id = const Value.absent(),
    this.lifetimeWords = const Value.absent(),
    this.averageWordsPerDay = const Value.absent(),
    this.currentGlobalStreak = const Value.absent(),
    this.longestGlobalStreak = const Value.absent(),
    this.projectsCompleted = const Value.absent(),
    this.writingDays = const Value.absent(),
    this.restDaysUsed = const Value.absent(),
    this.currentBacklog = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StatisticsTableCompanion.insert({
    required String id,
    this.lifetimeWords = const Value.absent(),
    this.averageWordsPerDay = const Value.absent(),
    this.currentGlobalStreak = const Value.absent(),
    this.longestGlobalStreak = const Value.absent(),
    this.projectsCompleted = const Value.absent(),
    this.writingDays = const Value.absent(),
    this.restDaysUsed = const Value.absent(),
    this.currentBacklog = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<StatisticsTableData> custom({
    Expression<String>? id,
    Expression<int>? lifetimeWords,
    Expression<double>? averageWordsPerDay,
    Expression<int>? currentGlobalStreak,
    Expression<int>? longestGlobalStreak,
    Expression<int>? projectsCompleted,
    Expression<int>? writingDays,
    Expression<int>? restDaysUsed,
    Expression<int>? currentBacklog,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lifetimeWords != null) 'lifetime_words': lifetimeWords,
      if (averageWordsPerDay != null)
        'average_words_per_day': averageWordsPerDay,
      if (currentGlobalStreak != null)
        'current_global_streak': currentGlobalStreak,
      if (longestGlobalStreak != null)
        'longest_global_streak': longestGlobalStreak,
      if (projectsCompleted != null) 'projects_completed': projectsCompleted,
      if (writingDays != null) 'writing_days': writingDays,
      if (restDaysUsed != null) 'rest_days_used': restDaysUsed,
      if (currentBacklog != null) 'current_backlog': currentBacklog,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StatisticsTableCompanion copyWith(
      {Value<String>? id,
      Value<int>? lifetimeWords,
      Value<double>? averageWordsPerDay,
      Value<int>? currentGlobalStreak,
      Value<int>? longestGlobalStreak,
      Value<int>? projectsCompleted,
      Value<int>? writingDays,
      Value<int>? restDaysUsed,
      Value<int>? currentBacklog,
      Value<int>? rowid}) {
    return StatisticsTableCompanion(
      id: id ?? this.id,
      lifetimeWords: lifetimeWords ?? this.lifetimeWords,
      averageWordsPerDay: averageWordsPerDay ?? this.averageWordsPerDay,
      currentGlobalStreak: currentGlobalStreak ?? this.currentGlobalStreak,
      longestGlobalStreak: longestGlobalStreak ?? this.longestGlobalStreak,
      projectsCompleted: projectsCompleted ?? this.projectsCompleted,
      writingDays: writingDays ?? this.writingDays,
      restDaysUsed: restDaysUsed ?? this.restDaysUsed,
      currentBacklog: currentBacklog ?? this.currentBacklog,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lifetimeWords.present) {
      map['lifetime_words'] = Variable<int>(lifetimeWords.value);
    }
    if (averageWordsPerDay.present) {
      map['average_words_per_day'] = Variable<double>(averageWordsPerDay.value);
    }
    if (currentGlobalStreak.present) {
      map['current_global_streak'] = Variable<int>(currentGlobalStreak.value);
    }
    if (longestGlobalStreak.present) {
      map['longest_global_streak'] = Variable<int>(longestGlobalStreak.value);
    }
    if (projectsCompleted.present) {
      map['projects_completed'] = Variable<int>(projectsCompleted.value);
    }
    if (writingDays.present) {
      map['writing_days'] = Variable<int>(writingDays.value);
    }
    if (restDaysUsed.present) {
      map['rest_days_used'] = Variable<int>(restDaysUsed.value);
    }
    if (currentBacklog.present) {
      map['current_backlog'] = Variable<int>(currentBacklog.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StatisticsTableCompanion(')
          ..write('id: $id, ')
          ..write('lifetimeWords: $lifetimeWords, ')
          ..write('averageWordsPerDay: $averageWordsPerDay, ')
          ..write('currentGlobalStreak: $currentGlobalStreak, ')
          ..write('longestGlobalStreak: $longestGlobalStreak, ')
          ..write('projectsCompleted: $projectsCompleted, ')
          ..write('writingDays: $writingDays, ')
          ..write('restDaysUsed: $restDaysUsed, ')
          ..write('currentBacklog: $currentBacklog, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AchievementsTable extends Achievements
    with TableInfo<$AchievementsTable, Achievement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _earnedDateMeta =
      const VerificationMeta('earnedDate');
  @override
  late final GeneratedColumn<DateTime> earnedDate = GeneratedColumn<DateTime>(
      'earned_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, title, description, earnedDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievements';
  @override
  VerificationContext validateIntegrity(Insertable<Achievement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('earned_date')) {
      context.handle(
          _earnedDateMeta,
          earnedDate.isAcceptableOrUnknown(
              data['earned_date']!, _earnedDateMeta));
    } else if (isInserting) {
      context.missing(_earnedDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Achievement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Achievement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      earnedDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}earned_date'])!,
    );
  }

  @override
  $AchievementsTable createAlias(String alias) {
    return $AchievementsTable(attachedDatabase, alias);
  }
}

class Achievement extends DataClass implements Insertable<Achievement> {
  final String id;
  final String title;
  final String description;
  final DateTime earnedDate;
  const Achievement(
      {required this.id,
      required this.title,
      required this.description,
      required this.earnedDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['earned_date'] = Variable<DateTime>(earnedDate);
    return map;
  }

  AchievementsCompanion toCompanion(bool nullToAbsent) {
    return AchievementsCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      earnedDate: Value(earnedDate),
    );
  }

  factory Achievement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Achievement(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      earnedDate: serializer.fromJson<DateTime>(json['earnedDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'earnedDate': serializer.toJson<DateTime>(earnedDate),
    };
  }

  Achievement copyWith(
          {String? id,
          String? title,
          String? description,
          DateTime? earnedDate}) =>
      Achievement(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        earnedDate: earnedDate ?? this.earnedDate,
      );
  Achievement copyWithCompanion(AchievementsCompanion data) {
    return Achievement(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      earnedDate:
          data.earnedDate.present ? data.earnedDate.value : this.earnedDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Achievement(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('earnedDate: $earnedDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, description, earnedDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Achievement &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.earnedDate == this.earnedDate);
}

class AchievementsCompanion extends UpdateCompanion<Achievement> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> description;
  final Value<DateTime> earnedDate;
  final Value<int> rowid;
  const AchievementsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.earnedDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AchievementsCompanion.insert({
    required String id,
    required String title,
    required String description,
    required DateTime earnedDate,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        description = Value(description),
        earnedDate = Value(earnedDate);
  static Insertable<Achievement> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? earnedDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (earnedDate != null) 'earned_date': earnedDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AchievementsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? description,
      Value<DateTime>? earnedDate,
      Value<int>? rowid}) {
    return AchievementsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      earnedDate: earnedDate ?? this.earnedDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (earnedDate.present) {
      map['earned_date'] = Variable<DateTime>(earnedDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('earnedDate: $earnedDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuotesTable extends Quotes with TableInfo<$QuotesTable, Quote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _textContentMeta =
      const VerificationMeta('textContent');
  @override
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
      'text_content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
      'author', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
      'mood', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, textContent, author, category, mood];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quotes';
  @override
  VerificationContext validateIntegrity(Insertable<Quote> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('text_content')) {
      context.handle(
          _textContentMeta,
          textContent.isAcceptableOrUnknown(
              data['text_content']!, _textContentMeta));
    } else if (isInserting) {
      context.missing(_textContentMeta);
    }
    if (data.containsKey('author')) {
      context.handle(_authorMeta,
          author.isAcceptableOrUnknown(data['author']!, _authorMeta));
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
          _moodMeta, mood.isAcceptableOrUnknown(data['mood']!, _moodMeta));
    } else if (isInserting) {
      context.missing(_moodMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Quote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Quote(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      textContent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text_content'])!,
      author: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      mood: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mood'])!,
    );
  }

  @override
  $QuotesTable createAlias(String alias) {
    return $QuotesTable(attachedDatabase, alias);
  }
}

class Quote extends DataClass implements Insertable<Quote> {
  final String id;
  final String textContent;
  final String author;
  final String category;
  final String mood;
  const Quote(
      {required this.id,
      required this.textContent,
      required this.author,
      required this.category,
      required this.mood});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['text_content'] = Variable<String>(textContent);
    map['author'] = Variable<String>(author);
    map['category'] = Variable<String>(category);
    map['mood'] = Variable<String>(mood);
    return map;
  }

  QuotesCompanion toCompanion(bool nullToAbsent) {
    return QuotesCompanion(
      id: Value(id),
      textContent: Value(textContent),
      author: Value(author),
      category: Value(category),
      mood: Value(mood),
    );
  }

  factory Quote.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Quote(
      id: serializer.fromJson<String>(json['id']),
      textContent: serializer.fromJson<String>(json['textContent']),
      author: serializer.fromJson<String>(json['author']),
      category: serializer.fromJson<String>(json['category']),
      mood: serializer.fromJson<String>(json['mood']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'textContent': serializer.toJson<String>(textContent),
      'author': serializer.toJson<String>(author),
      'category': serializer.toJson<String>(category),
      'mood': serializer.toJson<String>(mood),
    };
  }

  Quote copyWith(
          {String? id,
          String? textContent,
          String? author,
          String? category,
          String? mood}) =>
      Quote(
        id: id ?? this.id,
        textContent: textContent ?? this.textContent,
        author: author ?? this.author,
        category: category ?? this.category,
        mood: mood ?? this.mood,
      );
  Quote copyWithCompanion(QuotesCompanion data) {
    return Quote(
      id: data.id.present ? data.id.value : this.id,
      textContent:
          data.textContent.present ? data.textContent.value : this.textContent,
      author: data.author.present ? data.author.value : this.author,
      category: data.category.present ? data.category.value : this.category,
      mood: data.mood.present ? data.mood.value : this.mood,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Quote(')
          ..write('id: $id, ')
          ..write('textContent: $textContent, ')
          ..write('author: $author, ')
          ..write('category: $category, ')
          ..write('mood: $mood')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, textContent, author, category, mood);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Quote &&
          other.id == this.id &&
          other.textContent == this.textContent &&
          other.author == this.author &&
          other.category == this.category &&
          other.mood == this.mood);
}

class QuotesCompanion extends UpdateCompanion<Quote> {
  final Value<String> id;
  final Value<String> textContent;
  final Value<String> author;
  final Value<String> category;
  final Value<String> mood;
  final Value<int> rowid;
  const QuotesCompanion({
    this.id = const Value.absent(),
    this.textContent = const Value.absent(),
    this.author = const Value.absent(),
    this.category = const Value.absent(),
    this.mood = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuotesCompanion.insert({
    required String id,
    required String textContent,
    required String author,
    required String category,
    required String mood,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        textContent = Value(textContent),
        author = Value(author),
        category = Value(category),
        mood = Value(mood);
  static Insertable<Quote> custom({
    Expression<String>? id,
    Expression<String>? textContent,
    Expression<String>? author,
    Expression<String>? category,
    Expression<String>? mood,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (textContent != null) 'text_content': textContent,
      if (author != null) 'author': author,
      if (category != null) 'category': category,
      if (mood != null) 'mood': mood,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuotesCompanion copyWith(
      {Value<String>? id,
      Value<String>? textContent,
      Value<String>? author,
      Value<String>? category,
      Value<String>? mood,
      Value<int>? rowid}) {
    return QuotesCompanion(
      id: id ?? this.id,
      textContent: textContent ?? this.textContent,
      author: author ?? this.author,
      category: category ?? this.category,
      mood: mood ?? this.mood,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (textContent.present) {
      map['text_content'] = Variable<String>(textContent.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuotesCompanion(')
          ..write('id: $id, ')
          ..write('textContent: $textContent, ')
          ..write('author: $author, ')
          ..write('category: $category, ')
          ..write('mood: $mood, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
      'theme', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('system'));
  static const VerificationMeta _notificationsMeta =
      const VerificationMeta('notifications');
  @override
  late final GeneratedColumn<bool> notifications = GeneratedColumn<bool>(
      'notifications', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notifications" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _dailyQuotesMeta =
      const VerificationMeta('dailyQuotes');
  @override
  late final GeneratedColumn<bool> dailyQuotes = GeneratedColumn<bool>(
      'daily_quotes', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("daily_quotes" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _backupReminderMeta =
      const VerificationMeta('backupReminder');
  @override
  late final GeneratedColumn<bool> backupReminder = GeneratedColumn<bool>(
      'backup_reminder', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("backup_reminder" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _vibrationMeta =
      const VerificationMeta('vibration');
  @override
  late final GeneratedColumn<bool> vibration = GeneratedColumn<bool>(
      'vibration', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("vibration" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, theme, notifications, dailyQuotes, backupReminder, vibration];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_table';
  @override
  VerificationContext validateIntegrity(Insertable<SettingsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('theme')) {
      context.handle(
          _themeMeta, theme.isAcceptableOrUnknown(data['theme']!, _themeMeta));
    }
    if (data.containsKey('notifications')) {
      context.handle(
          _notificationsMeta,
          notifications.isAcceptableOrUnknown(
              data['notifications']!, _notificationsMeta));
    }
    if (data.containsKey('daily_quotes')) {
      context.handle(
          _dailyQuotesMeta,
          dailyQuotes.isAcceptableOrUnknown(
              data['daily_quotes']!, _dailyQuotesMeta));
    }
    if (data.containsKey('backup_reminder')) {
      context.handle(
          _backupReminderMeta,
          backupReminder.isAcceptableOrUnknown(
              data['backup_reminder']!, _backupReminderMeta));
    }
    if (data.containsKey('vibration')) {
      context.handle(_vibrationMeta,
          vibration.isAcceptableOrUnknown(data['vibration']!, _vibrationMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      theme: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme'])!,
      notifications: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}notifications'])!,
      dailyQuotes: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}daily_quotes'])!,
      backupReminder: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}backup_reminder'])!,
      vibration: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}vibration'])!,
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingsTableData extends DataClass
    implements Insertable<SettingsTableData> {
  final String id;
  final String theme;
  final bool notifications;
  final bool dailyQuotes;
  final bool backupReminder;
  final bool vibration;
  const SettingsTableData(
      {required this.id,
      required this.theme,
      required this.notifications,
      required this.dailyQuotes,
      required this.backupReminder,
      required this.vibration});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['theme'] = Variable<String>(theme);
    map['notifications'] = Variable<bool>(notifications);
    map['daily_quotes'] = Variable<bool>(dailyQuotes);
    map['backup_reminder'] = Variable<bool>(backupReminder);
    map['vibration'] = Variable<bool>(vibration);
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(
      id: Value(id),
      theme: Value(theme),
      notifications: Value(notifications),
      dailyQuotes: Value(dailyQuotes),
      backupReminder: Value(backupReminder),
      vibration: Value(vibration),
    );
  }

  factory SettingsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsTableData(
      id: serializer.fromJson<String>(json['id']),
      theme: serializer.fromJson<String>(json['theme']),
      notifications: serializer.fromJson<bool>(json['notifications']),
      dailyQuotes: serializer.fromJson<bool>(json['dailyQuotes']),
      backupReminder: serializer.fromJson<bool>(json['backupReminder']),
      vibration: serializer.fromJson<bool>(json['vibration']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'theme': serializer.toJson<String>(theme),
      'notifications': serializer.toJson<bool>(notifications),
      'dailyQuotes': serializer.toJson<bool>(dailyQuotes),
      'backupReminder': serializer.toJson<bool>(backupReminder),
      'vibration': serializer.toJson<bool>(vibration),
    };
  }

  SettingsTableData copyWith(
          {String? id,
          String? theme,
          bool? notifications,
          bool? dailyQuotes,
          bool? backupReminder,
          bool? vibration}) =>
      SettingsTableData(
        id: id ?? this.id,
        theme: theme ?? this.theme,
        notifications: notifications ?? this.notifications,
        dailyQuotes: dailyQuotes ?? this.dailyQuotes,
        backupReminder: backupReminder ?? this.backupReminder,
        vibration: vibration ?? this.vibration,
      );
  SettingsTableData copyWithCompanion(SettingsTableCompanion data) {
    return SettingsTableData(
      id: data.id.present ? data.id.value : this.id,
      theme: data.theme.present ? data.theme.value : this.theme,
      notifications: data.notifications.present
          ? data.notifications.value
          : this.notifications,
      dailyQuotes:
          data.dailyQuotes.present ? data.dailyQuotes.value : this.dailyQuotes,
      backupReminder: data.backupReminder.present
          ? data.backupReminder.value
          : this.backupReminder,
      vibration: data.vibration.present ? data.vibration.value : this.vibration,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableData(')
          ..write('id: $id, ')
          ..write('theme: $theme, ')
          ..write('notifications: $notifications, ')
          ..write('dailyQuotes: $dailyQuotes, ')
          ..write('backupReminder: $backupReminder, ')
          ..write('vibration: $vibration')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, theme, notifications, dailyQuotes, backupReminder, vibration);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsTableData &&
          other.id == this.id &&
          other.theme == this.theme &&
          other.notifications == this.notifications &&
          other.dailyQuotes == this.dailyQuotes &&
          other.backupReminder == this.backupReminder &&
          other.vibration == this.vibration);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsTableData> {
  final Value<String> id;
  final Value<String> theme;
  final Value<bool> notifications;
  final Value<bool> dailyQuotes;
  final Value<bool> backupReminder;
  final Value<bool> vibration;
  final Value<int> rowid;
  const SettingsTableCompanion({
    this.id = const Value.absent(),
    this.theme = const Value.absent(),
    this.notifications = const Value.absent(),
    this.dailyQuotes = const Value.absent(),
    this.backupReminder = const Value.absent(),
    this.vibration = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    required String id,
    this.theme = const Value.absent(),
    this.notifications = const Value.absent(),
    this.dailyQuotes = const Value.absent(),
    this.backupReminder = const Value.absent(),
    this.vibration = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<SettingsTableData> custom({
    Expression<String>? id,
    Expression<String>? theme,
    Expression<bool>? notifications,
    Expression<bool>? dailyQuotes,
    Expression<bool>? backupReminder,
    Expression<bool>? vibration,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (theme != null) 'theme': theme,
      if (notifications != null) 'notifications': notifications,
      if (dailyQuotes != null) 'daily_quotes': dailyQuotes,
      if (backupReminder != null) 'backup_reminder': backupReminder,
      if (vibration != null) 'vibration': vibration,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? theme,
      Value<bool>? notifications,
      Value<bool>? dailyQuotes,
      Value<bool>? backupReminder,
      Value<bool>? vibration,
      Value<int>? rowid}) {
    return SettingsTableCompanion(
      id: id ?? this.id,
      theme: theme ?? this.theme,
      notifications: notifications ?? this.notifications,
      dailyQuotes: dailyQuotes ?? this.dailyQuotes,
      backupReminder: backupReminder ?? this.backupReminder,
      vibration: vibration ?? this.vibration,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (notifications.present) {
      map['notifications'] = Variable<bool>(notifications.value);
    }
    if (dailyQuotes.present) {
      map['daily_quotes'] = Variable<bool>(dailyQuotes.value);
    }
    if (backupReminder.present) {
      map['backup_reminder'] = Variable<bool>(backupReminder.value);
    }
    if (vibration.present) {
      map['vibration'] = Variable<bool>(vibration.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('theme: $theme, ')
          ..write('notifications: $notifications, ')
          ..write('dailyQuotes: $dailyQuotes, ')
          ..write('backupReminder: $backupReminder, ')
          ..write('vibration: $vibration, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $SchedulesTable schedules = $SchedulesTable(this);
  late final $DailyLogsTable dailyLogs = $DailyLogsTable(this);
  late final $StatisticsTableTable statisticsTable =
      $StatisticsTableTable(this);
  late final $AchievementsTable achievements = $AchievementsTable(this);
  late final $QuotesTable quotes = $QuotesTable(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        projects,
        schedules,
        dailyLogs,
        statisticsTable,
        achievements,
        quotes,
        settingsTable
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('projects',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('schedules', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('projects',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('daily_logs', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('schedules',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('daily_logs', kind: UpdateKind.update),
            ],
          ),
        ],
      );
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  required String name,
  required DateTime createdAt,
  required String themeMode,
  Value<bool> notificationsEnabled,
  Value<bool> dailyQuotesEnabled,
  Value<int> rowid,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<DateTime> createdAt,
  Value<String> themeMode,
  Value<bool> notificationsEnabled,
  Value<bool> dailyQuotesEnabled,
  Value<int> rowid,
});

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dailyQuotesEnabled => $composableBuilder(
      column: $table.dailyQuotesEnabled,
      builder: (column) => ColumnFilters(column));
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dailyQuotesEnabled => $composableBuilder(
      column: $table.dailyQuotesEnabled,
      builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<bool> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled, builder: (column) => column);

  GeneratedColumn<bool> get dailyQuotesEnabled => $composableBuilder(
      column: $table.dailyQuotesEnabled, builder: (column) => column);
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<bool> notificationsEnabled = const Value.absent(),
            Value<bool> dailyQuotesEnabled = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            name: name,
            createdAt: createdAt,
            themeMode: themeMode,
            notificationsEnabled: notificationsEnabled,
            dailyQuotesEnabled: dailyQuotesEnabled,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required DateTime createdAt,
            required String themeMode,
            Value<bool> notificationsEnabled = const Value.absent(),
            Value<bool> dailyQuotesEnabled = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            name: name,
            createdAt: createdAt,
            themeMode: themeMode,
            notificationsEnabled: notificationsEnabled,
            dailyQuotesEnabled: dailyQuotesEnabled,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()>;
typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  required String id,
  required String name,
  Value<String?> description,
  required String status,
  required int targetWords,
  Value<int> writtenWords,
  required int remainingWords,
  required int dailyWordTarget,
  Value<int> backlogWords,
  required DateTime startDate,
  required DateTime expectedFinishDate,
  Value<DateTime?> actualFinishDate,
  required String restMode,
  Value<int> allowedRestDays,
  Value<int> remainingRestDays,
  Value<int> projectStreak,
  Value<int> longestProjectStreak,
  Value<int> currentWeek,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<String> status,
  Value<int> targetWords,
  Value<int> writtenWords,
  Value<int> remainingWords,
  Value<int> dailyWordTarget,
  Value<int> backlogWords,
  Value<DateTime> startDate,
  Value<DateTime> expectedFinishDate,
  Value<DateTime?> actualFinishDate,
  Value<String> restMode,
  Value<int> allowedRestDays,
  Value<int> remainingRestDays,
  Value<int> projectStreak,
  Value<int> longestProjectStreak,
  Value<int> currentWeek,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ProjectsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SchedulesTable, List<Schedule>>
      _schedulesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.schedules,
              aliasName:
                  $_aliasNameGenerator(db.projects.id, db.schedules.projectId));

  $$SchedulesTableProcessedTableManager get schedulesRefs {
    final manager = $$SchedulesTableTableManager($_db, $_db.schedules)
        .filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_schedulesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DailyLogsTable, List<DailyLog>>
      _dailyLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.dailyLogs,
              aliasName:
                  $_aliasNameGenerator(db.projects.id, db.dailyLogs.projectId));

  $$DailyLogsTableProcessedTableManager get dailyLogsRefs {
    final manager = $$DailyLogsTableTableManager($_db, $_db.dailyLogs)
        .filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_dailyLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetWords => $composableBuilder(
      column: $table.targetWords, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get writtenWords => $composableBuilder(
      column: $table.writtenWords, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remainingWords => $composableBuilder(
      column: $table.remainingWords,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dailyWordTarget => $composableBuilder(
      column: $table.dailyWordTarget,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get backlogWords => $composableBuilder(
      column: $table.backlogWords, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expectedFinishDate => $composableBuilder(
      column: $table.expectedFinishDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get actualFinishDate => $composableBuilder(
      column: $table.actualFinishDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get restMode => $composableBuilder(
      column: $table.restMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get allowedRestDays => $composableBuilder(
      column: $table.allowedRestDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remainingRestDays => $composableBuilder(
      column: $table.remainingRestDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get projectStreak => $composableBuilder(
      column: $table.projectStreak, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get longestProjectStreak => $composableBuilder(
      column: $table.longestProjectStreak,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentWeek => $composableBuilder(
      column: $table.currentWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> schedulesRefs(
      Expression<bool> Function($$SchedulesTableFilterComposer f) f) {
    final $$SchedulesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.schedules,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SchedulesTableFilterComposer(
              $db: $db,
              $table: $db.schedules,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> dailyLogsRefs(
      Expression<bool> Function($$DailyLogsTableFilterComposer f) f) {
    final $$DailyLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.dailyLogs,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DailyLogsTableFilterComposer(
              $db: $db,
              $table: $db.dailyLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetWords => $composableBuilder(
      column: $table.targetWords, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get writtenWords => $composableBuilder(
      column: $table.writtenWords,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remainingWords => $composableBuilder(
      column: $table.remainingWords,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dailyWordTarget => $composableBuilder(
      column: $table.dailyWordTarget,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get backlogWords => $composableBuilder(
      column: $table.backlogWords,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expectedFinishDate => $composableBuilder(
      column: $table.expectedFinishDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get actualFinishDate => $composableBuilder(
      column: $table.actualFinishDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get restMode => $composableBuilder(
      column: $table.restMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get allowedRestDays => $composableBuilder(
      column: $table.allowedRestDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remainingRestDays => $composableBuilder(
      column: $table.remainingRestDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get projectStreak => $composableBuilder(
      column: $table.projectStreak,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get longestProjectStreak => $composableBuilder(
      column: $table.longestProjectStreak,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentWeek => $composableBuilder(
      column: $table.currentWeek, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get targetWords => $composableBuilder(
      column: $table.targetWords, builder: (column) => column);

  GeneratedColumn<int> get writtenWords => $composableBuilder(
      column: $table.writtenWords, builder: (column) => column);

  GeneratedColumn<int> get remainingWords => $composableBuilder(
      column: $table.remainingWords, builder: (column) => column);

  GeneratedColumn<int> get dailyWordTarget => $composableBuilder(
      column: $table.dailyWordTarget, builder: (column) => column);

  GeneratedColumn<int> get backlogWords => $composableBuilder(
      column: $table.backlogWords, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get expectedFinishDate => $composableBuilder(
      column: $table.expectedFinishDate, builder: (column) => column);

  GeneratedColumn<DateTime> get actualFinishDate => $composableBuilder(
      column: $table.actualFinishDate, builder: (column) => column);

  GeneratedColumn<String> get restMode =>
      $composableBuilder(column: $table.restMode, builder: (column) => column);

  GeneratedColumn<int> get allowedRestDays => $composableBuilder(
      column: $table.allowedRestDays, builder: (column) => column);

  GeneratedColumn<int> get remainingRestDays => $composableBuilder(
      column: $table.remainingRestDays, builder: (column) => column);

  GeneratedColumn<int> get projectStreak => $composableBuilder(
      column: $table.projectStreak, builder: (column) => column);

  GeneratedColumn<int> get longestProjectStreak => $composableBuilder(
      column: $table.longestProjectStreak, builder: (column) => column);

  GeneratedColumn<int> get currentWeek => $composableBuilder(
      column: $table.currentWeek, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> schedulesRefs<T extends Object>(
      Expression<T> Function($$SchedulesTableAnnotationComposer a) f) {
    final $$SchedulesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.schedules,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SchedulesTableAnnotationComposer(
              $db: $db,
              $table: $db.schedules,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> dailyLogsRefs<T extends Object>(
      Expression<T> Function($$DailyLogsTableAnnotationComposer a) f) {
    final $$DailyLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.dailyLogs,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DailyLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.dailyLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProjectsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, $$ProjectsTableReferences),
    Project,
    PrefetchHooks Function({bool schedulesRefs, bool dailyLogsRefs})> {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> targetWords = const Value.absent(),
            Value<int> writtenWords = const Value.absent(),
            Value<int> remainingWords = const Value.absent(),
            Value<int> dailyWordTarget = const Value.absent(),
            Value<int> backlogWords = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime> expectedFinishDate = const Value.absent(),
            Value<DateTime?> actualFinishDate = const Value.absent(),
            Value<String> restMode = const Value.absent(),
            Value<int> allowedRestDays = const Value.absent(),
            Value<int> remainingRestDays = const Value.absent(),
            Value<int> projectStreak = const Value.absent(),
            Value<int> longestProjectStreak = const Value.absent(),
            Value<int> currentWeek = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjectsCompanion(
            id: id,
            name: name,
            description: description,
            status: status,
            targetWords: targetWords,
            writtenWords: writtenWords,
            remainingWords: remainingWords,
            dailyWordTarget: dailyWordTarget,
            backlogWords: backlogWords,
            startDate: startDate,
            expectedFinishDate: expectedFinishDate,
            actualFinishDate: actualFinishDate,
            restMode: restMode,
            allowedRestDays: allowedRestDays,
            remainingRestDays: remainingRestDays,
            projectStreak: projectStreak,
            longestProjectStreak: longestProjectStreak,
            currentWeek: currentWeek,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> description = const Value.absent(),
            required String status,
            required int targetWords,
            Value<int> writtenWords = const Value.absent(),
            required int remainingWords,
            required int dailyWordTarget,
            Value<int> backlogWords = const Value.absent(),
            required DateTime startDate,
            required DateTime expectedFinishDate,
            Value<DateTime?> actualFinishDate = const Value.absent(),
            required String restMode,
            Value<int> allowedRestDays = const Value.absent(),
            Value<int> remainingRestDays = const Value.absent(),
            Value<int> projectStreak = const Value.absent(),
            Value<int> longestProjectStreak = const Value.absent(),
            Value<int> currentWeek = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjectsCompanion.insert(
            id: id,
            name: name,
            description: description,
            status: status,
            targetWords: targetWords,
            writtenWords: writtenWords,
            remainingWords: remainingWords,
            dailyWordTarget: dailyWordTarget,
            backlogWords: backlogWords,
            startDate: startDate,
            expectedFinishDate: expectedFinishDate,
            actualFinishDate: actualFinishDate,
            restMode: restMode,
            allowedRestDays: allowedRestDays,
            remainingRestDays: remainingRestDays,
            projectStreak: projectStreak,
            longestProjectStreak: longestProjectStreak,
            currentWeek: currentWeek,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProjectsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {schedulesRefs = false, dailyLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (schedulesRefs) db.schedules,
                if (dailyLogsRefs) db.dailyLogs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (schedulesRefs)
                    await $_getPrefetchedData<Project, $ProjectsTable,
                            Schedule>(
                        currentTable: table,
                        referencedTable:
                            $$ProjectsTableReferences._schedulesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableReferences(db, table, p0)
                                .schedulesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items),
                  if (dailyLogsRefs)
                    await $_getPrefetchedData<Project, $ProjectsTable,
                            DailyLog>(
                        currentTable: table,
                        referencedTable:
                            $$ProjectsTableReferences._dailyLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableReferences(db, table, p0)
                                .dailyLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProjectsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, $$ProjectsTableReferences),
    Project,
    PrefetchHooks Function({bool schedulesRefs, bool dailyLogsRefs})>;
typedef $$SchedulesTableCreateCompanionBuilder = SchedulesCompanion Function({
  required String id,
  required String projectId,
  required DateTime date,
  required int plannedWords,
  Value<bool> isRestDay,
  Value<bool> completed,
  Value<bool> automaticRestDay,
  Value<bool> locked,
  Value<int> rowid,
});
typedef $$SchedulesTableUpdateCompanionBuilder = SchedulesCompanion Function({
  Value<String> id,
  Value<String> projectId,
  Value<DateTime> date,
  Value<int> plannedWords,
  Value<bool> isRestDay,
  Value<bool> completed,
  Value<bool> automaticRestDay,
  Value<bool> locked,
  Value<int> rowid,
});

final class $$SchedulesTableReferences
    extends BaseReferences<_$AppDatabase, $SchedulesTable, Schedule> {
  $$SchedulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias(
          $_aliasNameGenerator(db.schedules.projectId, db.projects.id));

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager($_db, $_db.projects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$DailyLogsTable, List<DailyLog>>
      _dailyLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.dailyLogs,
          aliasName:
              $_aliasNameGenerator(db.schedules.id, db.dailyLogs.scheduleId));

  $$DailyLogsTableProcessedTableManager get dailyLogsRefs {
    final manager = $$DailyLogsTableTableManager($_db, $_db.dailyLogs)
        .filter((f) => f.scheduleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_dailyLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get plannedWords => $composableBuilder(
      column: $table.plannedWords, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRestDay => $composableBuilder(
      column: $table.isRestDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get automaticRestDay => $composableBuilder(
      column: $table.automaticRestDay,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get locked => $composableBuilder(
      column: $table.locked, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableFilterComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> dailyLogsRefs(
      Expression<bool> Function($$DailyLogsTableFilterComposer f) f) {
    final $$DailyLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.dailyLogs,
        getReferencedColumn: (t) => t.scheduleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DailyLogsTableFilterComposer(
              $db: $db,
              $table: $db.dailyLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get plannedWords => $composableBuilder(
      column: $table.plannedWords,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRestDay => $composableBuilder(
      column: $table.isRestDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get automaticRestDay => $composableBuilder(
      column: $table.automaticRestDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get locked => $composableBuilder(
      column: $table.locked, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get plannedWords => $composableBuilder(
      column: $table.plannedWords, builder: (column) => column);

  GeneratedColumn<bool> get isRestDay =>
      $composableBuilder(column: $table.isRestDay, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<bool> get automaticRestDay => $composableBuilder(
      column: $table.automaticRestDay, builder: (column) => column);

  GeneratedColumn<bool> get locked =>
      $composableBuilder(column: $table.locked, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> dailyLogsRefs<T extends Object>(
      Expression<T> Function($$DailyLogsTableAnnotationComposer a) f) {
    final $$DailyLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.dailyLogs,
        getReferencedColumn: (t) => t.scheduleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DailyLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.dailyLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SchedulesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SchedulesTable,
    Schedule,
    $$SchedulesTableFilterComposer,
    $$SchedulesTableOrderingComposer,
    $$SchedulesTableAnnotationComposer,
    $$SchedulesTableCreateCompanionBuilder,
    $$SchedulesTableUpdateCompanionBuilder,
    (Schedule, $$SchedulesTableReferences),
    Schedule,
    PrefetchHooks Function({bool projectId, bool dailyLogsRefs})> {
  $$SchedulesTableTableManager(_$AppDatabase db, $SchedulesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> projectId = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int> plannedWords = const Value.absent(),
            Value<bool> isRestDay = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<bool> automaticRestDay = const Value.absent(),
            Value<bool> locked = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SchedulesCompanion(
            id: id,
            projectId: projectId,
            date: date,
            plannedWords: plannedWords,
            isRestDay: isRestDay,
            completed: completed,
            automaticRestDay: automaticRestDay,
            locked: locked,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String projectId,
            required DateTime date,
            required int plannedWords,
            Value<bool> isRestDay = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<bool> automaticRestDay = const Value.absent(),
            Value<bool> locked = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SchedulesCompanion.insert(
            id: id,
            projectId: projectId,
            date: date,
            plannedWords: plannedWords,
            isRestDay: isRestDay,
            completed: completed,
            automaticRestDay: automaticRestDay,
            locked: locked,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SchedulesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({projectId = false, dailyLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (dailyLogsRefs) db.dailyLogs],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable:
                        $$SchedulesTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$SchedulesTableReferences._projectIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (dailyLogsRefs)
                    await $_getPrefetchedData<Schedule, $SchedulesTable,
                            DailyLog>(
                        currentTable: table,
                        referencedTable:
                            $$SchedulesTableReferences._dailyLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SchedulesTableReferences(db, table, p0)
                                .dailyLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.scheduleId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SchedulesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SchedulesTable,
    Schedule,
    $$SchedulesTableFilterComposer,
    $$SchedulesTableOrderingComposer,
    $$SchedulesTableAnnotationComposer,
    $$SchedulesTableCreateCompanionBuilder,
    $$SchedulesTableUpdateCompanionBuilder,
    (Schedule, $$SchedulesTableReferences),
    Schedule,
    PrefetchHooks Function({bool projectId, bool dailyLogsRefs})>;
typedef $$DailyLogsTableCreateCompanionBuilder = DailyLogsCompanion Function({
  required String id,
  required String projectId,
  Value<String?> scheduleId,
  required DateTime date,
  required int plannedWords,
  required int actualWords,
  Value<int> carryForwardWords,
  Value<int> backlogCreated,
  Value<bool> completed,
  required DateTime loggedAt,
  Value<int> rowid,
});
typedef $$DailyLogsTableUpdateCompanionBuilder = DailyLogsCompanion Function({
  Value<String> id,
  Value<String> projectId,
  Value<String?> scheduleId,
  Value<DateTime> date,
  Value<int> plannedWords,
  Value<int> actualWords,
  Value<int> carryForwardWords,
  Value<int> backlogCreated,
  Value<bool> completed,
  Value<DateTime> loggedAt,
  Value<int> rowid,
});

final class $$DailyLogsTableReferences
    extends BaseReferences<_$AppDatabase, $DailyLogsTable, DailyLog> {
  $$DailyLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias(
          $_aliasNameGenerator(db.dailyLogs.projectId, db.projects.id));

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager($_db, $_db.projects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SchedulesTable _scheduleIdTable(_$AppDatabase db) =>
      db.schedules.createAlias(
          $_aliasNameGenerator(db.dailyLogs.scheduleId, db.schedules.id));

  $$SchedulesTableProcessedTableManager? get scheduleId {
    final $_column = $_itemColumn<String>('schedule_id');
    if ($_column == null) return null;
    final manager = $$SchedulesTableTableManager($_db, $_db.schedules)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scheduleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DailyLogsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyLogsTable> {
  $$DailyLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get plannedWords => $composableBuilder(
      column: $table.plannedWords, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get actualWords => $composableBuilder(
      column: $table.actualWords, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get carryForwardWords => $composableBuilder(
      column: $table.carryForwardWords,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get backlogCreated => $composableBuilder(
      column: $table.backlogCreated,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
      column: $table.loggedAt, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableFilterComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SchedulesTableFilterComposer get scheduleId {
    final $$SchedulesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.scheduleId,
        referencedTable: $db.schedules,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SchedulesTableFilterComposer(
              $db: $db,
              $table: $db.schedules,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DailyLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyLogsTable> {
  $$DailyLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get plannedWords => $composableBuilder(
      column: $table.plannedWords,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get actualWords => $composableBuilder(
      column: $table.actualWords, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get carryForwardWords => $composableBuilder(
      column: $table.carryForwardWords,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get backlogCreated => $composableBuilder(
      column: $table.backlogCreated,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
      column: $table.loggedAt, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SchedulesTableOrderingComposer get scheduleId {
    final $$SchedulesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.scheduleId,
        referencedTable: $db.schedules,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SchedulesTableOrderingComposer(
              $db: $db,
              $table: $db.schedules,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DailyLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyLogsTable> {
  $$DailyLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get plannedWords => $composableBuilder(
      column: $table.plannedWords, builder: (column) => column);

  GeneratedColumn<int> get actualWords => $composableBuilder(
      column: $table.actualWords, builder: (column) => column);

  GeneratedColumn<int> get carryForwardWords => $composableBuilder(
      column: $table.carryForwardWords, builder: (column) => column);

  GeneratedColumn<int> get backlogCreated => $composableBuilder(
      column: $table.backlogCreated, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SchedulesTableAnnotationComposer get scheduleId {
    final $$SchedulesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.scheduleId,
        referencedTable: $db.schedules,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SchedulesTableAnnotationComposer(
              $db: $db,
              $table: $db.schedules,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DailyLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyLogsTable,
    DailyLog,
    $$DailyLogsTableFilterComposer,
    $$DailyLogsTableOrderingComposer,
    $$DailyLogsTableAnnotationComposer,
    $$DailyLogsTableCreateCompanionBuilder,
    $$DailyLogsTableUpdateCompanionBuilder,
    (DailyLog, $$DailyLogsTableReferences),
    DailyLog,
    PrefetchHooks Function({bool projectId, bool scheduleId})> {
  $$DailyLogsTableTableManager(_$AppDatabase db, $DailyLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> projectId = const Value.absent(),
            Value<String?> scheduleId = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int> plannedWords = const Value.absent(),
            Value<int> actualWords = const Value.absent(),
            Value<int> carryForwardWords = const Value.absent(),
            Value<int> backlogCreated = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<DateTime> loggedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyLogsCompanion(
            id: id,
            projectId: projectId,
            scheduleId: scheduleId,
            date: date,
            plannedWords: plannedWords,
            actualWords: actualWords,
            carryForwardWords: carryForwardWords,
            backlogCreated: backlogCreated,
            completed: completed,
            loggedAt: loggedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String projectId,
            Value<String?> scheduleId = const Value.absent(),
            required DateTime date,
            required int plannedWords,
            required int actualWords,
            Value<int> carryForwardWords = const Value.absent(),
            Value<int> backlogCreated = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            required DateTime loggedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyLogsCompanion.insert(
            id: id,
            projectId: projectId,
            scheduleId: scheduleId,
            date: date,
            plannedWords: plannedWords,
            actualWords: actualWords,
            carryForwardWords: carryForwardWords,
            backlogCreated: backlogCreated,
            completed: completed,
            loggedAt: loggedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DailyLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({projectId = false, scheduleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable:
                        $$DailyLogsTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$DailyLogsTableReferences._projectIdTable(db).id,
                  ) as T;
                }
                if (scheduleId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.scheduleId,
                    referencedTable:
                        $$DailyLogsTableReferences._scheduleIdTable(db),
                    referencedColumn:
                        $$DailyLogsTableReferences._scheduleIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DailyLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyLogsTable,
    DailyLog,
    $$DailyLogsTableFilterComposer,
    $$DailyLogsTableOrderingComposer,
    $$DailyLogsTableAnnotationComposer,
    $$DailyLogsTableCreateCompanionBuilder,
    $$DailyLogsTableUpdateCompanionBuilder,
    (DailyLog, $$DailyLogsTableReferences),
    DailyLog,
    PrefetchHooks Function({bool projectId, bool scheduleId})>;
typedef $$StatisticsTableTableCreateCompanionBuilder = StatisticsTableCompanion
    Function({
  required String id,
  Value<int> lifetimeWords,
  Value<double> averageWordsPerDay,
  Value<int> currentGlobalStreak,
  Value<int> longestGlobalStreak,
  Value<int> projectsCompleted,
  Value<int> writingDays,
  Value<int> restDaysUsed,
  Value<int> currentBacklog,
  Value<int> rowid,
});
typedef $$StatisticsTableTableUpdateCompanionBuilder = StatisticsTableCompanion
    Function({
  Value<String> id,
  Value<int> lifetimeWords,
  Value<double> averageWordsPerDay,
  Value<int> currentGlobalStreak,
  Value<int> longestGlobalStreak,
  Value<int> projectsCompleted,
  Value<int> writingDays,
  Value<int> restDaysUsed,
  Value<int> currentBacklog,
  Value<int> rowid,
});

class $$StatisticsTableTableFilterComposer
    extends Composer<_$AppDatabase, $StatisticsTableTable> {
  $$StatisticsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lifetimeWords => $composableBuilder(
      column: $table.lifetimeWords, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get averageWordsPerDay => $composableBuilder(
      column: $table.averageWordsPerDay,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentGlobalStreak => $composableBuilder(
      column: $table.currentGlobalStreak,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get longestGlobalStreak => $composableBuilder(
      column: $table.longestGlobalStreak,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get projectsCompleted => $composableBuilder(
      column: $table.projectsCompleted,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get writingDays => $composableBuilder(
      column: $table.writingDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get restDaysUsed => $composableBuilder(
      column: $table.restDaysUsed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentBacklog => $composableBuilder(
      column: $table.currentBacklog,
      builder: (column) => ColumnFilters(column));
}

class $$StatisticsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StatisticsTableTable> {
  $$StatisticsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lifetimeWords => $composableBuilder(
      column: $table.lifetimeWords,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get averageWordsPerDay => $composableBuilder(
      column: $table.averageWordsPerDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentGlobalStreak => $composableBuilder(
      column: $table.currentGlobalStreak,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get longestGlobalStreak => $composableBuilder(
      column: $table.longestGlobalStreak,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get projectsCompleted => $composableBuilder(
      column: $table.projectsCompleted,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get writingDays => $composableBuilder(
      column: $table.writingDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get restDaysUsed => $composableBuilder(
      column: $table.restDaysUsed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentBacklog => $composableBuilder(
      column: $table.currentBacklog,
      builder: (column) => ColumnOrderings(column));
}

class $$StatisticsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StatisticsTableTable> {
  $$StatisticsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lifetimeWords => $composableBuilder(
      column: $table.lifetimeWords, builder: (column) => column);

  GeneratedColumn<double> get averageWordsPerDay => $composableBuilder(
      column: $table.averageWordsPerDay, builder: (column) => column);

  GeneratedColumn<int> get currentGlobalStreak => $composableBuilder(
      column: $table.currentGlobalStreak, builder: (column) => column);

  GeneratedColumn<int> get longestGlobalStreak => $composableBuilder(
      column: $table.longestGlobalStreak, builder: (column) => column);

  GeneratedColumn<int> get projectsCompleted => $composableBuilder(
      column: $table.projectsCompleted, builder: (column) => column);

  GeneratedColumn<int> get writingDays => $composableBuilder(
      column: $table.writingDays, builder: (column) => column);

  GeneratedColumn<int> get restDaysUsed => $composableBuilder(
      column: $table.restDaysUsed, builder: (column) => column);

  GeneratedColumn<int> get currentBacklog => $composableBuilder(
      column: $table.currentBacklog, builder: (column) => column);
}

class $$StatisticsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StatisticsTableTable,
    StatisticsTableData,
    $$StatisticsTableTableFilterComposer,
    $$StatisticsTableTableOrderingComposer,
    $$StatisticsTableTableAnnotationComposer,
    $$StatisticsTableTableCreateCompanionBuilder,
    $$StatisticsTableTableUpdateCompanionBuilder,
    (
      StatisticsTableData,
      BaseReferences<_$AppDatabase, $StatisticsTableTable, StatisticsTableData>
    ),
    StatisticsTableData,
    PrefetchHooks Function()> {
  $$StatisticsTableTableTableManager(
      _$AppDatabase db, $StatisticsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StatisticsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StatisticsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StatisticsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> lifetimeWords = const Value.absent(),
            Value<double> averageWordsPerDay = const Value.absent(),
            Value<int> currentGlobalStreak = const Value.absent(),
            Value<int> longestGlobalStreak = const Value.absent(),
            Value<int> projectsCompleted = const Value.absent(),
            Value<int> writingDays = const Value.absent(),
            Value<int> restDaysUsed = const Value.absent(),
            Value<int> currentBacklog = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StatisticsTableCompanion(
            id: id,
            lifetimeWords: lifetimeWords,
            averageWordsPerDay: averageWordsPerDay,
            currentGlobalStreak: currentGlobalStreak,
            longestGlobalStreak: longestGlobalStreak,
            projectsCompleted: projectsCompleted,
            writingDays: writingDays,
            restDaysUsed: restDaysUsed,
            currentBacklog: currentBacklog,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<int> lifetimeWords = const Value.absent(),
            Value<double> averageWordsPerDay = const Value.absent(),
            Value<int> currentGlobalStreak = const Value.absent(),
            Value<int> longestGlobalStreak = const Value.absent(),
            Value<int> projectsCompleted = const Value.absent(),
            Value<int> writingDays = const Value.absent(),
            Value<int> restDaysUsed = const Value.absent(),
            Value<int> currentBacklog = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StatisticsTableCompanion.insert(
            id: id,
            lifetimeWords: lifetimeWords,
            averageWordsPerDay: averageWordsPerDay,
            currentGlobalStreak: currentGlobalStreak,
            longestGlobalStreak: longestGlobalStreak,
            projectsCompleted: projectsCompleted,
            writingDays: writingDays,
            restDaysUsed: restDaysUsed,
            currentBacklog: currentBacklog,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StatisticsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StatisticsTableTable,
    StatisticsTableData,
    $$StatisticsTableTableFilterComposer,
    $$StatisticsTableTableOrderingComposer,
    $$StatisticsTableTableAnnotationComposer,
    $$StatisticsTableTableCreateCompanionBuilder,
    $$StatisticsTableTableUpdateCompanionBuilder,
    (
      StatisticsTableData,
      BaseReferences<_$AppDatabase, $StatisticsTableTable, StatisticsTableData>
    ),
    StatisticsTableData,
    PrefetchHooks Function()>;
typedef $$AchievementsTableCreateCompanionBuilder = AchievementsCompanion
    Function({
  required String id,
  required String title,
  required String description,
  required DateTime earnedDate,
  Value<int> rowid,
});
typedef $$AchievementsTableUpdateCompanionBuilder = AchievementsCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<String> description,
  Value<DateTime> earnedDate,
  Value<int> rowid,
});

class $$AchievementsTableFilterComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get earnedDate => $composableBuilder(
      column: $table.earnedDate, builder: (column) => ColumnFilters(column));
}

class $$AchievementsTableOrderingComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get earnedDate => $composableBuilder(
      column: $table.earnedDate, builder: (column) => ColumnOrderings(column));
}

class $$AchievementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get earnedDate => $composableBuilder(
      column: $table.earnedDate, builder: (column) => column);
}

class $$AchievementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AchievementsTable,
    Achievement,
    $$AchievementsTableFilterComposer,
    $$AchievementsTableOrderingComposer,
    $$AchievementsTableAnnotationComposer,
    $$AchievementsTableCreateCompanionBuilder,
    $$AchievementsTableUpdateCompanionBuilder,
    (
      Achievement,
      BaseReferences<_$AppDatabase, $AchievementsTable, Achievement>
    ),
    Achievement,
    PrefetchHooks Function()> {
  $$AchievementsTableTableManager(_$AppDatabase db, $AchievementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AchievementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<DateTime> earnedDate = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AchievementsCompanion(
            id: id,
            title: title,
            description: description,
            earnedDate: earnedDate,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String description,
            required DateTime earnedDate,
            Value<int> rowid = const Value.absent(),
          }) =>
              AchievementsCompanion.insert(
            id: id,
            title: title,
            description: description,
            earnedDate: earnedDate,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AchievementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AchievementsTable,
    Achievement,
    $$AchievementsTableFilterComposer,
    $$AchievementsTableOrderingComposer,
    $$AchievementsTableAnnotationComposer,
    $$AchievementsTableCreateCompanionBuilder,
    $$AchievementsTableUpdateCompanionBuilder,
    (
      Achievement,
      BaseReferences<_$AppDatabase, $AchievementsTable, Achievement>
    ),
    Achievement,
    PrefetchHooks Function()>;
typedef $$QuotesTableCreateCompanionBuilder = QuotesCompanion Function({
  required String id,
  required String textContent,
  required String author,
  required String category,
  required String mood,
  Value<int> rowid,
});
typedef $$QuotesTableUpdateCompanionBuilder = QuotesCompanion Function({
  Value<String> id,
  Value<String> textContent,
  Value<String> author,
  Value<String> category,
  Value<String> mood,
  Value<int> rowid,
});

class $$QuotesTableFilterComposer
    extends Composer<_$AppDatabase, $QuotesTable> {
  $$QuotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get textContent => $composableBuilder(
      column: $table.textContent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnFilters(column));
}

class $$QuotesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuotesTable> {
  $$QuotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textContent => $composableBuilder(
      column: $table.textContent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnOrderings(column));
}

class $$QuotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuotesTable> {
  $$QuotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get textContent => $composableBuilder(
      column: $table.textContent, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);
}

class $$QuotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuotesTable,
    Quote,
    $$QuotesTableFilterComposer,
    $$QuotesTableOrderingComposer,
    $$QuotesTableAnnotationComposer,
    $$QuotesTableCreateCompanionBuilder,
    $$QuotesTableUpdateCompanionBuilder,
    (Quote, BaseReferences<_$AppDatabase, $QuotesTable, Quote>),
    Quote,
    PrefetchHooks Function()> {
  $$QuotesTableTableManager(_$AppDatabase db, $QuotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> textContent = const Value.absent(),
            Value<String> author = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> mood = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QuotesCompanion(
            id: id,
            textContent: textContent,
            author: author,
            category: category,
            mood: mood,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String textContent,
            required String author,
            required String category,
            required String mood,
            Value<int> rowid = const Value.absent(),
          }) =>
              QuotesCompanion.insert(
            id: id,
            textContent: textContent,
            author: author,
            category: category,
            mood: mood,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QuotesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuotesTable,
    Quote,
    $$QuotesTableFilterComposer,
    $$QuotesTableOrderingComposer,
    $$QuotesTableAnnotationComposer,
    $$QuotesTableCreateCompanionBuilder,
    $$QuotesTableUpdateCompanionBuilder,
    (Quote, BaseReferences<_$AppDatabase, $QuotesTable, Quote>),
    Quote,
    PrefetchHooks Function()>;
typedef $$SettingsTableTableCreateCompanionBuilder = SettingsTableCompanion
    Function({
  required String id,
  Value<String> theme,
  Value<bool> notifications,
  Value<bool> dailyQuotes,
  Value<bool> backupReminder,
  Value<bool> vibration,
  Value<int> rowid,
});
typedef $$SettingsTableTableUpdateCompanionBuilder = SettingsTableCompanion
    Function({
  Value<String> id,
  Value<String> theme,
  Value<bool> notifications,
  Value<bool> dailyQuotes,
  Value<bool> backupReminder,
  Value<bool> vibration,
  Value<int> rowid,
});

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get theme => $composableBuilder(
      column: $table.theme, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get notifications => $composableBuilder(
      column: $table.notifications, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dailyQuotes => $composableBuilder(
      column: $table.dailyQuotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get backupReminder => $composableBuilder(
      column: $table.backupReminder,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get vibration => $composableBuilder(
      column: $table.vibration, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get theme => $composableBuilder(
      column: $table.theme, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get notifications => $composableBuilder(
      column: $table.notifications,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dailyQuotes => $composableBuilder(
      column: $table.dailyQuotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get backupReminder => $composableBuilder(
      column: $table.backupReminder,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get vibration => $composableBuilder(
      column: $table.vibration, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<bool> get notifications => $composableBuilder(
      column: $table.notifications, builder: (column) => column);

  GeneratedColumn<bool> get dailyQuotes => $composableBuilder(
      column: $table.dailyQuotes, builder: (column) => column);

  GeneratedColumn<bool> get backupReminder => $composableBuilder(
      column: $table.backupReminder, builder: (column) => column);

  GeneratedColumn<bool> get vibration =>
      $composableBuilder(column: $table.vibration, builder: (column) => column);
}

class $$SettingsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTableTable,
    SettingsTableData,
    $$SettingsTableTableFilterComposer,
    $$SettingsTableTableOrderingComposer,
    $$SettingsTableTableAnnotationComposer,
    $$SettingsTableTableCreateCompanionBuilder,
    $$SettingsTableTableUpdateCompanionBuilder,
    (
      SettingsTableData,
      BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsTableData>
    ),
    SettingsTableData,
    PrefetchHooks Function()> {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> theme = const Value.absent(),
            Value<bool> notifications = const Value.absent(),
            Value<bool> dailyQuotes = const Value.absent(),
            Value<bool> backupReminder = const Value.absent(),
            Value<bool> vibration = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsTableCompanion(
            id: id,
            theme: theme,
            notifications: notifications,
            dailyQuotes: dailyQuotes,
            backupReminder: backupReminder,
            vibration: vibration,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String> theme = const Value.absent(),
            Value<bool> notifications = const Value.absent(),
            Value<bool> dailyQuotes = const Value.absent(),
            Value<bool> backupReminder = const Value.absent(),
            Value<bool> vibration = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsTableCompanion.insert(
            id: id,
            theme: theme,
            notifications: notifications,
            dailyQuotes: dailyQuotes,
            backupReminder: backupReminder,
            vibration: vibration,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTableTable,
    SettingsTableData,
    $$SettingsTableTableFilterComposer,
    $$SettingsTableTableOrderingComposer,
    $$SettingsTableTableAnnotationComposer,
    $$SettingsTableTableCreateCompanionBuilder,
    $$SettingsTableTableUpdateCompanionBuilder,
    (
      SettingsTableData,
      BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsTableData>
    ),
    SettingsTableData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$SchedulesTableTableManager get schedules =>
      $$SchedulesTableTableManager(_db, _db.schedules);
  $$DailyLogsTableTableManager get dailyLogs =>
      $$DailyLogsTableTableManager(_db, _db.dailyLogs);
  $$StatisticsTableTableTableManager get statisticsTable =>
      $$StatisticsTableTableTableManager(_db, _db.statisticsTable);
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db, _db.achievements);
  $$QuotesTableTableManager get quotes =>
      $$QuotesTableTableManager(_db, _db.quotes);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
}
