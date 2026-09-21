// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UniversesTable extends Universes
    with TableInfo<$UniversesTable, Universe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UniversesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loglineMeta = const VerificationMeta(
    'logline',
  );
  @override
  late final GeneratedColumn<String> logline = GeneratedColumn<String>(
    'logline',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _synopsisMeta = const VerificationMeta(
    'synopsis',
  );
  @override
  late final GeneratedColumn<String> synopsis = GeneratedColumn<String>(
    'synopsis',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverColorMeta = const VerificationMeta(
    'coverColor',
  );
  @override
  late final GeneratedColumn<String> coverColor = GeneratedColumn<String>(
    'cover_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('amber'),
  );
  static const VerificationMeta _linkedProjectInkIdMeta =
      const VerificationMeta('linkedProjectInkId');
  @override
  late final GeneratedColumn<String> linkedProjectInkId =
      GeneratedColumn<String>(
        'linked_project_ink_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _linkedProjectInkNameMeta =
      const VerificationMeta('linkedProjectInkName');
  @override
  late final GeneratedColumn<String> linkedProjectInkName =
      GeneratedColumn<String>(
        'linked_project_ink_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    genre,
    logline,
    synopsis,
    coverColor,
    linkedProjectInkId,
    linkedProjectInkName,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'universes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Universe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    } else if (isInserting) {
      context.missing(_genreMeta);
    }
    if (data.containsKey('logline')) {
      context.handle(
        _loglineMeta,
        logline.isAcceptableOrUnknown(data['logline']!, _loglineMeta),
      );
    }
    if (data.containsKey('synopsis')) {
      context.handle(
        _synopsisMeta,
        synopsis.isAcceptableOrUnknown(data['synopsis']!, _synopsisMeta),
      );
    }
    if (data.containsKey('cover_color')) {
      context.handle(
        _coverColorMeta,
        coverColor.isAcceptableOrUnknown(data['cover_color']!, _coverColorMeta),
      );
    }
    if (data.containsKey('linked_project_ink_id')) {
      context.handle(
        _linkedProjectInkIdMeta,
        linkedProjectInkId.isAcceptableOrUnknown(
          data['linked_project_ink_id']!,
          _linkedProjectInkIdMeta,
        ),
      );
    }
    if (data.containsKey('linked_project_ink_name')) {
      context.handle(
        _linkedProjectInkNameMeta,
        linkedProjectInkName.isAcceptableOrUnknown(
          data['linked_project_ink_name']!,
          _linkedProjectInkNameMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Universe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Universe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      )!,
      logline: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logline'],
      ),
      synopsis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}synopsis'],
      ),
      coverColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_color'],
      )!,
      linkedProjectInkId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_project_ink_id'],
      ),
      linkedProjectInkName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_project_ink_name'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UniversesTable createAlias(String alias) {
    return $UniversesTable(attachedDatabase, alias);
  }
}

class Universe extends DataClass implements Insertable<Universe> {
  final String id;
  final String title;
  final String genre;
  final String? logline;
  final String? synopsis;
  final String coverColor;
  final String? linkedProjectInkId;
  final String? linkedProjectInkName;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Universe({
    required this.id,
    required this.title,
    required this.genre,
    this.logline,
    this.synopsis,
    required this.coverColor,
    this.linkedProjectInkId,
    this.linkedProjectInkName,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['genre'] = Variable<String>(genre);
    if (!nullToAbsent || logline != null) {
      map['logline'] = Variable<String>(logline);
    }
    if (!nullToAbsent || synopsis != null) {
      map['synopsis'] = Variable<String>(synopsis);
    }
    map['cover_color'] = Variable<String>(coverColor);
    if (!nullToAbsent || linkedProjectInkId != null) {
      map['linked_project_ink_id'] = Variable<String>(linkedProjectInkId);
    }
    if (!nullToAbsent || linkedProjectInkName != null) {
      map['linked_project_ink_name'] = Variable<String>(linkedProjectInkName);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UniversesCompanion toCompanion(bool nullToAbsent) {
    return UniversesCompanion(
      id: Value(id),
      title: Value(title),
      genre: Value(genre),
      logline: logline == null && nullToAbsent
          ? const Value.absent()
          : Value(logline),
      synopsis: synopsis == null && nullToAbsent
          ? const Value.absent()
          : Value(synopsis),
      coverColor: Value(coverColor),
      linkedProjectInkId: linkedProjectInkId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedProjectInkId),
      linkedProjectInkName: linkedProjectInkName == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedProjectInkName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Universe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Universe(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      genre: serializer.fromJson<String>(json['genre']),
      logline: serializer.fromJson<String?>(json['logline']),
      synopsis: serializer.fromJson<String?>(json['synopsis']),
      coverColor: serializer.fromJson<String>(json['coverColor']),
      linkedProjectInkId: serializer.fromJson<String?>(
        json['linkedProjectInkId'],
      ),
      linkedProjectInkName: serializer.fromJson<String?>(
        json['linkedProjectInkName'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'genre': serializer.toJson<String>(genre),
      'logline': serializer.toJson<String?>(logline),
      'synopsis': serializer.toJson<String?>(synopsis),
      'coverColor': serializer.toJson<String>(coverColor),
      'linkedProjectInkId': serializer.toJson<String?>(linkedProjectInkId),
      'linkedProjectInkName': serializer.toJson<String?>(linkedProjectInkName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Universe copyWith({
    String? id,
    String? title,
    String? genre,
    Value<String?> logline = const Value.absent(),
    Value<String?> synopsis = const Value.absent(),
    String? coverColor,
    Value<String?> linkedProjectInkId = const Value.absent(),
    Value<String?> linkedProjectInkName = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Universe(
    id: id ?? this.id,
    title: title ?? this.title,
    genre: genre ?? this.genre,
    logline: logline.present ? logline.value : this.logline,
    synopsis: synopsis.present ? synopsis.value : this.synopsis,
    coverColor: coverColor ?? this.coverColor,
    linkedProjectInkId: linkedProjectInkId.present
        ? linkedProjectInkId.value
        : this.linkedProjectInkId,
    linkedProjectInkName: linkedProjectInkName.present
        ? linkedProjectInkName.value
        : this.linkedProjectInkName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Universe copyWithCompanion(UniversesCompanion data) {
    return Universe(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      genre: data.genre.present ? data.genre.value : this.genre,
      logline: data.logline.present ? data.logline.value : this.logline,
      synopsis: data.synopsis.present ? data.synopsis.value : this.synopsis,
      coverColor: data.coverColor.present
          ? data.coverColor.value
          : this.coverColor,
      linkedProjectInkId: data.linkedProjectInkId.present
          ? data.linkedProjectInkId.value
          : this.linkedProjectInkId,
      linkedProjectInkName: data.linkedProjectInkName.present
          ? data.linkedProjectInkName.value
          : this.linkedProjectInkName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Universe(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('genre: $genre, ')
          ..write('logline: $logline, ')
          ..write('synopsis: $synopsis, ')
          ..write('coverColor: $coverColor, ')
          ..write('linkedProjectInkId: $linkedProjectInkId, ')
          ..write('linkedProjectInkName: $linkedProjectInkName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    genre,
    logline,
    synopsis,
    coverColor,
    linkedProjectInkId,
    linkedProjectInkName,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Universe &&
          other.id == this.id &&
          other.title == this.title &&
          other.genre == this.genre &&
          other.logline == this.logline &&
          other.synopsis == this.synopsis &&
          other.coverColor == this.coverColor &&
          other.linkedProjectInkId == this.linkedProjectInkId &&
          other.linkedProjectInkName == this.linkedProjectInkName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UniversesCompanion extends UpdateCompanion<Universe> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> genre;
  final Value<String?> logline;
  final Value<String?> synopsis;
  final Value<String> coverColor;
  final Value<String?> linkedProjectInkId;
  final Value<String?> linkedProjectInkName;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UniversesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.genre = const Value.absent(),
    this.logline = const Value.absent(),
    this.synopsis = const Value.absent(),
    this.coverColor = const Value.absent(),
    this.linkedProjectInkId = const Value.absent(),
    this.linkedProjectInkName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UniversesCompanion.insert({
    required String id,
    required String title,
    required String genre,
    this.logline = const Value.absent(),
    this.synopsis = const Value.absent(),
    this.coverColor = const Value.absent(),
    this.linkedProjectInkId = const Value.absent(),
    this.linkedProjectInkName = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       genre = Value(genre),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Universe> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? genre,
    Expression<String>? logline,
    Expression<String>? synopsis,
    Expression<String>? coverColor,
    Expression<String>? linkedProjectInkId,
    Expression<String>? linkedProjectInkName,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (genre != null) 'genre': genre,
      if (logline != null) 'logline': logline,
      if (synopsis != null) 'synopsis': synopsis,
      if (coverColor != null) 'cover_color': coverColor,
      if (linkedProjectInkId != null)
        'linked_project_ink_id': linkedProjectInkId,
      if (linkedProjectInkName != null)
        'linked_project_ink_name': linkedProjectInkName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UniversesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? genre,
    Value<String?>? logline,
    Value<String?>? synopsis,
    Value<String>? coverColor,
    Value<String?>? linkedProjectInkId,
    Value<String?>? linkedProjectInkName,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UniversesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      logline: logline ?? this.logline,
      synopsis: synopsis ?? this.synopsis,
      coverColor: coverColor ?? this.coverColor,
      linkedProjectInkId: linkedProjectInkId ?? this.linkedProjectInkId,
      linkedProjectInkName: linkedProjectInkName ?? this.linkedProjectInkName,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (logline.present) {
      map['logline'] = Variable<String>(logline.value);
    }
    if (synopsis.present) {
      map['synopsis'] = Variable<String>(synopsis.value);
    }
    if (coverColor.present) {
      map['cover_color'] = Variable<String>(coverColor.value);
    }
    if (linkedProjectInkId.present) {
      map['linked_project_ink_id'] = Variable<String>(linkedProjectInkId.value);
    }
    if (linkedProjectInkName.present) {
      map['linked_project_ink_name'] = Variable<String>(
        linkedProjectInkName.value,
      );
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
    return (StringBuffer('UniversesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('genre: $genre, ')
          ..write('logline: $logline, ')
          ..write('synopsis: $synopsis, ')
          ..write('coverColor: $coverColor, ')
          ..write('linkedProjectInkId: $linkedProjectInkId, ')
          ..write('linkedProjectInkName: $linkedProjectInkName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharactersTable extends Characters
    with TableInfo<$CharactersTable, Character> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharactersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _universeIdMeta = const VerificationMeta(
    'universeId',
  );
  @override
  late final GeneratedColumn<String> universeId = GeneratedColumn<String>(
    'universe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES universes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  @override
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
    'alias',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archetypeMeta = const VerificationMeta(
    'archetype',
  );
  @override
  late final GeneratedColumn<String> archetype = GeneratedColumn<String>(
    'archetype',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<String> age = GeneratedColumn<String>(
    'age',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occupationMeta = const VerificationMeta(
    'occupation',
  );
  @override
  late final GeneratedColumn<String> occupation = GeneratedColumn<String>(
    'occupation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _motivationMeta = const VerificationMeta(
    'motivation',
  );
  @override
  late final GeneratedColumn<String> motivation = GeneratedColumn<String>(
    'motivation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _flawMeta = const VerificationMeta('flaw');
  @override
  late final GeneratedColumn<String> flaw = GeneratedColumn<String>(
    'flaw',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _internalConflictMeta = const VerificationMeta(
    'internalConflict',
  );
  @override
  late final GeneratedColumn<String> internalConflict = GeneratedColumn<String>(
    'internal_conflict',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backstoryMeta = const VerificationMeta(
    'backstory',
  );
  @override
  late final GeneratedColumn<String> backstory = GeneratedColumn<String>(
    'backstory',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _arcStageMeta = const VerificationMeta(
    'arcStage',
  );
  @override
  late final GeneratedColumn<String> arcStage = GeneratedColumn<String>(
    'arc_stage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Introduction'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarColorMeta = const VerificationMeta(
    'avatarColor',
  );
  @override
  late final GeneratedColumn<String> avatarColor = GeneratedColumn<String>(
    'avatar_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('teal'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    universeId,
    name,
    alias,
    role,
    archetype,
    age,
    occupation,
    motivation,
    flaw,
    internalConflict,
    backstory,
    arcStage,
    notes,
    avatarColor,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'characters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Character> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('universe_id')) {
      context.handle(
        _universeIdMeta,
        universeId.isAcceptableOrUnknown(data['universe_id']!, _universeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_universeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('alias')) {
      context.handle(
        _aliasMeta,
        alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('archetype')) {
      context.handle(
        _archetypeMeta,
        archetype.isAcceptableOrUnknown(data['archetype']!, _archetypeMeta),
      );
    }
    if (data.containsKey('age')) {
      context.handle(
        _ageMeta,
        age.isAcceptableOrUnknown(data['age']!, _ageMeta),
      );
    }
    if (data.containsKey('occupation')) {
      context.handle(
        _occupationMeta,
        occupation.isAcceptableOrUnknown(data['occupation']!, _occupationMeta),
      );
    }
    if (data.containsKey('motivation')) {
      context.handle(
        _motivationMeta,
        motivation.isAcceptableOrUnknown(data['motivation']!, _motivationMeta),
      );
    }
    if (data.containsKey('flaw')) {
      context.handle(
        _flawMeta,
        flaw.isAcceptableOrUnknown(data['flaw']!, _flawMeta),
      );
    }
    if (data.containsKey('internal_conflict')) {
      context.handle(
        _internalConflictMeta,
        internalConflict.isAcceptableOrUnknown(
          data['internal_conflict']!,
          _internalConflictMeta,
        ),
      );
    }
    if (data.containsKey('backstory')) {
      context.handle(
        _backstoryMeta,
        backstory.isAcceptableOrUnknown(data['backstory']!, _backstoryMeta),
      );
    }
    if (data.containsKey('arc_stage')) {
      context.handle(
        _arcStageMeta,
        arcStage.isAcceptableOrUnknown(data['arc_stage']!, _arcStageMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('avatar_color')) {
      context.handle(
        _avatarColorMeta,
        avatarColor.isAcceptableOrUnknown(
          data['avatar_color']!,
          _avatarColorMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Character map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Character(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      universeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}universe_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      alias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      archetype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archetype'],
      ),
      age: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}age'],
      ),
      occupation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occupation'],
      ),
      motivation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motivation'],
      ),
      flaw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flaw'],
      ),
      internalConflict: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}internal_conflict'],
      ),
      backstory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backstory'],
      ),
      arcStage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arc_stage'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      avatarColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_color'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CharactersTable createAlias(String alias) {
    return $CharactersTable(attachedDatabase, alias);
  }
}

class Character extends DataClass implements Insertable<Character> {
  final String id;
  final String universeId;
  final String name;
  final String? alias;
  final String role;
  final String? archetype;
  final String? age;
  final String? occupation;
  final String? motivation;
  final String? flaw;
  final String? internalConflict;
  final String? backstory;
  final String arcStage;
  final String? notes;
  final String avatarColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Character({
    required this.id,
    required this.universeId,
    required this.name,
    this.alias,
    required this.role,
    this.archetype,
    this.age,
    this.occupation,
    this.motivation,
    this.flaw,
    this.internalConflict,
    this.backstory,
    required this.arcStage,
    this.notes,
    required this.avatarColor,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['universe_id'] = Variable<String>(universeId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || alias != null) {
      map['alias'] = Variable<String>(alias);
    }
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || archetype != null) {
      map['archetype'] = Variable<String>(archetype);
    }
    if (!nullToAbsent || age != null) {
      map['age'] = Variable<String>(age);
    }
    if (!nullToAbsent || occupation != null) {
      map['occupation'] = Variable<String>(occupation);
    }
    if (!nullToAbsent || motivation != null) {
      map['motivation'] = Variable<String>(motivation);
    }
    if (!nullToAbsent || flaw != null) {
      map['flaw'] = Variable<String>(flaw);
    }
    if (!nullToAbsent || internalConflict != null) {
      map['internal_conflict'] = Variable<String>(internalConflict);
    }
    if (!nullToAbsent || backstory != null) {
      map['backstory'] = Variable<String>(backstory);
    }
    map['arc_stage'] = Variable<String>(arcStage);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['avatar_color'] = Variable<String>(avatarColor);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CharactersCompanion toCompanion(bool nullToAbsent) {
    return CharactersCompanion(
      id: Value(id),
      universeId: Value(universeId),
      name: Value(name),
      alias: alias == null && nullToAbsent
          ? const Value.absent()
          : Value(alias),
      role: Value(role),
      archetype: archetype == null && nullToAbsent
          ? const Value.absent()
          : Value(archetype),
      age: age == null && nullToAbsent ? const Value.absent() : Value(age),
      occupation: occupation == null && nullToAbsent
          ? const Value.absent()
          : Value(occupation),
      motivation: motivation == null && nullToAbsent
          ? const Value.absent()
          : Value(motivation),
      flaw: flaw == null && nullToAbsent ? const Value.absent() : Value(flaw),
      internalConflict: internalConflict == null && nullToAbsent
          ? const Value.absent()
          : Value(internalConflict),
      backstory: backstory == null && nullToAbsent
          ? const Value.absent()
          : Value(backstory),
      arcStage: Value(arcStage),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      avatarColor: Value(avatarColor),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Character.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Character(
      id: serializer.fromJson<String>(json['id']),
      universeId: serializer.fromJson<String>(json['universeId']),
      name: serializer.fromJson<String>(json['name']),
      alias: serializer.fromJson<String?>(json['alias']),
      role: serializer.fromJson<String>(json['role']),
      archetype: serializer.fromJson<String?>(json['archetype']),
      age: serializer.fromJson<String?>(json['age']),
      occupation: serializer.fromJson<String?>(json['occupation']),
      motivation: serializer.fromJson<String?>(json['motivation']),
      flaw: serializer.fromJson<String?>(json['flaw']),
      internalConflict: serializer.fromJson<String?>(json['internalConflict']),
      backstory: serializer.fromJson<String?>(json['backstory']),
      arcStage: serializer.fromJson<String>(json['arcStage']),
      notes: serializer.fromJson<String?>(json['notes']),
      avatarColor: serializer.fromJson<String>(json['avatarColor']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'universeId': serializer.toJson<String>(universeId),
      'name': serializer.toJson<String>(name),
      'alias': serializer.toJson<String?>(alias),
      'role': serializer.toJson<String>(role),
      'archetype': serializer.toJson<String?>(archetype),
      'age': serializer.toJson<String?>(age),
      'occupation': serializer.toJson<String?>(occupation),
      'motivation': serializer.toJson<String?>(motivation),
      'flaw': serializer.toJson<String?>(flaw),
      'internalConflict': serializer.toJson<String?>(internalConflict),
      'backstory': serializer.toJson<String?>(backstory),
      'arcStage': serializer.toJson<String>(arcStage),
      'notes': serializer.toJson<String?>(notes),
      'avatarColor': serializer.toJson<String>(avatarColor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Character copyWith({
    String? id,
    String? universeId,
    String? name,
    Value<String?> alias = const Value.absent(),
    String? role,
    Value<String?> archetype = const Value.absent(),
    Value<String?> age = const Value.absent(),
    Value<String?> occupation = const Value.absent(),
    Value<String?> motivation = const Value.absent(),
    Value<String?> flaw = const Value.absent(),
    Value<String?> internalConflict = const Value.absent(),
    Value<String?> backstory = const Value.absent(),
    String? arcStage,
    Value<String?> notes = const Value.absent(),
    String? avatarColor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Character(
    id: id ?? this.id,
    universeId: universeId ?? this.universeId,
    name: name ?? this.name,
    alias: alias.present ? alias.value : this.alias,
    role: role ?? this.role,
    archetype: archetype.present ? archetype.value : this.archetype,
    age: age.present ? age.value : this.age,
    occupation: occupation.present ? occupation.value : this.occupation,
    motivation: motivation.present ? motivation.value : this.motivation,
    flaw: flaw.present ? flaw.value : this.flaw,
    internalConflict: internalConflict.present
        ? internalConflict.value
        : this.internalConflict,
    backstory: backstory.present ? backstory.value : this.backstory,
    arcStage: arcStage ?? this.arcStage,
    notes: notes.present ? notes.value : this.notes,
    avatarColor: avatarColor ?? this.avatarColor,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Character copyWithCompanion(CharactersCompanion data) {
    return Character(
      id: data.id.present ? data.id.value : this.id,
      universeId: data.universeId.present
          ? data.universeId.value
          : this.universeId,
      name: data.name.present ? data.name.value : this.name,
      alias: data.alias.present ? data.alias.value : this.alias,
      role: data.role.present ? data.role.value : this.role,
      archetype: data.archetype.present ? data.archetype.value : this.archetype,
      age: data.age.present ? data.age.value : this.age,
      occupation: data.occupation.present
          ? data.occupation.value
          : this.occupation,
      motivation: data.motivation.present
          ? data.motivation.value
          : this.motivation,
      flaw: data.flaw.present ? data.flaw.value : this.flaw,
      internalConflict: data.internalConflict.present
          ? data.internalConflict.value
          : this.internalConflict,
      backstory: data.backstory.present ? data.backstory.value : this.backstory,
      arcStage: data.arcStage.present ? data.arcStage.value : this.arcStage,
      notes: data.notes.present ? data.notes.value : this.notes,
      avatarColor: data.avatarColor.present
          ? data.avatarColor.value
          : this.avatarColor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Character(')
          ..write('id: $id, ')
          ..write('universeId: $universeId, ')
          ..write('name: $name, ')
          ..write('alias: $alias, ')
          ..write('role: $role, ')
          ..write('archetype: $archetype, ')
          ..write('age: $age, ')
          ..write('occupation: $occupation, ')
          ..write('motivation: $motivation, ')
          ..write('flaw: $flaw, ')
          ..write('internalConflict: $internalConflict, ')
          ..write('backstory: $backstory, ')
          ..write('arcStage: $arcStage, ')
          ..write('notes: $notes, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    universeId,
    name,
    alias,
    role,
    archetype,
    age,
    occupation,
    motivation,
    flaw,
    internalConflict,
    backstory,
    arcStage,
    notes,
    avatarColor,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Character &&
          other.id == this.id &&
          other.universeId == this.universeId &&
          other.name == this.name &&
          other.alias == this.alias &&
          other.role == this.role &&
          other.archetype == this.archetype &&
          other.age == this.age &&
          other.occupation == this.occupation &&
          other.motivation == this.motivation &&
          other.flaw == this.flaw &&
          other.internalConflict == this.internalConflict &&
          other.backstory == this.backstory &&
          other.arcStage == this.arcStage &&
          other.notes == this.notes &&
          other.avatarColor == this.avatarColor &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CharactersCompanion extends UpdateCompanion<Character> {
  final Value<String> id;
  final Value<String> universeId;
  final Value<String> name;
  final Value<String?> alias;
  final Value<String> role;
  final Value<String?> archetype;
  final Value<String?> age;
  final Value<String?> occupation;
  final Value<String?> motivation;
  final Value<String?> flaw;
  final Value<String?> internalConflict;
  final Value<String?> backstory;
  final Value<String> arcStage;
  final Value<String?> notes;
  final Value<String> avatarColor;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CharactersCompanion({
    this.id = const Value.absent(),
    this.universeId = const Value.absent(),
    this.name = const Value.absent(),
    this.alias = const Value.absent(),
    this.role = const Value.absent(),
    this.archetype = const Value.absent(),
    this.age = const Value.absent(),
    this.occupation = const Value.absent(),
    this.motivation = const Value.absent(),
    this.flaw = const Value.absent(),
    this.internalConflict = const Value.absent(),
    this.backstory = const Value.absent(),
    this.arcStage = const Value.absent(),
    this.notes = const Value.absent(),
    this.avatarColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharactersCompanion.insert({
    required String id,
    required String universeId,
    required String name,
    this.alias = const Value.absent(),
    required String role,
    this.archetype = const Value.absent(),
    this.age = const Value.absent(),
    this.occupation = const Value.absent(),
    this.motivation = const Value.absent(),
    this.flaw = const Value.absent(),
    this.internalConflict = const Value.absent(),
    this.backstory = const Value.absent(),
    this.arcStage = const Value.absent(),
    this.notes = const Value.absent(),
    this.avatarColor = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       universeId = Value(universeId),
       name = Value(name),
       role = Value(role),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Character> custom({
    Expression<String>? id,
    Expression<String>? universeId,
    Expression<String>? name,
    Expression<String>? alias,
    Expression<String>? role,
    Expression<String>? archetype,
    Expression<String>? age,
    Expression<String>? occupation,
    Expression<String>? motivation,
    Expression<String>? flaw,
    Expression<String>? internalConflict,
    Expression<String>? backstory,
    Expression<String>? arcStage,
    Expression<String>? notes,
    Expression<String>? avatarColor,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (universeId != null) 'universe_id': universeId,
      if (name != null) 'name': name,
      if (alias != null) 'alias': alias,
      if (role != null) 'role': role,
      if (archetype != null) 'archetype': archetype,
      if (age != null) 'age': age,
      if (occupation != null) 'occupation': occupation,
      if (motivation != null) 'motivation': motivation,
      if (flaw != null) 'flaw': flaw,
      if (internalConflict != null) 'internal_conflict': internalConflict,
      if (backstory != null) 'backstory': backstory,
      if (arcStage != null) 'arc_stage': arcStage,
      if (notes != null) 'notes': notes,
      if (avatarColor != null) 'avatar_color': avatarColor,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharactersCompanion copyWith({
    Value<String>? id,
    Value<String>? universeId,
    Value<String>? name,
    Value<String?>? alias,
    Value<String>? role,
    Value<String?>? archetype,
    Value<String?>? age,
    Value<String?>? occupation,
    Value<String?>? motivation,
    Value<String?>? flaw,
    Value<String?>? internalConflict,
    Value<String?>? backstory,
    Value<String>? arcStage,
    Value<String?>? notes,
    Value<String>? avatarColor,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CharactersCompanion(
      id: id ?? this.id,
      universeId: universeId ?? this.universeId,
      name: name ?? this.name,
      alias: alias ?? this.alias,
      role: role ?? this.role,
      archetype: archetype ?? this.archetype,
      age: age ?? this.age,
      occupation: occupation ?? this.occupation,
      motivation: motivation ?? this.motivation,
      flaw: flaw ?? this.flaw,
      internalConflict: internalConflict ?? this.internalConflict,
      backstory: backstory ?? this.backstory,
      arcStage: arcStage ?? this.arcStage,
      notes: notes ?? this.notes,
      avatarColor: avatarColor ?? this.avatarColor,
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
    if (universeId.present) {
      map['universe_id'] = Variable<String>(universeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (archetype.present) {
      map['archetype'] = Variable<String>(archetype.value);
    }
    if (age.present) {
      map['age'] = Variable<String>(age.value);
    }
    if (occupation.present) {
      map['occupation'] = Variable<String>(occupation.value);
    }
    if (motivation.present) {
      map['motivation'] = Variable<String>(motivation.value);
    }
    if (flaw.present) {
      map['flaw'] = Variable<String>(flaw.value);
    }
    if (internalConflict.present) {
      map['internal_conflict'] = Variable<String>(internalConflict.value);
    }
    if (backstory.present) {
      map['backstory'] = Variable<String>(backstory.value);
    }
    if (arcStage.present) {
      map['arc_stage'] = Variable<String>(arcStage.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (avatarColor.present) {
      map['avatar_color'] = Variable<String>(avatarColor.value);
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
    return (StringBuffer('CharactersCompanion(')
          ..write('id: $id, ')
          ..write('universeId: $universeId, ')
          ..write('name: $name, ')
          ..write('alias: $alias, ')
          ..write('role: $role, ')
          ..write('archetype: $archetype, ')
          ..write('age: $age, ')
          ..write('occupation: $occupation, ')
          ..write('motivation: $motivation, ')
          ..write('flaw: $flaw, ')
          ..write('internalConflict: $internalConflict, ')
          ..write('backstory: $backstory, ')
          ..write('arcStage: $arcStage, ')
          ..write('notes: $notes, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharacterRelationshipsTable extends CharacterRelationships
    with TableInfo<$CharacterRelationshipsTable, CharacterRelationship> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterRelationshipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _universeIdMeta = const VerificationMeta(
    'universeId',
  );
  @override
  late final GeneratedColumn<String> universeId = GeneratedColumn<String>(
    'universe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES universes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sourceCharacterIdMeta = const VerificationMeta(
    'sourceCharacterId',
  );
  @override
  late final GeneratedColumn<String> sourceCharacterId =
      GeneratedColumn<String>(
        'source_character_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES characters (id) ON DELETE CASCADE',
        ),
      );
  static const VerificationMeta _targetCharacterIdMeta = const VerificationMeta(
    'targetCharacterId',
  );
  @override
  late final GeneratedColumn<String> targetCharacterId =
      GeneratedColumn<String>(
        'target_character_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES characters (id) ON DELETE CASCADE',
        ),
      );
  static const VerificationMeta _relationTypeMeta = const VerificationMeta(
    'relationType',
  );
  @override
  late final GeneratedColumn<String> relationType = GeneratedColumn<String>(
    'relation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    universeId,
    sourceCharacterId,
    targetCharacterId,
    relationType,
    description,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_relationships';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterRelationship> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('universe_id')) {
      context.handle(
        _universeIdMeta,
        universeId.isAcceptableOrUnknown(data['universe_id']!, _universeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_universeIdMeta);
    }
    if (data.containsKey('source_character_id')) {
      context.handle(
        _sourceCharacterIdMeta,
        sourceCharacterId.isAcceptableOrUnknown(
          data['source_character_id']!,
          _sourceCharacterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceCharacterIdMeta);
    }
    if (data.containsKey('target_character_id')) {
      context.handle(
        _targetCharacterIdMeta,
        targetCharacterId.isAcceptableOrUnknown(
          data['target_character_id']!,
          _targetCharacterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetCharacterIdMeta);
    }
    if (data.containsKey('relation_type')) {
      context.handle(
        _relationTypeMeta,
        relationType.isAcceptableOrUnknown(
          data['relation_type']!,
          _relationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relationTypeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterRelationship map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterRelationship(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      universeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}universe_id'],
      )!,
      sourceCharacterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_character_id'],
      )!,
      targetCharacterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_character_id'],
      )!,
      relationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relation_type'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CharacterRelationshipsTable createAlias(String alias) {
    return $CharacterRelationshipsTable(attachedDatabase, alias);
  }
}

class CharacterRelationship extends DataClass
    implements Insertable<CharacterRelationship> {
  final String id;
  final String universeId;
  final String sourceCharacterId;
  final String targetCharacterId;
  final String relationType;
  final String? description;
  final DateTime createdAt;
  const CharacterRelationship({
    required this.id,
    required this.universeId,
    required this.sourceCharacterId,
    required this.targetCharacterId,
    required this.relationType,
    this.description,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['universe_id'] = Variable<String>(universeId);
    map['source_character_id'] = Variable<String>(sourceCharacterId);
    map['target_character_id'] = Variable<String>(targetCharacterId);
    map['relation_type'] = Variable<String>(relationType);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CharacterRelationshipsCompanion toCompanion(bool nullToAbsent) {
    return CharacterRelationshipsCompanion(
      id: Value(id),
      universeId: Value(universeId),
      sourceCharacterId: Value(sourceCharacterId),
      targetCharacterId: Value(targetCharacterId),
      relationType: Value(relationType),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory CharacterRelationship.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterRelationship(
      id: serializer.fromJson<String>(json['id']),
      universeId: serializer.fromJson<String>(json['universeId']),
      sourceCharacterId: serializer.fromJson<String>(json['sourceCharacterId']),
      targetCharacterId: serializer.fromJson<String>(json['targetCharacterId']),
      relationType: serializer.fromJson<String>(json['relationType']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'universeId': serializer.toJson<String>(universeId),
      'sourceCharacterId': serializer.toJson<String>(sourceCharacterId),
      'targetCharacterId': serializer.toJson<String>(targetCharacterId),
      'relationType': serializer.toJson<String>(relationType),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CharacterRelationship copyWith({
    String? id,
    String? universeId,
    String? sourceCharacterId,
    String? targetCharacterId,
    String? relationType,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
  }) => CharacterRelationship(
    id: id ?? this.id,
    universeId: universeId ?? this.universeId,
    sourceCharacterId: sourceCharacterId ?? this.sourceCharacterId,
    targetCharacterId: targetCharacterId ?? this.targetCharacterId,
    relationType: relationType ?? this.relationType,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
  );
  CharacterRelationship copyWithCompanion(
    CharacterRelationshipsCompanion data,
  ) {
    return CharacterRelationship(
      id: data.id.present ? data.id.value : this.id,
      universeId: data.universeId.present
          ? data.universeId.value
          : this.universeId,
      sourceCharacterId: data.sourceCharacterId.present
          ? data.sourceCharacterId.value
          : this.sourceCharacterId,
      targetCharacterId: data.targetCharacterId.present
          ? data.targetCharacterId.value
          : this.targetCharacterId,
      relationType: data.relationType.present
          ? data.relationType.value
          : this.relationType,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterRelationship(')
          ..write('id: $id, ')
          ..write('universeId: $universeId, ')
          ..write('sourceCharacterId: $sourceCharacterId, ')
          ..write('targetCharacterId: $targetCharacterId, ')
          ..write('relationType: $relationType, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    universeId,
    sourceCharacterId,
    targetCharacterId,
    relationType,
    description,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterRelationship &&
          other.id == this.id &&
          other.universeId == this.universeId &&
          other.sourceCharacterId == this.sourceCharacterId &&
          other.targetCharacterId == this.targetCharacterId &&
          other.relationType == this.relationType &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class CharacterRelationshipsCompanion
    extends UpdateCompanion<CharacterRelationship> {
  final Value<String> id;
  final Value<String> universeId;
  final Value<String> sourceCharacterId;
  final Value<String> targetCharacterId;
  final Value<String> relationType;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CharacterRelationshipsCompanion({
    this.id = const Value.absent(),
    this.universeId = const Value.absent(),
    this.sourceCharacterId = const Value.absent(),
    this.targetCharacterId = const Value.absent(),
    this.relationType = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharacterRelationshipsCompanion.insert({
    required String id,
    required String universeId,
    required String sourceCharacterId,
    required String targetCharacterId,
    required String relationType,
    this.description = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       universeId = Value(universeId),
       sourceCharacterId = Value(sourceCharacterId),
       targetCharacterId = Value(targetCharacterId),
       relationType = Value(relationType),
       createdAt = Value(createdAt);
  static Insertable<CharacterRelationship> custom({
    Expression<String>? id,
    Expression<String>? universeId,
    Expression<String>? sourceCharacterId,
    Expression<String>? targetCharacterId,
    Expression<String>? relationType,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (universeId != null) 'universe_id': universeId,
      if (sourceCharacterId != null) 'source_character_id': sourceCharacterId,
      if (targetCharacterId != null) 'target_character_id': targetCharacterId,
      if (relationType != null) 'relation_type': relationType,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharacterRelationshipsCompanion copyWith({
    Value<String>? id,
    Value<String>? universeId,
    Value<String>? sourceCharacterId,
    Value<String>? targetCharacterId,
    Value<String>? relationType,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CharacterRelationshipsCompanion(
      id: id ?? this.id,
      universeId: universeId ?? this.universeId,
      sourceCharacterId: sourceCharacterId ?? this.sourceCharacterId,
      targetCharacterId: targetCharacterId ?? this.targetCharacterId,
      relationType: relationType ?? this.relationType,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (universeId.present) {
      map['universe_id'] = Variable<String>(universeId.value);
    }
    if (sourceCharacterId.present) {
      map['source_character_id'] = Variable<String>(sourceCharacterId.value);
    }
    if (targetCharacterId.present) {
      map['target_character_id'] = Variable<String>(targetCharacterId.value);
    }
    if (relationType.present) {
      map['relation_type'] = Variable<String>(relationType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterRelationshipsCompanion(')
          ..write('id: $id, ')
          ..write('universeId: $universeId, ')
          ..write('sourceCharacterId: $sourceCharacterId, ')
          ..write('targetCharacterId: $targetCharacterId, ')
          ..write('relationType: $relationType, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChaptersTable extends Chapters with TableInfo<$ChaptersTable, Chapter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _universeIdMeta = const VerificationMeta(
    'universeId',
  );
  @override
  late final GeneratedColumn<String> universeId = GeneratedColumn<String>(
    'universe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES universes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _chapterNumberMeta = const VerificationMeta(
    'chapterNumber',
  );
  @override
  late final GeneratedColumn<int> chapterNumber = GeneratedColumn<int>(
    'chapter_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actMeta = const VerificationMeta('act');
  @override
  late final GeneratedColumn<String> act = GeneratedColumn<String>(
    'act',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Act I'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _objectiveMeta = const VerificationMeta(
    'objective',
  );
  @override
  late final GeneratedColumn<String> objective = GeneratedColumn<String>(
    'objective',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimatedWordCountMeta =
      const VerificationMeta('estimatedWordCount');
  @override
  late final GeneratedColumn<int> estimatedWordCount = GeneratedColumn<int>(
    'estimated_word_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2500),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Outlined'),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    universeId,
    chapterNumber,
    act,
    title,
    objective,
    estimatedWordCount,
    status,
    orderIndex,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Chapter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('universe_id')) {
      context.handle(
        _universeIdMeta,
        universeId.isAcceptableOrUnknown(data['universe_id']!, _universeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_universeIdMeta);
    }
    if (data.containsKey('chapter_number')) {
      context.handle(
        _chapterNumberMeta,
        chapterNumber.isAcceptableOrUnknown(
          data['chapter_number']!,
          _chapterNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chapterNumberMeta);
    }
    if (data.containsKey('act')) {
      context.handle(
        _actMeta,
        act.isAcceptableOrUnknown(data['act']!, _actMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('objective')) {
      context.handle(
        _objectiveMeta,
        objective.isAcceptableOrUnknown(data['objective']!, _objectiveMeta),
      );
    }
    if (data.containsKey('estimated_word_count')) {
      context.handle(
        _estimatedWordCountMeta,
        estimatedWordCount.isAcceptableOrUnknown(
          data['estimated_word_count']!,
          _estimatedWordCountMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Chapter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chapter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      universeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}universe_id'],
      )!,
      chapterNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_number'],
      )!,
      act: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}act'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      objective: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}objective'],
      ),
      estimatedWordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_word_count'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ChaptersTable createAlias(String alias) {
    return $ChaptersTable(attachedDatabase, alias);
  }
}

class Chapter extends DataClass implements Insertable<Chapter> {
  final String id;
  final String universeId;
  final int chapterNumber;
  final String act;
  final String title;
  final String? objective;
  final int estimatedWordCount;
  final String status;
  final int orderIndex;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Chapter({
    required this.id,
    required this.universeId,
    required this.chapterNumber,
    required this.act,
    required this.title,
    this.objective,
    required this.estimatedWordCount,
    required this.status,
    required this.orderIndex,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['universe_id'] = Variable<String>(universeId);
    map['chapter_number'] = Variable<int>(chapterNumber);
    map['act'] = Variable<String>(act);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || objective != null) {
      map['objective'] = Variable<String>(objective);
    }
    map['estimated_word_count'] = Variable<int>(estimatedWordCount);
    map['status'] = Variable<String>(status);
    map['order_index'] = Variable<int>(orderIndex);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChaptersCompanion toCompanion(bool nullToAbsent) {
    return ChaptersCompanion(
      id: Value(id),
      universeId: Value(universeId),
      chapterNumber: Value(chapterNumber),
      act: Value(act),
      title: Value(title),
      objective: objective == null && nullToAbsent
          ? const Value.absent()
          : Value(objective),
      estimatedWordCount: Value(estimatedWordCount),
      status: Value(status),
      orderIndex: Value(orderIndex),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Chapter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chapter(
      id: serializer.fromJson<String>(json['id']),
      universeId: serializer.fromJson<String>(json['universeId']),
      chapterNumber: serializer.fromJson<int>(json['chapterNumber']),
      act: serializer.fromJson<String>(json['act']),
      title: serializer.fromJson<String>(json['title']),
      objective: serializer.fromJson<String?>(json['objective']),
      estimatedWordCount: serializer.fromJson<int>(json['estimatedWordCount']),
      status: serializer.fromJson<String>(json['status']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'universeId': serializer.toJson<String>(universeId),
      'chapterNumber': serializer.toJson<int>(chapterNumber),
      'act': serializer.toJson<String>(act),
      'title': serializer.toJson<String>(title),
      'objective': serializer.toJson<String?>(objective),
      'estimatedWordCount': serializer.toJson<int>(estimatedWordCount),
      'status': serializer.toJson<String>(status),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Chapter copyWith({
    String? id,
    String? universeId,
    int? chapterNumber,
    String? act,
    String? title,
    Value<String?> objective = const Value.absent(),
    int? estimatedWordCount,
    String? status,
    int? orderIndex,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Chapter(
    id: id ?? this.id,
    universeId: universeId ?? this.universeId,
    chapterNumber: chapterNumber ?? this.chapterNumber,
    act: act ?? this.act,
    title: title ?? this.title,
    objective: objective.present ? objective.value : this.objective,
    estimatedWordCount: estimatedWordCount ?? this.estimatedWordCount,
    status: status ?? this.status,
    orderIndex: orderIndex ?? this.orderIndex,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Chapter copyWithCompanion(ChaptersCompanion data) {
    return Chapter(
      id: data.id.present ? data.id.value : this.id,
      universeId: data.universeId.present
          ? data.universeId.value
          : this.universeId,
      chapterNumber: data.chapterNumber.present
          ? data.chapterNumber.value
          : this.chapterNumber,
      act: data.act.present ? data.act.value : this.act,
      title: data.title.present ? data.title.value : this.title,
      objective: data.objective.present ? data.objective.value : this.objective,
      estimatedWordCount: data.estimatedWordCount.present
          ? data.estimatedWordCount.value
          : this.estimatedWordCount,
      status: data.status.present ? data.status.value : this.status,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Chapter(')
          ..write('id: $id, ')
          ..write('universeId: $universeId, ')
          ..write('chapterNumber: $chapterNumber, ')
          ..write('act: $act, ')
          ..write('title: $title, ')
          ..write('objective: $objective, ')
          ..write('estimatedWordCount: $estimatedWordCount, ')
          ..write('status: $status, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    universeId,
    chapterNumber,
    act,
    title,
    objective,
    estimatedWordCount,
    status,
    orderIndex,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chapter &&
          other.id == this.id &&
          other.universeId == this.universeId &&
          other.chapterNumber == this.chapterNumber &&
          other.act == this.act &&
          other.title == this.title &&
          other.objective == this.objective &&
          other.estimatedWordCount == this.estimatedWordCount &&
          other.status == this.status &&
          other.orderIndex == this.orderIndex &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChaptersCompanion extends UpdateCompanion<Chapter> {
  final Value<String> id;
  final Value<String> universeId;
  final Value<int> chapterNumber;
  final Value<String> act;
  final Value<String> title;
  final Value<String?> objective;
  final Value<int> estimatedWordCount;
  final Value<String> status;
  final Value<int> orderIndex;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChaptersCompanion({
    this.id = const Value.absent(),
    this.universeId = const Value.absent(),
    this.chapterNumber = const Value.absent(),
    this.act = const Value.absent(),
    this.title = const Value.absent(),
    this.objective = const Value.absent(),
    this.estimatedWordCount = const Value.absent(),
    this.status = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChaptersCompanion.insert({
    required String id,
    required String universeId,
    required int chapterNumber,
    this.act = const Value.absent(),
    required String title,
    this.objective = const Value.absent(),
    this.estimatedWordCount = const Value.absent(),
    this.status = const Value.absent(),
    required int orderIndex,
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       universeId = Value(universeId),
       chapterNumber = Value(chapterNumber),
       title = Value(title),
       orderIndex = Value(orderIndex),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Chapter> custom({
    Expression<String>? id,
    Expression<String>? universeId,
    Expression<int>? chapterNumber,
    Expression<String>? act,
    Expression<String>? title,
    Expression<String>? objective,
    Expression<int>? estimatedWordCount,
    Expression<String>? status,
    Expression<int>? orderIndex,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (universeId != null) 'universe_id': universeId,
      if (chapterNumber != null) 'chapter_number': chapterNumber,
      if (act != null) 'act': act,
      if (title != null) 'title': title,
      if (objective != null) 'objective': objective,
      if (estimatedWordCount != null)
        'estimated_word_count': estimatedWordCount,
      if (status != null) 'status': status,
      if (orderIndex != null) 'order_index': orderIndex,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChaptersCompanion copyWith({
    Value<String>? id,
    Value<String>? universeId,
    Value<int>? chapterNumber,
    Value<String>? act,
    Value<String>? title,
    Value<String?>? objective,
    Value<int>? estimatedWordCount,
    Value<String>? status,
    Value<int>? orderIndex,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ChaptersCompanion(
      id: id ?? this.id,
      universeId: universeId ?? this.universeId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      act: act ?? this.act,
      title: title ?? this.title,
      objective: objective ?? this.objective,
      estimatedWordCount: estimatedWordCount ?? this.estimatedWordCount,
      status: status ?? this.status,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
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
    if (universeId.present) {
      map['universe_id'] = Variable<String>(universeId.value);
    }
    if (chapterNumber.present) {
      map['chapter_number'] = Variable<int>(chapterNumber.value);
    }
    if (act.present) {
      map['act'] = Variable<String>(act.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (objective.present) {
      map['objective'] = Variable<String>(objective.value);
    }
    if (estimatedWordCount.present) {
      map['estimated_word_count'] = Variable<int>(estimatedWordCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
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
    return (StringBuffer('ChaptersCompanion(')
          ..write('id: $id, ')
          ..write('universeId: $universeId, ')
          ..write('chapterNumber: $chapterNumber, ')
          ..write('act: $act, ')
          ..write('title: $title, ')
          ..write('objective: $objective, ')
          ..write('estimatedWordCount: $estimatedWordCount, ')
          ..write('status: $status, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScenesTable extends Scenes with TableInfo<$ScenesTable, Scene> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScenesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chapters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _universeIdMeta = const VerificationMeta(
    'universeId',
  );
  @override
  late final GeneratedColumn<String> universeId = GeneratedColumn<String>(
    'universe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES universes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sceneNumberMeta = const VerificationMeta(
    'sceneNumber',
  );
  @override
  late final GeneratedColumn<int> sceneNumber = GeneratedColumn<int>(
    'scene_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _povCharacterIdMeta = const VerificationMeta(
    'povCharacterId',
  );
  @override
  late final GeneratedColumn<String> povCharacterId = GeneratedColumn<String>(
    'pov_character_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tensionLevelMeta = const VerificationMeta(
    'tensionLevel',
  );
  @override
  late final GeneratedColumn<int> tensionLevel = GeneratedColumn<int>(
    'tension_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Outlined'),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    chapterId,
    universeId,
    sceneNumber,
    title,
    summary,
    povCharacterId,
    locationName,
    tensionLevel,
    status,
    orderIndex,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scenes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Scene> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('universe_id')) {
      context.handle(
        _universeIdMeta,
        universeId.isAcceptableOrUnknown(data['universe_id']!, _universeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_universeIdMeta);
    }
    if (data.containsKey('scene_number')) {
      context.handle(
        _sceneNumberMeta,
        sceneNumber.isAcceptableOrUnknown(
          data['scene_number']!,
          _sceneNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sceneNumberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('pov_character_id')) {
      context.handle(
        _povCharacterIdMeta,
        povCharacterId.isAcceptableOrUnknown(
          data['pov_character_id']!,
          _povCharacterIdMeta,
        ),
      );
    }
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    }
    if (data.containsKey('tension_level')) {
      context.handle(
        _tensionLevelMeta,
        tensionLevel.isAcceptableOrUnknown(
          data['tension_level']!,
          _tensionLevelMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Scene map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Scene(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_id'],
      )!,
      universeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}universe_id'],
      )!,
      sceneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scene_number'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      povCharacterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pov_character_id'],
      ),
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      ),
      tensionLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tension_level'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ScenesTable createAlias(String alias) {
    return $ScenesTable(attachedDatabase, alias);
  }
}

class Scene extends DataClass implements Insertable<Scene> {
  final String id;
  final String chapterId;
  final String universeId;
  final int sceneNumber;
  final String title;
  final String? summary;
  final String? povCharacterId;
  final String? locationName;
  final int tensionLevel;
  final String status;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Scene({
    required this.id,
    required this.chapterId,
    required this.universeId,
    required this.sceneNumber,
    required this.title,
    this.summary,
    this.povCharacterId,
    this.locationName,
    required this.tensionLevel,
    required this.status,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['chapter_id'] = Variable<String>(chapterId);
    map['universe_id'] = Variable<String>(universeId);
    map['scene_number'] = Variable<int>(sceneNumber);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    if (!nullToAbsent || povCharacterId != null) {
      map['pov_character_id'] = Variable<String>(povCharacterId);
    }
    if (!nullToAbsent || locationName != null) {
      map['location_name'] = Variable<String>(locationName);
    }
    map['tension_level'] = Variable<int>(tensionLevel);
    map['status'] = Variable<String>(status);
    map['order_index'] = Variable<int>(orderIndex);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ScenesCompanion toCompanion(bool nullToAbsent) {
    return ScenesCompanion(
      id: Value(id),
      chapterId: Value(chapterId),
      universeId: Value(universeId),
      sceneNumber: Value(sceneNumber),
      title: Value(title),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      povCharacterId: povCharacterId == null && nullToAbsent
          ? const Value.absent()
          : Value(povCharacterId),
      locationName: locationName == null && nullToAbsent
          ? const Value.absent()
          : Value(locationName),
      tensionLevel: Value(tensionLevel),
      status: Value(status),
      orderIndex: Value(orderIndex),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Scene.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Scene(
      id: serializer.fromJson<String>(json['id']),
      chapterId: serializer.fromJson<String>(json['chapterId']),
      universeId: serializer.fromJson<String>(json['universeId']),
      sceneNumber: serializer.fromJson<int>(json['sceneNumber']),
      title: serializer.fromJson<String>(json['title']),
      summary: serializer.fromJson<String?>(json['summary']),
      povCharacterId: serializer.fromJson<String?>(json['povCharacterId']),
      locationName: serializer.fromJson<String?>(json['locationName']),
      tensionLevel: serializer.fromJson<int>(json['tensionLevel']),
      status: serializer.fromJson<String>(json['status']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'chapterId': serializer.toJson<String>(chapterId),
      'universeId': serializer.toJson<String>(universeId),
      'sceneNumber': serializer.toJson<int>(sceneNumber),
      'title': serializer.toJson<String>(title),
      'summary': serializer.toJson<String?>(summary),
      'povCharacterId': serializer.toJson<String?>(povCharacterId),
      'locationName': serializer.toJson<String?>(locationName),
      'tensionLevel': serializer.toJson<int>(tensionLevel),
      'status': serializer.toJson<String>(status),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Scene copyWith({
    String? id,
    String? chapterId,
    String? universeId,
    int? sceneNumber,
    String? title,
    Value<String?> summary = const Value.absent(),
    Value<String?> povCharacterId = const Value.absent(),
    Value<String?> locationName = const Value.absent(),
    int? tensionLevel,
    String? status,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Scene(
    id: id ?? this.id,
    chapterId: chapterId ?? this.chapterId,
    universeId: universeId ?? this.universeId,
    sceneNumber: sceneNumber ?? this.sceneNumber,
    title: title ?? this.title,
    summary: summary.present ? summary.value : this.summary,
    povCharacterId: povCharacterId.present
        ? povCharacterId.value
        : this.povCharacterId,
    locationName: locationName.present ? locationName.value : this.locationName,
    tensionLevel: tensionLevel ?? this.tensionLevel,
    status: status ?? this.status,
    orderIndex: orderIndex ?? this.orderIndex,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Scene copyWithCompanion(ScenesCompanion data) {
    return Scene(
      id: data.id.present ? data.id.value : this.id,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      universeId: data.universeId.present
          ? data.universeId.value
          : this.universeId,
      sceneNumber: data.sceneNumber.present
          ? data.sceneNumber.value
          : this.sceneNumber,
      title: data.title.present ? data.title.value : this.title,
      summary: data.summary.present ? data.summary.value : this.summary,
      povCharacterId: data.povCharacterId.present
          ? data.povCharacterId.value
          : this.povCharacterId,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      tensionLevel: data.tensionLevel.present
          ? data.tensionLevel.value
          : this.tensionLevel,
      status: data.status.present ? data.status.value : this.status,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Scene(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('universeId: $universeId, ')
          ..write('sceneNumber: $sceneNumber, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('povCharacterId: $povCharacterId, ')
          ..write('locationName: $locationName, ')
          ..write('tensionLevel: $tensionLevel, ')
          ..write('status: $status, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    chapterId,
    universeId,
    sceneNumber,
    title,
    summary,
    povCharacterId,
    locationName,
    tensionLevel,
    status,
    orderIndex,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Scene &&
          other.id == this.id &&
          other.chapterId == this.chapterId &&
          other.universeId == this.universeId &&
          other.sceneNumber == this.sceneNumber &&
          other.title == this.title &&
          other.summary == this.summary &&
          other.povCharacterId == this.povCharacterId &&
          other.locationName == this.locationName &&
          other.tensionLevel == this.tensionLevel &&
          other.status == this.status &&
          other.orderIndex == this.orderIndex &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ScenesCompanion extends UpdateCompanion<Scene> {
  final Value<String> id;
  final Value<String> chapterId;
  final Value<String> universeId;
  final Value<int> sceneNumber;
  final Value<String> title;
  final Value<String?> summary;
  final Value<String?> povCharacterId;
  final Value<String?> locationName;
  final Value<int> tensionLevel;
  final Value<String> status;
  final Value<int> orderIndex;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ScenesCompanion({
    this.id = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.universeId = const Value.absent(),
    this.sceneNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
    this.povCharacterId = const Value.absent(),
    this.locationName = const Value.absent(),
    this.tensionLevel = const Value.absent(),
    this.status = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScenesCompanion.insert({
    required String id,
    required String chapterId,
    required String universeId,
    required int sceneNumber,
    required String title,
    this.summary = const Value.absent(),
    this.povCharacterId = const Value.absent(),
    this.locationName = const Value.absent(),
    this.tensionLevel = const Value.absent(),
    this.status = const Value.absent(),
    required int orderIndex,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       chapterId = Value(chapterId),
       universeId = Value(universeId),
       sceneNumber = Value(sceneNumber),
       title = Value(title),
       orderIndex = Value(orderIndex),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Scene> custom({
    Expression<String>? id,
    Expression<String>? chapterId,
    Expression<String>? universeId,
    Expression<int>? sceneNumber,
    Expression<String>? title,
    Expression<String>? summary,
    Expression<String>? povCharacterId,
    Expression<String>? locationName,
    Expression<int>? tensionLevel,
    Expression<String>? status,
    Expression<int>? orderIndex,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chapterId != null) 'chapter_id': chapterId,
      if (universeId != null) 'universe_id': universeId,
      if (sceneNumber != null) 'scene_number': sceneNumber,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (povCharacterId != null) 'pov_character_id': povCharacterId,
      if (locationName != null) 'location_name': locationName,
      if (tensionLevel != null) 'tension_level': tensionLevel,
      if (status != null) 'status': status,
      if (orderIndex != null) 'order_index': orderIndex,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScenesCompanion copyWith({
    Value<String>? id,
    Value<String>? chapterId,
    Value<String>? universeId,
    Value<int>? sceneNumber,
    Value<String>? title,
    Value<String?>? summary,
    Value<String?>? povCharacterId,
    Value<String?>? locationName,
    Value<int>? tensionLevel,
    Value<String>? status,
    Value<int>? orderIndex,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ScenesCompanion(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      universeId: universeId ?? this.universeId,
      sceneNumber: sceneNumber ?? this.sceneNumber,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      povCharacterId: povCharacterId ?? this.povCharacterId,
      locationName: locationName ?? this.locationName,
      tensionLevel: tensionLevel ?? this.tensionLevel,
      status: status ?? this.status,
      orderIndex: orderIndex ?? this.orderIndex,
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
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (universeId.present) {
      map['universe_id'] = Variable<String>(universeId.value);
    }
    if (sceneNumber.present) {
      map['scene_number'] = Variable<int>(sceneNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (povCharacterId.present) {
      map['pov_character_id'] = Variable<String>(povCharacterId.value);
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (tensionLevel.present) {
      map['tension_level'] = Variable<int>(tensionLevel.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
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
    return (StringBuffer('ScenesCompanion(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('universeId: $universeId, ')
          ..write('sceneNumber: $sceneNumber, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('povCharacterId: $povCharacterId, ')
          ..write('locationName: $locationName, ')
          ..write('tensionLevel: $tensionLevel, ')
          ..write('status: $status, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LoreEntriesTable extends LoreEntries
    with TableInfo<$LoreEntriesTable, LoreEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoreEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _universeIdMeta = const VerificationMeta(
    'universeId',
  );
  @override
  late final GeneratedColumn<String> universeId = GeneratedColumn<String>(
    'universe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES universes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    universeId,
    title,
    category,
    summary,
    content,
    tags,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lore_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoreEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('universe_id')) {
      context.handle(
        _universeIdMeta,
        universeId.isAcceptableOrUnknown(data['universe_id']!, _universeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_universeIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoreEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoreEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      universeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}universe_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LoreEntriesTable createAlias(String alias) {
    return $LoreEntriesTable(attachedDatabase, alias);
  }
}

class LoreEntry extends DataClass implements Insertable<LoreEntry> {
  final String id;
  final String universeId;
  final String title;
  final String category;
  final String? summary;
  final String? content;
  final String? tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LoreEntry({
    required this.id,
    required this.universeId,
    required this.title,
    required this.category,
    this.summary,
    this.content,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['universe_id'] = Variable<String>(universeId);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LoreEntriesCompanion toCompanion(bool nullToAbsent) {
    return LoreEntriesCompanion(
      id: Value(id),
      universeId: Value(universeId),
      title: Value(title),
      category: Value(category),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LoreEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoreEntry(
      id: serializer.fromJson<String>(json['id']),
      universeId: serializer.fromJson<String>(json['universeId']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      summary: serializer.fromJson<String?>(json['summary']),
      content: serializer.fromJson<String?>(json['content']),
      tags: serializer.fromJson<String?>(json['tags']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'universeId': serializer.toJson<String>(universeId),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'summary': serializer.toJson<String?>(summary),
      'content': serializer.toJson<String?>(content),
      'tags': serializer.toJson<String?>(tags),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LoreEntry copyWith({
    String? id,
    String? universeId,
    String? title,
    String? category,
    Value<String?> summary = const Value.absent(),
    Value<String?> content = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LoreEntry(
    id: id ?? this.id,
    universeId: universeId ?? this.universeId,
    title: title ?? this.title,
    category: category ?? this.category,
    summary: summary.present ? summary.value : this.summary,
    content: content.present ? content.value : this.content,
    tags: tags.present ? tags.value : this.tags,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LoreEntry copyWithCompanion(LoreEntriesCompanion data) {
    return LoreEntry(
      id: data.id.present ? data.id.value : this.id,
      universeId: data.universeId.present
          ? data.universeId.value
          : this.universeId,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      summary: data.summary.present ? data.summary.value : this.summary,
      content: data.content.present ? data.content.value : this.content,
      tags: data.tags.present ? data.tags.value : this.tags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoreEntry(')
          ..write('id: $id, ')
          ..write('universeId: $universeId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('summary: $summary, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    universeId,
    title,
    category,
    summary,
    content,
    tags,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoreEntry &&
          other.id == this.id &&
          other.universeId == this.universeId &&
          other.title == this.title &&
          other.category == this.category &&
          other.summary == this.summary &&
          other.content == this.content &&
          other.tags == this.tags &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LoreEntriesCompanion extends UpdateCompanion<LoreEntry> {
  final Value<String> id;
  final Value<String> universeId;
  final Value<String> title;
  final Value<String> category;
  final Value<String?> summary;
  final Value<String?> content;
  final Value<String?> tags;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LoreEntriesCompanion({
    this.id = const Value.absent(),
    this.universeId = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.summary = const Value.absent(),
    this.content = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoreEntriesCompanion.insert({
    required String id,
    required String universeId,
    required String title,
    required String category,
    this.summary = const Value.absent(),
    this.content = const Value.absent(),
    this.tags = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       universeId = Value(universeId),
       title = Value(title),
       category = Value(category),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LoreEntry> custom({
    Expression<String>? id,
    Expression<String>? universeId,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? summary,
    Expression<String>? content,
    Expression<String>? tags,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (universeId != null) 'universe_id': universeId,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (summary != null) 'summary': summary,
      if (content != null) 'content': content,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoreEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? universeId,
    Value<String>? title,
    Value<String>? category,
    Value<String?>? summary,
    Value<String?>? content,
    Value<String?>? tags,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LoreEntriesCompanion(
      id: id ?? this.id,
      universeId: universeId ?? this.universeId,
      title: title ?? this.title,
      category: category ?? this.category,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      tags: tags ?? this.tags,
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
    if (universeId.present) {
      map['universe_id'] = Variable<String>(universeId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
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
    return (StringBuffer('LoreEntriesCompanion(')
          ..write('id: $id, ')
          ..write('universeId: $universeId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('summary: $summary, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IdeaSparksTable extends IdeaSparks
    with TableInfo<$IdeaSparksTable, IdeaSpark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IdeaSparksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _universeIdMeta = const VerificationMeta(
    'universeId',
  );
  @override
  late final GeneratedColumn<String> universeId = GeneratedColumn<String>(
    'universe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES universes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('General'),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isConvertedMeta = const VerificationMeta(
    'isConverted',
  );
  @override
  late final GeneratedColumn<bool> isConverted = GeneratedColumn<bool>(
    'is_converted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_converted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    universeId,
    content,
    category,
    isPinned,
    isConverted,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'idea_sparks';
  @override
  VerificationContext validateIntegrity(
    Insertable<IdeaSpark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('universe_id')) {
      context.handle(
        _universeIdMeta,
        universeId.isAcceptableOrUnknown(data['universe_id']!, _universeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_universeIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('is_converted')) {
      context.handle(
        _isConvertedMeta,
        isConverted.isAcceptableOrUnknown(
          data['is_converted']!,
          _isConvertedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IdeaSpark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IdeaSpark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      universeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}universe_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      isConverted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_converted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $IdeaSparksTable createAlias(String alias) {
    return $IdeaSparksTable(attachedDatabase, alias);
  }
}

class IdeaSpark extends DataClass implements Insertable<IdeaSpark> {
  final String id;
  final String universeId;
  final String content;
  final String category;
  final bool isPinned;
  final bool isConverted;
  final DateTime createdAt;
  const IdeaSpark({
    required this.id,
    required this.universeId,
    required this.content,
    required this.category,
    required this.isPinned,
    required this.isConverted,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['universe_id'] = Variable<String>(universeId);
    map['content'] = Variable<String>(content);
    map['category'] = Variable<String>(category);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['is_converted'] = Variable<bool>(isConverted);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  IdeaSparksCompanion toCompanion(bool nullToAbsent) {
    return IdeaSparksCompanion(
      id: Value(id),
      universeId: Value(universeId),
      content: Value(content),
      category: Value(category),
      isPinned: Value(isPinned),
      isConverted: Value(isConverted),
      createdAt: Value(createdAt),
    );
  }

  factory IdeaSpark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IdeaSpark(
      id: serializer.fromJson<String>(json['id']),
      universeId: serializer.fromJson<String>(json['universeId']),
      content: serializer.fromJson<String>(json['content']),
      category: serializer.fromJson<String>(json['category']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      isConverted: serializer.fromJson<bool>(json['isConverted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'universeId': serializer.toJson<String>(universeId),
      'content': serializer.toJson<String>(content),
      'category': serializer.toJson<String>(category),
      'isPinned': serializer.toJson<bool>(isPinned),
      'isConverted': serializer.toJson<bool>(isConverted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  IdeaSpark copyWith({
    String? id,
    String? universeId,
    String? content,
    String? category,
    bool? isPinned,
    bool? isConverted,
    DateTime? createdAt,
  }) => IdeaSpark(
    id: id ?? this.id,
    universeId: universeId ?? this.universeId,
    content: content ?? this.content,
    category: category ?? this.category,
    isPinned: isPinned ?? this.isPinned,
    isConverted: isConverted ?? this.isConverted,
    createdAt: createdAt ?? this.createdAt,
  );
  IdeaSpark copyWithCompanion(IdeaSparksCompanion data) {
    return IdeaSpark(
      id: data.id.present ? data.id.value : this.id,
      universeId: data.universeId.present
          ? data.universeId.value
          : this.universeId,
      content: data.content.present ? data.content.value : this.content,
      category: data.category.present ? data.category.value : this.category,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      isConverted: data.isConverted.present
          ? data.isConverted.value
          : this.isConverted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IdeaSpark(')
          ..write('id: $id, ')
          ..write('universeId: $universeId, ')
          ..write('content: $content, ')
          ..write('category: $category, ')
          ..write('isPinned: $isPinned, ')
          ..write('isConverted: $isConverted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    universeId,
    content,
    category,
    isPinned,
    isConverted,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdeaSpark &&
          other.id == this.id &&
          other.universeId == this.universeId &&
          other.content == this.content &&
          other.category == this.category &&
          other.isPinned == this.isPinned &&
          other.isConverted == this.isConverted &&
          other.createdAt == this.createdAt);
}

class IdeaSparksCompanion extends UpdateCompanion<IdeaSpark> {
  final Value<String> id;
  final Value<String> universeId;
  final Value<String> content;
  final Value<String> category;
  final Value<bool> isPinned;
  final Value<bool> isConverted;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const IdeaSparksCompanion({
    this.id = const Value.absent(),
    this.universeId = const Value.absent(),
    this.content = const Value.absent(),
    this.category = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isConverted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IdeaSparksCompanion.insert({
    required String id,
    required String universeId,
    required String content,
    this.category = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isConverted = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       universeId = Value(universeId),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<IdeaSpark> custom({
    Expression<String>? id,
    Expression<String>? universeId,
    Expression<String>? content,
    Expression<String>? category,
    Expression<bool>? isPinned,
    Expression<bool>? isConverted,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (universeId != null) 'universe_id': universeId,
      if (content != null) 'content': content,
      if (category != null) 'category': category,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isConverted != null) 'is_converted': isConverted,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IdeaSparksCompanion copyWith({
    Value<String>? id,
    Value<String>? universeId,
    Value<String>? content,
    Value<String>? category,
    Value<bool>? isPinned,
    Value<bool>? isConverted,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return IdeaSparksCompanion(
      id: id ?? this.id,
      universeId: universeId ?? this.universeId,
      content: content ?? this.content,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      isConverted: isConverted ?? this.isConverted,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (universeId.present) {
      map['universe_id'] = Variable<String>(universeId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (isConverted.present) {
      map['is_converted'] = Variable<bool>(isConverted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IdeaSparksCompanion(')
          ..write('id: $id, ')
          ..write('universeId: $universeId, ')
          ..write('content: $content, ')
          ..write('category: $category, ')
          ..write('isPinned: $isPinned, ')
          ..write('isConverted: $isConverted, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UniversesTable universes = $UniversesTable(this);
  late final $CharactersTable characters = $CharactersTable(this);
  late final $CharacterRelationshipsTable characterRelationships =
      $CharacterRelationshipsTable(this);
  late final $ChaptersTable chapters = $ChaptersTable(this);
  late final $ScenesTable scenes = $ScenesTable(this);
  late final $LoreEntriesTable loreEntries = $LoreEntriesTable(this);
  late final $IdeaSparksTable ideaSparks = $IdeaSparksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    universes,
    characters,
    characterRelationships,
    chapters,
    scenes,
    loreEntries,
    ideaSparks,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'universes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('characters', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'universes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('character_relationships', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'characters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('character_relationships', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'characters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('character_relationships', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'universes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chapters', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chapters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('scenes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'universes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('scenes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'characters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('scenes', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'universes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lore_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'universes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('idea_sparks', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$UniversesTableCreateCompanionBuilder =
    UniversesCompanion Function({
      required String id,
      required String title,
      required String genre,
      Value<String?> logline,
      Value<String?> synopsis,
      Value<String> coverColor,
      Value<String?> linkedProjectInkId,
      Value<String?> linkedProjectInkName,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$UniversesTableUpdateCompanionBuilder =
    UniversesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> genre,
      Value<String?> logline,
      Value<String?> synopsis,
      Value<String> coverColor,
      Value<String?> linkedProjectInkId,
      Value<String?> linkedProjectInkName,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$UniversesTableReferences
    extends BaseReferences<_$AppDatabase, $UniversesTable, Universe> {
  $$UniversesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CharactersTable, List<Character>>
  _charactersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.characters,
    aliasName: 'universes__id__characters__universe_id',
  );

  $$CharactersTableProcessedTableManager get charactersRefs {
    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.universeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_charactersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CharacterRelationshipsTable,
    List<CharacterRelationship>
  >
  _characterRelationshipsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.characterRelationships,
        aliasName: 'universes__id__character_relationships__universe_id',
      );

  $$CharacterRelationshipsTableProcessedTableManager
  get characterRelationshipsRefs {
    final manager = $$CharacterRelationshipsTableTableManager(
      $_db,
      $_db.characterRelationships,
    ).filter((f) => f.universeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _characterRelationshipsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChaptersTable, List<Chapter>> _chaptersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.chapters,
    aliasName: 'universes__id__chapters__universe_id',
  );

  $$ChaptersTableProcessedTableManager get chaptersRefs {
    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.universeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chaptersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScenesTable, List<Scene>> _scenesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.scenes,
    aliasName: 'universes__id__scenes__universe_id',
  );

  $$ScenesTableProcessedTableManager get scenesRefs {
    final manager = $$ScenesTableTableManager(
      $_db,
      $_db.scenes,
    ).filter((f) => f.universeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scenesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LoreEntriesTable, List<LoreEntry>>
  _loreEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.loreEntries,
    aliasName: 'universes__id__lore_entries__universe_id',
  );

  $$LoreEntriesTableProcessedTableManager get loreEntriesRefs {
    final manager = $$LoreEntriesTableTableManager(
      $_db,
      $_db.loreEntries,
    ).filter((f) => f.universeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_loreEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$IdeaSparksTable, List<IdeaSpark>>
  _ideaSparksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ideaSparks,
    aliasName: 'universes__id__idea_sparks__universe_id',
  );

  $$IdeaSparksTableProcessedTableManager get ideaSparksRefs {
    final manager = $$IdeaSparksTableTableManager(
      $_db,
      $_db.ideaSparks,
    ).filter((f) => f.universeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ideaSparksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UniversesTableFilterComposer
    extends Composer<_$AppDatabase, $UniversesTable> {
  $$UniversesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logline => $composableBuilder(
    column: $table.logline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get synopsis => $composableBuilder(
    column: $table.synopsis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverColor => $composableBuilder(
    column: $table.coverColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedProjectInkId => $composableBuilder(
    column: $table.linkedProjectInkId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedProjectInkName => $composableBuilder(
    column: $table.linkedProjectInkName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> charactersRefs(
    Expression<bool> Function($$CharactersTableFilterComposer f) f,
  ) {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.universeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> characterRelationshipsRefs(
    Expression<bool> Function($$CharacterRelationshipsTableFilterComposer f) f,
  ) {
    final $$CharacterRelationshipsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.characterRelationships,
          getReferencedColumn: (t) => t.universeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CharacterRelationshipsTableFilterComposer(
                $db: $db,
                $table: $db.characterRelationships,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> chaptersRefs(
    Expression<bool> Function($$ChaptersTableFilterComposer f) f,
  ) {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.universeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scenesRefs(
    Expression<bool> Function($$ScenesTableFilterComposer f) f,
  ) {
    final $$ScenesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scenes,
      getReferencedColumn: (t) => t.universeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScenesTableFilterComposer(
            $db: $db,
            $table: $db.scenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> loreEntriesRefs(
    Expression<bool> Function($$LoreEntriesTableFilterComposer f) f,
  ) {
    final $$LoreEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loreEntries,
      getReferencedColumn: (t) => t.universeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntriesTableFilterComposer(
            $db: $db,
            $table: $db.loreEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ideaSparksRefs(
    Expression<bool> Function($$IdeaSparksTableFilterComposer f) f,
  ) {
    final $$IdeaSparksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ideaSparks,
      getReferencedColumn: (t) => t.universeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IdeaSparksTableFilterComposer(
            $db: $db,
            $table: $db.ideaSparks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UniversesTableOrderingComposer
    extends Composer<_$AppDatabase, $UniversesTable> {
  $$UniversesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logline => $composableBuilder(
    column: $table.logline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get synopsis => $composableBuilder(
    column: $table.synopsis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverColor => $composableBuilder(
    column: $table.coverColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedProjectInkId => $composableBuilder(
    column: $table.linkedProjectInkId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedProjectInkName => $composableBuilder(
    column: $table.linkedProjectInkName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UniversesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UniversesTable> {
  $$UniversesTableAnnotationComposer({
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

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get logline =>
      $composableBuilder(column: $table.logline, builder: (column) => column);

  GeneratedColumn<String> get synopsis =>
      $composableBuilder(column: $table.synopsis, builder: (column) => column);

  GeneratedColumn<String> get coverColor => $composableBuilder(
    column: $table.coverColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedProjectInkId => $composableBuilder(
    column: $table.linkedProjectInkId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedProjectInkName => $composableBuilder(
    column: $table.linkedProjectInkName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> charactersRefs<T extends Object>(
    Expression<T> Function($$CharactersTableAnnotationComposer a) f,
  ) {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.universeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> characterRelationshipsRefs<T extends Object>(
    Expression<T> Function($$CharacterRelationshipsTableAnnotationComposer a) f,
  ) {
    final $$CharacterRelationshipsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.characterRelationships,
          getReferencedColumn: (t) => t.universeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CharacterRelationshipsTableAnnotationComposer(
                $db: $db,
                $table: $db.characterRelationships,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> chaptersRefs<T extends Object>(
    Expression<T> Function($$ChaptersTableAnnotationComposer a) f,
  ) {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.universeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> scenesRefs<T extends Object>(
    Expression<T> Function($$ScenesTableAnnotationComposer a) f,
  ) {
    final $$ScenesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scenes,
      getReferencedColumn: (t) => t.universeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScenesTableAnnotationComposer(
            $db: $db,
            $table: $db.scenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> loreEntriesRefs<T extends Object>(
    Expression<T> Function($$LoreEntriesTableAnnotationComposer a) f,
  ) {
    final $$LoreEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loreEntries,
      getReferencedColumn: (t) => t.universeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.loreEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ideaSparksRefs<T extends Object>(
    Expression<T> Function($$IdeaSparksTableAnnotationComposer a) f,
  ) {
    final $$IdeaSparksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ideaSparks,
      getReferencedColumn: (t) => t.universeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IdeaSparksTableAnnotationComposer(
            $db: $db,
            $table: $db.ideaSparks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UniversesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UniversesTable,
          Universe,
          $$UniversesTableFilterComposer,
          $$UniversesTableOrderingComposer,
          $$UniversesTableAnnotationComposer,
          $$UniversesTableCreateCompanionBuilder,
          $$UniversesTableUpdateCompanionBuilder,
          (Universe, $$UniversesTableReferences),
          Universe,
          PrefetchHooks Function({
            bool charactersRefs,
            bool characterRelationshipsRefs,
            bool chaptersRefs,
            bool scenesRefs,
            bool loreEntriesRefs,
            bool ideaSparksRefs,
          })
        > {
  $$UniversesTableTableManager(_$AppDatabase db, $UniversesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UniversesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UniversesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UniversesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> genre = const Value.absent(),
                Value<String?> logline = const Value.absent(),
                Value<String?> synopsis = const Value.absent(),
                Value<String> coverColor = const Value.absent(),
                Value<String?> linkedProjectInkId = const Value.absent(),
                Value<String?> linkedProjectInkName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UniversesCompanion(
                id: id,
                title: title,
                genre: genre,
                logline: logline,
                synopsis: synopsis,
                coverColor: coverColor,
                linkedProjectInkId: linkedProjectInkId,
                linkedProjectInkName: linkedProjectInkName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String genre,
                Value<String?> logline = const Value.absent(),
                Value<String?> synopsis = const Value.absent(),
                Value<String> coverColor = const Value.absent(),
                Value<String?> linkedProjectInkId = const Value.absent(),
                Value<String?> linkedProjectInkName = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UniversesCompanion.insert(
                id: id,
                title: title,
                genre: genre,
                logline: logline,
                synopsis: synopsis,
                coverColor: coverColor,
                linkedProjectInkId: linkedProjectInkId,
                linkedProjectInkName: linkedProjectInkName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UniversesTable, Universe>(table),
                  $$UniversesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                charactersRefs = false,
                characterRelationshipsRefs = false,
                chaptersRefs = false,
                scenesRefs = false,
                loreEntriesRefs = false,
                ideaSparksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (charactersRefs) db.characters,
                    if (characterRelationshipsRefs) db.characterRelationships,
                    if (chaptersRefs) db.chapters,
                    if (scenesRefs) db.scenes,
                    if (loreEntriesRefs) db.loreEntries,
                    if (ideaSparksRefs) db.ideaSparks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (charactersRefs)
                        await $_getPrefetchedData<
                          Universe,
                          $UniversesTable,
                          Character
                        >(
                          currentTable: table,
                          referencedTable: $$UniversesTableReferences
                              ._charactersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UniversesTableReferences(
                                db,
                                table,
                                p0,
                              ).charactersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.universeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (characterRelationshipsRefs)
                        await $_getPrefetchedData<
                          Universe,
                          $UniversesTable,
                          CharacterRelationship
                        >(
                          currentTable: table,
                          referencedTable: $$UniversesTableReferences
                              ._characterRelationshipsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UniversesTableReferences(
                                db,
                                table,
                                p0,
                              ).characterRelationshipsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.universeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (chaptersRefs)
                        await $_getPrefetchedData<
                          Universe,
                          $UniversesTable,
                          Chapter
                        >(
                          currentTable: table,
                          referencedTable: $$UniversesTableReferences
                              ._chaptersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UniversesTableReferences(
                                db,
                                table,
                                p0,
                              ).chaptersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.universeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scenesRefs)
                        await $_getPrefetchedData<
                          Universe,
                          $UniversesTable,
                          Scene
                        >(
                          currentTable: table,
                          referencedTable: $$UniversesTableReferences
                              ._scenesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UniversesTableReferences(
                                db,
                                table,
                                p0,
                              ).scenesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.universeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (loreEntriesRefs)
                        await $_getPrefetchedData<
                          Universe,
                          $UniversesTable,
                          LoreEntry
                        >(
                          currentTable: table,
                          referencedTable: $$UniversesTableReferences
                              ._loreEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UniversesTableReferences(
                                db,
                                table,
                                p0,
                              ).loreEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.universeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ideaSparksRefs)
                        await $_getPrefetchedData<
                          Universe,
                          $UniversesTable,
                          IdeaSpark
                        >(
                          currentTable: table,
                          referencedTable: $$UniversesTableReferences
                              ._ideaSparksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UniversesTableReferences(
                                db,
                                table,
                                p0,
                              ).ideaSparksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.universeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$UniversesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UniversesTable,
      Universe,
      $$UniversesTableFilterComposer,
      $$UniversesTableOrderingComposer,
      $$UniversesTableAnnotationComposer,
      $$UniversesTableCreateCompanionBuilder,
      $$UniversesTableUpdateCompanionBuilder,
      (Universe, $$UniversesTableReferences),
      Universe,
      PrefetchHooks Function({
        bool charactersRefs,
        bool characterRelationshipsRefs,
        bool chaptersRefs,
        bool scenesRefs,
        bool loreEntriesRefs,
        bool ideaSparksRefs,
      })
    >;
typedef $$CharactersTableCreateCompanionBuilder =
    CharactersCompanion Function({
      required String id,
      required String universeId,
      required String name,
      Value<String?> alias,
      required String role,
      Value<String?> archetype,
      Value<String?> age,
      Value<String?> occupation,
      Value<String?> motivation,
      Value<String?> flaw,
      Value<String?> internalConflict,
      Value<String?> backstory,
      Value<String> arcStage,
      Value<String?> notes,
      Value<String> avatarColor,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CharactersTableUpdateCompanionBuilder =
    CharactersCompanion Function({
      Value<String> id,
      Value<String> universeId,
      Value<String> name,
      Value<String?> alias,
      Value<String> role,
      Value<String?> archetype,
      Value<String?> age,
      Value<String?> occupation,
      Value<String?> motivation,
      Value<String?> flaw,
      Value<String?> internalConflict,
      Value<String?> backstory,
      Value<String> arcStage,
      Value<String?> notes,
      Value<String> avatarColor,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CharactersTableReferences
    extends BaseReferences<_$AppDatabase, $CharactersTable, Character> {
  $$CharactersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UniversesTable _universeIdTable(_$AppDatabase db) =>
      db.universes.createAlias('characters__universe_id__universes__id');

  $$UniversesTableProcessedTableManager get universeId {
    final $_column = $_itemColumn<String>('universe_id')!;

    final manager = $$UniversesTableTableManager(
      $_db,
      $_db.universes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_universeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ScenesTable, List<Scene>> _scenesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.scenes,
    aliasName: 'characters__id__scenes__pov_character_id',
  );

  $$ScenesTableProcessedTableManager get scenesRefs {
    final manager = $$ScenesTableTableManager(
      $_db,
      $_db.scenes,
    ).filter((f) => f.povCharacterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scenesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CharactersTableFilterComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get archetype => $composableBuilder(
    column: $table.archetype,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occupation => $composableBuilder(
    column: $table.occupation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motivation => $composableBuilder(
    column: $table.motivation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flaw => $composableBuilder(
    column: $table.flaw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get internalConflict => $composableBuilder(
    column: $table.internalConflict,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backstory => $composableBuilder(
    column: $table.backstory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arcStage => $composableBuilder(
    column: $table.arcStage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UniversesTableFilterComposer get universeId {
    final $$UniversesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableFilterComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> scenesRefs(
    Expression<bool> Function($$ScenesTableFilterComposer f) f,
  ) {
    final $$ScenesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scenes,
      getReferencedColumn: (t) => t.povCharacterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScenesTableFilterComposer(
            $db: $db,
            $table: $db.scenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CharactersTableOrderingComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archetype => $composableBuilder(
    column: $table.archetype,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occupation => $composableBuilder(
    column: $table.occupation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motivation => $composableBuilder(
    column: $table.motivation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flaw => $composableBuilder(
    column: $table.flaw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get internalConflict => $composableBuilder(
    column: $table.internalConflict,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backstory => $composableBuilder(
    column: $table.backstory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arcStage => $composableBuilder(
    column: $table.arcStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UniversesTableOrderingComposer get universeId {
    final $$UniversesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableOrderingComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharactersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableAnnotationComposer({
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

  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get archetype =>
      $composableBuilder(column: $table.archetype, builder: (column) => column);

  GeneratedColumn<String> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<String> get occupation => $composableBuilder(
    column: $table.occupation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motivation => $composableBuilder(
    column: $table.motivation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get flaw =>
      $composableBuilder(column: $table.flaw, builder: (column) => column);

  GeneratedColumn<String> get internalConflict => $composableBuilder(
    column: $table.internalConflict,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backstory =>
      $composableBuilder(column: $table.backstory, builder: (column) => column);

  GeneratedColumn<String> get arcStage =>
      $composableBuilder(column: $table.arcStage, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UniversesTableAnnotationComposer get universeId {
    final $$UniversesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableAnnotationComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> scenesRefs<T extends Object>(
    Expression<T> Function($$ScenesTableAnnotationComposer a) f,
  ) {
    final $$ScenesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scenes,
      getReferencedColumn: (t) => t.povCharacterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScenesTableAnnotationComposer(
            $db: $db,
            $table: $db.scenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CharactersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharactersTable,
          Character,
          $$CharactersTableFilterComposer,
          $$CharactersTableOrderingComposer,
          $$CharactersTableAnnotationComposer,
          $$CharactersTableCreateCompanionBuilder,
          $$CharactersTableUpdateCompanionBuilder,
          (Character, $$CharactersTableReferences),
          Character,
          PrefetchHooks Function({bool universeId, bool scenesRefs})
        > {
  $$CharactersTableTableManager(_$AppDatabase db, $CharactersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharactersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharactersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharactersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> universeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> alias = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> archetype = const Value.absent(),
                Value<String?> age = const Value.absent(),
                Value<String?> occupation = const Value.absent(),
                Value<String?> motivation = const Value.absent(),
                Value<String?> flaw = const Value.absent(),
                Value<String?> internalConflict = const Value.absent(),
                Value<String?> backstory = const Value.absent(),
                Value<String> arcStage = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> avatarColor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharactersCompanion(
                id: id,
                universeId: universeId,
                name: name,
                alias: alias,
                role: role,
                archetype: archetype,
                age: age,
                occupation: occupation,
                motivation: motivation,
                flaw: flaw,
                internalConflict: internalConflict,
                backstory: backstory,
                arcStage: arcStage,
                notes: notes,
                avatarColor: avatarColor,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String universeId,
                required String name,
                Value<String?> alias = const Value.absent(),
                required String role,
                Value<String?> archetype = const Value.absent(),
                Value<String?> age = const Value.absent(),
                Value<String?> occupation = const Value.absent(),
                Value<String?> motivation = const Value.absent(),
                Value<String?> flaw = const Value.absent(),
                Value<String?> internalConflict = const Value.absent(),
                Value<String?> backstory = const Value.absent(),
                Value<String> arcStage = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> avatarColor = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CharactersCompanion.insert(
                id: id,
                universeId: universeId,
                name: name,
                alias: alias,
                role: role,
                archetype: archetype,
                age: age,
                occupation: occupation,
                motivation: motivation,
                flaw: flaw,
                internalConflict: internalConflict,
                backstory: backstory,
                arcStage: arcStage,
                notes: notes,
                avatarColor: avatarColor,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CharactersTable, Character>(table),
                  $$CharactersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({universeId = false, scenesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (scenesRefs) db.scenes],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (universeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.universeId,
                                referencedTable: $$CharactersTableReferences
                                    ._universeIdTable(db),
                                referencedColumn: $$CharactersTableReferences
                                    ._universeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (scenesRefs)
                    await $_getPrefetchedData<
                      Character,
                      $CharactersTable,
                      Scene
                    >(
                      currentTable: table,
                      referencedTable: $$CharactersTableReferences
                          ._scenesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CharactersTableReferences(db, table, p0).scenesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.povCharacterId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CharactersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharactersTable,
      Character,
      $$CharactersTableFilterComposer,
      $$CharactersTableOrderingComposer,
      $$CharactersTableAnnotationComposer,
      $$CharactersTableCreateCompanionBuilder,
      $$CharactersTableUpdateCompanionBuilder,
      (Character, $$CharactersTableReferences),
      Character,
      PrefetchHooks Function({bool universeId, bool scenesRefs})
    >;
typedef $$CharacterRelationshipsTableCreateCompanionBuilder =
    CharacterRelationshipsCompanion Function({
      required String id,
      required String universeId,
      required String sourceCharacterId,
      required String targetCharacterId,
      required String relationType,
      Value<String?> description,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CharacterRelationshipsTableUpdateCompanionBuilder =
    CharacterRelationshipsCompanion Function({
      Value<String> id,
      Value<String> universeId,
      Value<String> sourceCharacterId,
      Value<String> targetCharacterId,
      Value<String> relationType,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$CharacterRelationshipsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CharacterRelationshipsTable,
          CharacterRelationship
        > {
  $$CharacterRelationshipsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UniversesTable _universeIdTable(_$AppDatabase db) => db.universes
      .createAlias('character_relationships__universe_id__universes__id');

  $$UniversesTableProcessedTableManager get universeId {
    final $_column = $_itemColumn<String>('universe_id')!;

    final manager = $$UniversesTableTableManager(
      $_db,
      $_db.universes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_universeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CharactersTable _sourceCharacterIdTable(_$AppDatabase db) =>
      db.characters.createAlias(
        'character_relationships__source_character_id__characters__id',
      );

  $$CharactersTableProcessedTableManager get sourceCharacterId {
    final $_column = $_itemColumn<String>('source_character_id')!;

    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceCharacterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CharactersTable _targetCharacterIdTable(_$AppDatabase db) =>
      db.characters.createAlias(
        'character_relationships__target_character_id__characters__id',
      );

  $$CharactersTableProcessedTableManager get targetCharacterId {
    final $_column = $_itemColumn<String>('target_character_id')!;

    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_targetCharacterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CharacterRelationshipsTableFilterComposer
    extends Composer<_$AppDatabase, $CharacterRelationshipsTable> {
  $$CharacterRelationshipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UniversesTableFilterComposer get universeId {
    final $$UniversesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableFilterComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableFilterComposer get sourceCharacterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableFilterComposer get targetCharacterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterRelationshipsTableOrderingComposer
    extends Composer<_$AppDatabase, $CharacterRelationshipsTable> {
  $$CharacterRelationshipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UniversesTableOrderingComposer get universeId {
    final $$UniversesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableOrderingComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableOrderingComposer get sourceCharacterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableOrderingComposer get targetCharacterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterRelationshipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharacterRelationshipsTable> {
  $$CharacterRelationshipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UniversesTableAnnotationComposer get universeId {
    final $$UniversesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableAnnotationComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableAnnotationComposer get sourceCharacterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableAnnotationComposer get targetCharacterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterRelationshipsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharacterRelationshipsTable,
          CharacterRelationship,
          $$CharacterRelationshipsTableFilterComposer,
          $$CharacterRelationshipsTableOrderingComposer,
          $$CharacterRelationshipsTableAnnotationComposer,
          $$CharacterRelationshipsTableCreateCompanionBuilder,
          $$CharacterRelationshipsTableUpdateCompanionBuilder,
          (CharacterRelationship, $$CharacterRelationshipsTableReferences),
          CharacterRelationship,
          PrefetchHooks Function({
            bool universeId,
            bool sourceCharacterId,
            bool targetCharacterId,
          })
        > {
  $$CharacterRelationshipsTableTableManager(
    _$AppDatabase db,
    $CharacterRelationshipsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterRelationshipsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CharacterRelationshipsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CharacterRelationshipsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> universeId = const Value.absent(),
                Value<String> sourceCharacterId = const Value.absent(),
                Value<String> targetCharacterId = const Value.absent(),
                Value<String> relationType = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterRelationshipsCompanion(
                id: id,
                universeId: universeId,
                sourceCharacterId: sourceCharacterId,
                targetCharacterId: targetCharacterId,
                relationType: relationType,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String universeId,
                required String sourceCharacterId,
                required String targetCharacterId,
                required String relationType,
                Value<String?> description = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CharacterRelationshipsCompanion.insert(
                id: id,
                universeId: universeId,
                sourceCharacterId: sourceCharacterId,
                targetCharacterId: targetCharacterId,
                relationType: relationType,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CharacterRelationshipsTable,
                    CharacterRelationship
                  >(table),
                  $$CharacterRelationshipsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                universeId = false,
                sourceCharacterId = false,
                targetCharacterId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
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
                          dynamic
                        >
                      >(state) {
                        if (universeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.universeId,
                                    referencedTable:
                                        $$CharacterRelationshipsTableReferences
                                            ._universeIdTable(db),
                                    referencedColumn:
                                        $$CharacterRelationshipsTableReferences
                                            ._universeIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (sourceCharacterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sourceCharacterId,
                                    referencedTable:
                                        $$CharacterRelationshipsTableReferences
                                            ._sourceCharacterIdTable(db),
                                    referencedColumn:
                                        $$CharacterRelationshipsTableReferences
                                            ._sourceCharacterIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (targetCharacterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.targetCharacterId,
                                    referencedTable:
                                        $$CharacterRelationshipsTableReferences
                                            ._targetCharacterIdTable(db),
                                    referencedColumn:
                                        $$CharacterRelationshipsTableReferences
                                            ._targetCharacterIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$CharacterRelationshipsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharacterRelationshipsTable,
      CharacterRelationship,
      $$CharacterRelationshipsTableFilterComposer,
      $$CharacterRelationshipsTableOrderingComposer,
      $$CharacterRelationshipsTableAnnotationComposer,
      $$CharacterRelationshipsTableCreateCompanionBuilder,
      $$CharacterRelationshipsTableUpdateCompanionBuilder,
      (CharacterRelationship, $$CharacterRelationshipsTableReferences),
      CharacterRelationship,
      PrefetchHooks Function({
        bool universeId,
        bool sourceCharacterId,
        bool targetCharacterId,
      })
    >;
typedef $$ChaptersTableCreateCompanionBuilder =
    ChaptersCompanion Function({
      required String id,
      required String universeId,
      required int chapterNumber,
      Value<String> act,
      required String title,
      Value<String?> objective,
      Value<int> estimatedWordCount,
      Value<String> status,
      required int orderIndex,
      Value<String?> notes,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ChaptersTableUpdateCompanionBuilder =
    ChaptersCompanion Function({
      Value<String> id,
      Value<String> universeId,
      Value<int> chapterNumber,
      Value<String> act,
      Value<String> title,
      Value<String?> objective,
      Value<int> estimatedWordCount,
      Value<String> status,
      Value<int> orderIndex,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ChaptersTableReferences
    extends BaseReferences<_$AppDatabase, $ChaptersTable, Chapter> {
  $$ChaptersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UniversesTable _universeIdTable(_$AppDatabase db) =>
      db.universes.createAlias('chapters__universe_id__universes__id');

  $$UniversesTableProcessedTableManager get universeId {
    final $_column = $_itemColumn<String>('universe_id')!;

    final manager = $$UniversesTableTableManager(
      $_db,
      $_db.universes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_universeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ScenesTable, List<Scene>> _scenesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.scenes,
    aliasName: 'chapters__id__scenes__chapter_id',
  );

  $$ScenesTableProcessedTableManager get scenesRefs {
    final manager = $$ScenesTableTableManager(
      $_db,
      $_db.scenes,
    ).filter((f) => f.chapterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scenesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChaptersTableFilterComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterNumber => $composableBuilder(
    column: $table.chapterNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get act => $composableBuilder(
    column: $table.act,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get objective => $composableBuilder(
    column: $table.objective,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedWordCount => $composableBuilder(
    column: $table.estimatedWordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UniversesTableFilterComposer get universeId {
    final $$UniversesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableFilterComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> scenesRefs(
    Expression<bool> Function($$ScenesTableFilterComposer f) f,
  ) {
    final $$ScenesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scenes,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScenesTableFilterComposer(
            $db: $db,
            $table: $db.scenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChaptersTableOrderingComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterNumber => $composableBuilder(
    column: $table.chapterNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get act => $composableBuilder(
    column: $table.act,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get objective => $composableBuilder(
    column: $table.objective,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedWordCount => $composableBuilder(
    column: $table.estimatedWordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UniversesTableOrderingComposer get universeId {
    final $$UniversesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableOrderingComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChaptersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get chapterNumber => $composableBuilder(
    column: $table.chapterNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get act =>
      $composableBuilder(column: $table.act, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get objective =>
      $composableBuilder(column: $table.objective, builder: (column) => column);

  GeneratedColumn<int> get estimatedWordCount => $composableBuilder(
    column: $table.estimatedWordCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UniversesTableAnnotationComposer get universeId {
    final $$UniversesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableAnnotationComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> scenesRefs<T extends Object>(
    Expression<T> Function($$ScenesTableAnnotationComposer a) f,
  ) {
    final $$ScenesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scenes,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScenesTableAnnotationComposer(
            $db: $db,
            $table: $db.scenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChaptersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChaptersTable,
          Chapter,
          $$ChaptersTableFilterComposer,
          $$ChaptersTableOrderingComposer,
          $$ChaptersTableAnnotationComposer,
          $$ChaptersTableCreateCompanionBuilder,
          $$ChaptersTableUpdateCompanionBuilder,
          (Chapter, $$ChaptersTableReferences),
          Chapter,
          PrefetchHooks Function({bool universeId, bool scenesRefs})
        > {
  $$ChaptersTableTableManager(_$AppDatabase db, $ChaptersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> universeId = const Value.absent(),
                Value<int> chapterNumber = const Value.absent(),
                Value<String> act = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> objective = const Value.absent(),
                Value<int> estimatedWordCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChaptersCompanion(
                id: id,
                universeId: universeId,
                chapterNumber: chapterNumber,
                act: act,
                title: title,
                objective: objective,
                estimatedWordCount: estimatedWordCount,
                status: status,
                orderIndex: orderIndex,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String universeId,
                required int chapterNumber,
                Value<String> act = const Value.absent(),
                required String title,
                Value<String?> objective = const Value.absent(),
                Value<int> estimatedWordCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                required int orderIndex,
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChaptersCompanion.insert(
                id: id,
                universeId: universeId,
                chapterNumber: chapterNumber,
                act: act,
                title: title,
                objective: objective,
                estimatedWordCount: estimatedWordCount,
                status: status,
                orderIndex: orderIndex,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChaptersTable, Chapter>(table),
                  $$ChaptersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({universeId = false, scenesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (scenesRefs) db.scenes],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (universeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.universeId,
                                referencedTable: $$ChaptersTableReferences
                                    ._universeIdTable(db),
                                referencedColumn: $$ChaptersTableReferences
                                    ._universeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (scenesRefs)
                    await $_getPrefetchedData<Chapter, $ChaptersTable, Scene>(
                      currentTable: table,
                      referencedTable: $$ChaptersTableReferences
                          ._scenesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ChaptersTableReferences(db, table, p0).scenesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.chapterId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ChaptersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChaptersTable,
      Chapter,
      $$ChaptersTableFilterComposer,
      $$ChaptersTableOrderingComposer,
      $$ChaptersTableAnnotationComposer,
      $$ChaptersTableCreateCompanionBuilder,
      $$ChaptersTableUpdateCompanionBuilder,
      (Chapter, $$ChaptersTableReferences),
      Chapter,
      PrefetchHooks Function({bool universeId, bool scenesRefs})
    >;
typedef $$ScenesTableCreateCompanionBuilder =
    ScenesCompanion Function({
      required String id,
      required String chapterId,
      required String universeId,
      required int sceneNumber,
      required String title,
      Value<String?> summary,
      Value<String?> povCharacterId,
      Value<String?> locationName,
      Value<int> tensionLevel,
      Value<String> status,
      required int orderIndex,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ScenesTableUpdateCompanionBuilder =
    ScenesCompanion Function({
      Value<String> id,
      Value<String> chapterId,
      Value<String> universeId,
      Value<int> sceneNumber,
      Value<String> title,
      Value<String?> summary,
      Value<String?> povCharacterId,
      Value<String?> locationName,
      Value<int> tensionLevel,
      Value<String> status,
      Value<int> orderIndex,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ScenesTableReferences
    extends BaseReferences<_$AppDatabase, $ScenesTable, Scene> {
  $$ScenesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChaptersTable _chapterIdTable(_$AppDatabase db) =>
      db.chapters.createAlias('scenes__chapter_id__chapters__id');

  $$ChaptersTableProcessedTableManager get chapterId {
    final $_column = $_itemColumn<String>('chapter_id')!;

    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UniversesTable _universeIdTable(_$AppDatabase db) =>
      db.universes.createAlias('scenes__universe_id__universes__id');

  $$UniversesTableProcessedTableManager get universeId {
    final $_column = $_itemColumn<String>('universe_id')!;

    final manager = $$UniversesTableTableManager(
      $_db,
      $_db.universes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_universeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CharactersTable _povCharacterIdTable(_$AppDatabase db) =>
      db.characters.createAlias('scenes__pov_character_id__characters__id');

  $$CharactersTableProcessedTableManager? get povCharacterId {
    final $_column = $_itemColumn<String>('pov_character_id');
    if ($_column == null) return null;
    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_povCharacterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScenesTableFilterComposer
    extends Composer<_$AppDatabase, $ScenesTable> {
  $$ScenesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sceneNumber => $composableBuilder(
    column: $table.sceneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tensionLevel => $composableBuilder(
    column: $table.tensionLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ChaptersTableFilterComposer get chapterId {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UniversesTableFilterComposer get universeId {
    final $$UniversesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableFilterComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableFilterComposer get povCharacterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.povCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScenesTableOrderingComposer
    extends Composer<_$AppDatabase, $ScenesTable> {
  $$ScenesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sceneNumber => $composableBuilder(
    column: $table.sceneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tensionLevel => $composableBuilder(
    column: $table.tensionLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChaptersTableOrderingComposer get chapterId {
    final $$ChaptersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableOrderingComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UniversesTableOrderingComposer get universeId {
    final $$UniversesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableOrderingComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableOrderingComposer get povCharacterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.povCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScenesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScenesTable> {
  $$ScenesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sceneNumber => $composableBuilder(
    column: $table.sceneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tensionLevel => $composableBuilder(
    column: $table.tensionLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ChaptersTableAnnotationComposer get chapterId {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UniversesTableAnnotationComposer get universeId {
    final $$UniversesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableAnnotationComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableAnnotationComposer get povCharacterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.povCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScenesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScenesTable,
          Scene,
          $$ScenesTableFilterComposer,
          $$ScenesTableOrderingComposer,
          $$ScenesTableAnnotationComposer,
          $$ScenesTableCreateCompanionBuilder,
          $$ScenesTableUpdateCompanionBuilder,
          (Scene, $$ScenesTableReferences),
          Scene,
          PrefetchHooks Function({
            bool chapterId,
            bool universeId,
            bool povCharacterId,
          })
        > {
  $$ScenesTableTableManager(_$AppDatabase db, $ScenesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScenesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScenesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScenesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> chapterId = const Value.absent(),
                Value<String> universeId = const Value.absent(),
                Value<int> sceneNumber = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String?> povCharacterId = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<int> tensionLevel = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScenesCompanion(
                id: id,
                chapterId: chapterId,
                universeId: universeId,
                sceneNumber: sceneNumber,
                title: title,
                summary: summary,
                povCharacterId: povCharacterId,
                locationName: locationName,
                tensionLevel: tensionLevel,
                status: status,
                orderIndex: orderIndex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String chapterId,
                required String universeId,
                required int sceneNumber,
                required String title,
                Value<String?> summary = const Value.absent(),
                Value<String?> povCharacterId = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<int> tensionLevel = const Value.absent(),
                Value<String> status = const Value.absent(),
                required int orderIndex,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ScenesCompanion.insert(
                id: id,
                chapterId: chapterId,
                universeId: universeId,
                sceneNumber: sceneNumber,
                title: title,
                summary: summary,
                povCharacterId: povCharacterId,
                locationName: locationName,
                tensionLevel: tensionLevel,
                status: status,
                orderIndex: orderIndex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScenesTable, Scene>(table),
                  $$ScenesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                chapterId = false,
                universeId = false,
                povCharacterId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
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
                          dynamic
                        >
                      >(state) {
                        if (chapterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.chapterId,
                                    referencedTable: $$ScenesTableReferences
                                        ._chapterIdTable(db),
                                    referencedColumn: $$ScenesTableReferences
                                        ._chapterIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (universeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.universeId,
                                    referencedTable: $$ScenesTableReferences
                                        ._universeIdTable(db),
                                    referencedColumn: $$ScenesTableReferences
                                        ._universeIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (povCharacterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.povCharacterId,
                                    referencedTable: $$ScenesTableReferences
                                        ._povCharacterIdTable(db),
                                    referencedColumn: $$ScenesTableReferences
                                        ._povCharacterIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ScenesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScenesTable,
      Scene,
      $$ScenesTableFilterComposer,
      $$ScenesTableOrderingComposer,
      $$ScenesTableAnnotationComposer,
      $$ScenesTableCreateCompanionBuilder,
      $$ScenesTableUpdateCompanionBuilder,
      (Scene, $$ScenesTableReferences),
      Scene,
      PrefetchHooks Function({
        bool chapterId,
        bool universeId,
        bool povCharacterId,
      })
    >;
typedef $$LoreEntriesTableCreateCompanionBuilder =
    LoreEntriesCompanion Function({
      required String id,
      required String universeId,
      required String title,
      required String category,
      Value<String?> summary,
      Value<String?> content,
      Value<String?> tags,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LoreEntriesTableUpdateCompanionBuilder =
    LoreEntriesCompanion Function({
      Value<String> id,
      Value<String> universeId,
      Value<String> title,
      Value<String> category,
      Value<String?> summary,
      Value<String?> content,
      Value<String?> tags,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$LoreEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $LoreEntriesTable, LoreEntry> {
  $$LoreEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UniversesTable _universeIdTable(_$AppDatabase db) =>
      db.universes.createAlias('lore_entries__universe_id__universes__id');

  $$UniversesTableProcessedTableManager get universeId {
    final $_column = $_itemColumn<String>('universe_id')!;

    final manager = $$UniversesTableTableManager(
      $_db,
      $_db.universes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_universeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LoreEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LoreEntriesTable> {
  $$LoreEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UniversesTableFilterComposer get universeId {
    final $$UniversesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableFilterComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoreEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LoreEntriesTable> {
  $$LoreEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UniversesTableOrderingComposer get universeId {
    final $$UniversesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableOrderingComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoreEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoreEntriesTable> {
  $$LoreEntriesTableAnnotationComposer({
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

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UniversesTableAnnotationComposer get universeId {
    final $$UniversesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableAnnotationComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoreEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoreEntriesTable,
          LoreEntry,
          $$LoreEntriesTableFilterComposer,
          $$LoreEntriesTableOrderingComposer,
          $$LoreEntriesTableAnnotationComposer,
          $$LoreEntriesTableCreateCompanionBuilder,
          $$LoreEntriesTableUpdateCompanionBuilder,
          (LoreEntry, $$LoreEntriesTableReferences),
          LoreEntry,
          PrefetchHooks Function({bool universeId})
        > {
  $$LoreEntriesTableTableManager(_$AppDatabase db, $LoreEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoreEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoreEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoreEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> universeId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoreEntriesCompanion(
                id: id,
                universeId: universeId,
                title: title,
                category: category,
                summary: summary,
                content: content,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String universeId,
                required String title,
                required String category,
                Value<String?> summary = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LoreEntriesCompanion.insert(
                id: id,
                universeId: universeId,
                title: title,
                category: category,
                summary: summary,
                content: content,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LoreEntriesTable, LoreEntry>(table),
                  $$LoreEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({universeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (universeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.universeId,
                                referencedTable: $$LoreEntriesTableReferences
                                    ._universeIdTable(db),
                                referencedColumn: $$LoreEntriesTableReferences
                                    ._universeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LoreEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoreEntriesTable,
      LoreEntry,
      $$LoreEntriesTableFilterComposer,
      $$LoreEntriesTableOrderingComposer,
      $$LoreEntriesTableAnnotationComposer,
      $$LoreEntriesTableCreateCompanionBuilder,
      $$LoreEntriesTableUpdateCompanionBuilder,
      (LoreEntry, $$LoreEntriesTableReferences),
      LoreEntry,
      PrefetchHooks Function({bool universeId})
    >;
typedef $$IdeaSparksTableCreateCompanionBuilder =
    IdeaSparksCompanion Function({
      required String id,
      required String universeId,
      required String content,
      Value<String> category,
      Value<bool> isPinned,
      Value<bool> isConverted,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$IdeaSparksTableUpdateCompanionBuilder =
    IdeaSparksCompanion Function({
      Value<String> id,
      Value<String> universeId,
      Value<String> content,
      Value<String> category,
      Value<bool> isPinned,
      Value<bool> isConverted,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$IdeaSparksTableReferences
    extends BaseReferences<_$AppDatabase, $IdeaSparksTable, IdeaSpark> {
  $$IdeaSparksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UniversesTable _universeIdTable(_$AppDatabase db) =>
      db.universes.createAlias('idea_sparks__universe_id__universes__id');

  $$UniversesTableProcessedTableManager get universeId {
    final $_column = $_itemColumn<String>('universe_id')!;

    final manager = $$UniversesTableTableManager(
      $_db,
      $_db.universes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_universeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IdeaSparksTableFilterComposer
    extends Composer<_$AppDatabase, $IdeaSparksTable> {
  $$IdeaSparksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isConverted => $composableBuilder(
    column: $table.isConverted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UniversesTableFilterComposer get universeId {
    final $$UniversesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableFilterComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IdeaSparksTableOrderingComposer
    extends Composer<_$AppDatabase, $IdeaSparksTable> {
  $$IdeaSparksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isConverted => $composableBuilder(
    column: $table.isConverted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UniversesTableOrderingComposer get universeId {
    final $$UniversesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableOrderingComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IdeaSparksTableAnnotationComposer
    extends Composer<_$AppDatabase, $IdeaSparksTable> {
  $$IdeaSparksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<bool> get isConverted => $composableBuilder(
    column: $table.isConverted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UniversesTableAnnotationComposer get universeId {
    final $$UniversesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.universeId,
      referencedTable: $db.universes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UniversesTableAnnotationComposer(
            $db: $db,
            $table: $db.universes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IdeaSparksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IdeaSparksTable,
          IdeaSpark,
          $$IdeaSparksTableFilterComposer,
          $$IdeaSparksTableOrderingComposer,
          $$IdeaSparksTableAnnotationComposer,
          $$IdeaSparksTableCreateCompanionBuilder,
          $$IdeaSparksTableUpdateCompanionBuilder,
          (IdeaSpark, $$IdeaSparksTableReferences),
          IdeaSpark,
          PrefetchHooks Function({bool universeId})
        > {
  $$IdeaSparksTableTableManager(_$AppDatabase db, $IdeaSparksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IdeaSparksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IdeaSparksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IdeaSparksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> universeId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isConverted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IdeaSparksCompanion(
                id: id,
                universeId: universeId,
                content: content,
                category: category,
                isPinned: isPinned,
                isConverted: isConverted,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String universeId,
                required String content,
                Value<String> category = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isConverted = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => IdeaSparksCompanion.insert(
                id: id,
                universeId: universeId,
                content: content,
                category: category,
                isPinned: isPinned,
                isConverted: isConverted,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IdeaSparksTable, IdeaSpark>(table),
                  $$IdeaSparksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({universeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (universeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.universeId,
                                referencedTable: $$IdeaSparksTableReferences
                                    ._universeIdTable(db),
                                referencedColumn: $$IdeaSparksTableReferences
                                    ._universeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IdeaSparksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IdeaSparksTable,
      IdeaSpark,
      $$IdeaSparksTableFilterComposer,
      $$IdeaSparksTableOrderingComposer,
      $$IdeaSparksTableAnnotationComposer,
      $$IdeaSparksTableCreateCompanionBuilder,
      $$IdeaSparksTableUpdateCompanionBuilder,
      (IdeaSpark, $$IdeaSparksTableReferences),
      IdeaSpark,
      PrefetchHooks Function({bool universeId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UniversesTableTableManager get universes =>
      $$UniversesTableTableManager(_db, _db.universes);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db, _db.characters);
  $$CharacterRelationshipsTableTableManager get characterRelationships =>
      $$CharacterRelationshipsTableTableManager(
        _db,
        _db.characterRelationships,
      );
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db, _db.chapters);
  $$ScenesTableTableManager get scenes =>
      $$ScenesTableTableManager(_db, _db.scenes);
  $$LoreEntriesTableTableManager get loreEntries =>
      $$LoreEntriesTableTableManager(_db, _db.loreEntries);
  $$IdeaSparksTableTableManager get ideaSparks =>
      $$IdeaSparksTableTableManager(_db, _db.ideaSparks);
}
