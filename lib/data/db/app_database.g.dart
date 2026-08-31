// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SpikeRowsTable extends SpikeRows
    with TableInfo<$SpikeRowsTable, SpikeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpikeRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 128,
    ),
    type: DriftSqlType.string,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, label, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'spike_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SpikeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SpikeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpikeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SpikeRowsTable createAlias(String alias) {
    return $SpikeRowsTable(attachedDatabase, alias);
  }
}

class SpikeRow extends DataClass implements Insertable<SpikeRow> {
  final int id;
  final String label;
  final DateTime createdAt;
  const SpikeRow({
    required this.id,
    required this.label,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['label'] = Variable<String>(label);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SpikeRowsCompanion toCompanion(bool nullToAbsent) {
    return SpikeRowsCompanion(
      id: Value(id),
      label: Value(label),
      createdAt: Value(createdAt),
    );
  }

  factory SpikeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpikeRow(
      id: serializer.fromJson<int>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'label': serializer.toJson<String>(label),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SpikeRow copyWith({int? id, String? label, DateTime? createdAt}) => SpikeRow(
    id: id ?? this.id,
    label: label ?? this.label,
    createdAt: createdAt ?? this.createdAt,
  );
  SpikeRow copyWithCompanion(SpikeRowsCompanion data) {
    return SpikeRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpikeRow(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpikeRow &&
          other.id == this.id &&
          other.label == this.label &&
          other.createdAt == this.createdAt);
}

class SpikeRowsCompanion extends UpdateCompanion<SpikeRow> {
  final Value<int> id;
  final Value<String> label;
  final Value<DateTime> createdAt;
  const SpikeRowsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SpikeRowsCompanion.insert({
    this.id = const Value.absent(),
    required String label,
    this.createdAt = const Value.absent(),
  }) : label = Value(label);
  static Insertable<SpikeRow> custom({
    Expression<int>? id,
    Expression<String>? label,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SpikeRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? label,
    Value<DateTime>? createdAt,
  }) {
    return SpikeRowsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpikeRowsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SpikeRowsTable spikeRows = $SpikeRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [spikeRows];
}

typedef $$SpikeRowsTableCreateCompanionBuilder =
    SpikeRowsCompanion Function({
      Value<int> id,
      required String label,
      Value<DateTime> createdAt,
    });
typedef $$SpikeRowsTableUpdateCompanionBuilder =
    SpikeRowsCompanion Function({
      Value<int> id,
      Value<String> label,
      Value<DateTime> createdAt,
    });

class $$SpikeRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SpikeRowsTable> {
  $$SpikeRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SpikeRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SpikeRowsTable> {
  $$SpikeRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SpikeRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SpikeRowsTable> {
  $$SpikeRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SpikeRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SpikeRowsTable,
          SpikeRow,
          $$SpikeRowsTableFilterComposer,
          $$SpikeRowsTableOrderingComposer,
          $$SpikeRowsTableAnnotationComposer,
          $$SpikeRowsTableCreateCompanionBuilder,
          $$SpikeRowsTableUpdateCompanionBuilder,
          (SpikeRow, BaseReferences<_$AppDatabase, $SpikeRowsTable, SpikeRow>),
          SpikeRow,
          PrefetchHooks Function()
        > {
  $$SpikeRowsTableTableManager(_$AppDatabase db, $SpikeRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpikeRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpikeRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpikeRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SpikeRowsCompanion(
                id: id,
                label: label,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String label,
                Value<DateTime> createdAt = const Value.absent(),
              }) => SpikeRowsCompanion.insert(
                id: id,
                label: label,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SpikeRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SpikeRowsTable,
      SpikeRow,
      $$SpikeRowsTableFilterComposer,
      $$SpikeRowsTableOrderingComposer,
      $$SpikeRowsTableAnnotationComposer,
      $$SpikeRowsTableCreateCompanionBuilder,
      $$SpikeRowsTableUpdateCompanionBuilder,
      (SpikeRow, BaseReferences<_$AppDatabase, $SpikeRowsTable, SpikeRow>),
      SpikeRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SpikeRowsTableTableManager get spikeRows =>
      $$SpikeRowsTableTableManager(_db, _db.spikeRows);
}
