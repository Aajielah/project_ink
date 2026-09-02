// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'target_change_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTargetChangeLogCollection on Isar {
  IsarCollection<TargetChangeLog> get targetChangeLogs => this.collection();
}

const TargetChangeLogSchema = CollectionSchema(
  name: r'TargetChangeLog',
  id: -5708067075848652902,
  properties: {
    r'dateChanged': PropertySchema(
      id: 0,
      name: r'dateChanged',
      type: IsarType.dateTime,
    ),
    r'newTarget': PropertySchema(
      id: 1,
      name: r'newTarget',
      type: IsarType.long,
    ),
    r'oldTarget': PropertySchema(
      id: 2,
      name: r'oldTarget',
      type: IsarType.long,
    ),
    r'projectId': PropertySchema(
      id: 3,
      name: r'projectId',
      type: IsarType.long,
    )
  },
  estimateSize: _targetChangeLogEstimateSize,
  serialize: _targetChangeLogSerialize,
  deserialize: _targetChangeLogDeserialize,
  deserializeProp: _targetChangeLogDeserializeProp,
  idName: r'id',
  indexes: {
    r'projectId': IndexSchema(
      id: 3305656282123791113,
      name: r'projectId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'projectId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _targetChangeLogGetId,
  getLinks: _targetChangeLogGetLinks,
  attach: _targetChangeLogAttach,
  version: '3.1.0+1',
);

int _targetChangeLogEstimateSize(
  TargetChangeLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _targetChangeLogSerialize(
  TargetChangeLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.dateChanged);
  writer.writeLong(offsets[1], object.newTarget);
  writer.writeLong(offsets[2], object.oldTarget);
  writer.writeLong(offsets[3], object.projectId);
}

TargetChangeLog _targetChangeLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TargetChangeLog();
  object.dateChanged = reader.readDateTime(offsets[0]);
  object.id = id;
  object.newTarget = reader.readLong(offsets[1]);
  object.oldTarget = reader.readLong(offsets[2]);
  object.projectId = reader.readLong(offsets[3]);
  return object;
}

P _targetChangeLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _targetChangeLogGetId(TargetChangeLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _targetChangeLogGetLinks(TargetChangeLog object) {
  return [];
}

void _targetChangeLogAttach(
    IsarCollection<dynamic> col, Id id, TargetChangeLog object) {
  object.id = id;
}

extension TargetChangeLogQueryWhereSort
    on QueryBuilder<TargetChangeLog, TargetChangeLog, QWhere> {
  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterWhere> anyProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'projectId'),
      );
    });
  }
}

extension TargetChangeLogQueryWhere
    on QueryBuilder<TargetChangeLog, TargetChangeLog, QWhereClause> {
  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterWhereClause>
      projectIdEqualTo(int projectId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'projectId',
        value: [projectId],
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterWhereClause>
      projectIdNotEqualTo(int projectId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [],
              upper: [projectId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [projectId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [projectId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [],
              upper: [projectId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterWhereClause>
      projectIdGreaterThan(
    int projectId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'projectId',
        lower: [projectId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterWhereClause>
      projectIdLessThan(
    int projectId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'projectId',
        lower: [],
        upper: [projectId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterWhereClause>
      projectIdBetween(
    int lowerProjectId,
    int upperProjectId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'projectId',
        lower: [lowerProjectId],
        includeLower: includeLower,
        upper: [upperProjectId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TargetChangeLogQueryFilter
    on QueryBuilder<TargetChangeLog, TargetChangeLog, QFilterCondition> {
  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      dateChangedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateChanged',
        value: value,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      dateChangedGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateChanged',
        value: value,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      dateChangedLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateChanged',
        value: value,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      dateChangedBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateChanged',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      newTargetEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'newTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      newTargetGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'newTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      newTargetLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'newTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      newTargetBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'newTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      oldTargetEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'oldTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      oldTargetGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'oldTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      oldTargetLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'oldTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      oldTargetBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'oldTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      projectIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectId',
        value: value,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      projectIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'projectId',
        value: value,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      projectIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'projectId',
        value: value,
      ));
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterFilterCondition>
      projectIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'projectId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TargetChangeLogQueryObject
    on QueryBuilder<TargetChangeLog, TargetChangeLog, QFilterCondition> {}

extension TargetChangeLogQueryLinks
    on QueryBuilder<TargetChangeLog, TargetChangeLog, QFilterCondition> {}

extension TargetChangeLogQuerySortBy
    on QueryBuilder<TargetChangeLog, TargetChangeLog, QSortBy> {
  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy>
      sortByDateChanged() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateChanged', Sort.asc);
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy>
      sortByDateChangedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateChanged', Sort.desc);
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy>
      sortByNewTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newTarget', Sort.asc);
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy>
      sortByNewTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newTarget', Sort.desc);
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy>
      sortByOldTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'oldTarget', Sort.asc);
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy>
      sortByOldTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'oldTarget', Sort.desc);
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy>
      sortByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.asc);
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy>
      sortByProjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.desc);
    });
  }
}

extension TargetChangeLogQuerySortThenBy
    on QueryBuilder<TargetChangeLog, TargetChangeLog, QSortThenBy> {
  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy>
      thenByDateChanged() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateChanged', Sort.asc);
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy>
      thenByDateChangedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateChanged', Sort.desc);
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy>
      thenByNewTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newTarget', Sort.asc);
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy>
      thenByNewTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newTarget', Sort.desc);
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy>
      thenByOldTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'oldTarget', Sort.asc);
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy>
      thenByOldTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'oldTarget', Sort.desc);
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy>
      thenByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.asc);
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QAfterSortBy>
      thenByProjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.desc);
    });
  }
}

extension TargetChangeLogQueryWhereDistinct
    on QueryBuilder<TargetChangeLog, TargetChangeLog, QDistinct> {
  QueryBuilder<TargetChangeLog, TargetChangeLog, QDistinct>
      distinctByDateChanged() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateChanged');
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QDistinct>
      distinctByNewTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'newTarget');
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QDistinct>
      distinctByOldTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'oldTarget');
    });
  }

  QueryBuilder<TargetChangeLog, TargetChangeLog, QDistinct>
      distinctByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'projectId');
    });
  }
}

extension TargetChangeLogQueryProperty
    on QueryBuilder<TargetChangeLog, TargetChangeLog, QQueryProperty> {
  QueryBuilder<TargetChangeLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TargetChangeLog, DateTime, QQueryOperations>
      dateChangedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateChanged');
    });
  }

  QueryBuilder<TargetChangeLog, int, QQueryOperations> newTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'newTarget');
    });
  }

  QueryBuilder<TargetChangeLog, int, QQueryOperations> oldTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'oldTarget');
    });
  }

  QueryBuilder<TargetChangeLog, int, QQueryOperations> projectIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectId');
    });
  }
}
