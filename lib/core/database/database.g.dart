// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LocalizationsOverridesTable extends LocalizationsOverrides
    with TableInfo<$LocalizationsOverridesTable, LocalizationsOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalizationsOverridesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stringKeyMeta = const VerificationMeta(
    'stringKey',
  );
  @override
  late final GeneratedColumn<String> stringKey = GeneratedColumn<String>(
    'string_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customValueMeta = const VerificationMeta(
    'customValue',
  );
  @override
  late final GeneratedColumn<String> customValue = GeneratedColumn<String>(
    'custom_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileName,
    stringKey,
    customValue,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'localizations_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalizationsOverride> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('string_key')) {
      context.handle(
        _stringKeyMeta,
        stringKey.isAcceptableOrUnknown(data['string_key']!, _stringKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_stringKeyMeta);
    }
    if (data.containsKey('custom_value')) {
      context.handle(
        _customValueMeta,
        customValue.isAcceptableOrUnknown(
          data['custom_value']!,
          _customValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customValueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {fileName, stringKey},
  ];
  @override
  LocalizationsOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalizationsOverride(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      stringKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}string_key'],
      )!,
      customValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalizationsOverridesTable createAlias(String alias) {
    return $LocalizationsOverridesTable(attachedDatabase, alias);
  }
}

class LocalizationsOverride extends DataClass
    implements Insertable<LocalizationsOverride> {
  final int id;
  final String fileName;
  final String stringKey;
  final String customValue;
  final DateTime updatedAt;
  const LocalizationsOverride({
    required this.id,
    required this.fileName,
    required this.stringKey,
    required this.customValue,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_name'] = Variable<String>(fileName);
    map['string_key'] = Variable<String>(stringKey);
    map['custom_value'] = Variable<String>(customValue);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalizationsOverridesCompanion toCompanion(bool nullToAbsent) {
    return LocalizationsOverridesCompanion(
      id: Value(id),
      fileName: Value(fileName),
      stringKey: Value(stringKey),
      customValue: Value(customValue),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalizationsOverride.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalizationsOverride(
      id: serializer.fromJson<int>(json['id']),
      fileName: serializer.fromJson<String>(json['fileName']),
      stringKey: serializer.fromJson<String>(json['stringKey']),
      customValue: serializer.fromJson<String>(json['customValue']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fileName': serializer.toJson<String>(fileName),
      'stringKey': serializer.toJson<String>(stringKey),
      'customValue': serializer.toJson<String>(customValue),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalizationsOverride copyWith({
    int? id,
    String? fileName,
    String? stringKey,
    String? customValue,
    DateTime? updatedAt,
  }) => LocalizationsOverride(
    id: id ?? this.id,
    fileName: fileName ?? this.fileName,
    stringKey: stringKey ?? this.stringKey,
    customValue: customValue ?? this.customValue,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalizationsOverride copyWithCompanion(
    LocalizationsOverridesCompanion data,
  ) {
    return LocalizationsOverride(
      id: data.id.present ? data.id.value : this.id,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      stringKey: data.stringKey.present ? data.stringKey.value : this.stringKey,
      customValue: data.customValue.present
          ? data.customValue.value
          : this.customValue,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalizationsOverride(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('stringKey: $stringKey, ')
          ..write('customValue: $customValue, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fileName, stringKey, customValue, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalizationsOverride &&
          other.id == this.id &&
          other.fileName == this.fileName &&
          other.stringKey == this.stringKey &&
          other.customValue == this.customValue &&
          other.updatedAt == this.updatedAt);
}

class LocalizationsOverridesCompanion
    extends UpdateCompanion<LocalizationsOverride> {
  final Value<int> id;
  final Value<String> fileName;
  final Value<String> stringKey;
  final Value<String> customValue;
  final Value<DateTime> updatedAt;
  const LocalizationsOverridesCompanion({
    this.id = const Value.absent(),
    this.fileName = const Value.absent(),
    this.stringKey = const Value.absent(),
    this.customValue = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalizationsOverridesCompanion.insert({
    this.id = const Value.absent(),
    required String fileName,
    required String stringKey,
    required String customValue,
    this.updatedAt = const Value.absent(),
  }) : fileName = Value(fileName),
       stringKey = Value(stringKey),
       customValue = Value(customValue);
  static Insertable<LocalizationsOverride> custom({
    Expression<int>? id,
    Expression<String>? fileName,
    Expression<String>? stringKey,
    Expression<String>? customValue,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileName != null) 'file_name': fileName,
      if (stringKey != null) 'string_key': stringKey,
      if (customValue != null) 'custom_value': customValue,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalizationsOverridesCompanion copyWith({
    Value<int>? id,
    Value<String>? fileName,
    Value<String>? stringKey,
    Value<String>? customValue,
    Value<DateTime>? updatedAt,
  }) {
    return LocalizationsOverridesCompanion(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      stringKey: stringKey ?? this.stringKey,
      customValue: customValue ?? this.customValue,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (stringKey.present) {
      map['string_key'] = Variable<String>(stringKey.value);
    }
    if (customValue.present) {
      map['custom_value'] = Variable<String>(customValue.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalizationsOverridesCompanion(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('stringKey: $stringKey, ')
          ..write('customValue: $customValue, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalizationsOverridesTable localizationsOverrides =
      $LocalizationsOverridesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [localizationsOverrides];
}

typedef $$LocalizationsOverridesTableCreateCompanionBuilder =
    LocalizationsOverridesCompanion Function({
      Value<int> id,
      required String fileName,
      required String stringKey,
      required String customValue,
      Value<DateTime> updatedAt,
    });
typedef $$LocalizationsOverridesTableUpdateCompanionBuilder =
    LocalizationsOverridesCompanion Function({
      Value<int> id,
      Value<String> fileName,
      Value<String> stringKey,
      Value<String> customValue,
      Value<DateTime> updatedAt,
    });

class $$LocalizationsOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalizationsOverridesTable> {
  $$LocalizationsOverridesTableFilterComposer({
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

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stringKey => $composableBuilder(
    column: $table.stringKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customValue => $composableBuilder(
    column: $table.customValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalizationsOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalizationsOverridesTable> {
  $$LocalizationsOverridesTableOrderingComposer({
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

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stringKey => $composableBuilder(
    column: $table.stringKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customValue => $composableBuilder(
    column: $table.customValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalizationsOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalizationsOverridesTable> {
  $$LocalizationsOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get stringKey =>
      $composableBuilder(column: $table.stringKey, builder: (column) => column);

  GeneratedColumn<String> get customValue => $composableBuilder(
    column: $table.customValue,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalizationsOverridesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalizationsOverridesTable,
          LocalizationsOverride,
          $$LocalizationsOverridesTableFilterComposer,
          $$LocalizationsOverridesTableOrderingComposer,
          $$LocalizationsOverridesTableAnnotationComposer,
          $$LocalizationsOverridesTableCreateCompanionBuilder,
          $$LocalizationsOverridesTableUpdateCompanionBuilder,
          (
            LocalizationsOverride,
            BaseReferences<
              _$AppDatabase,
              $LocalizationsOverridesTable,
              LocalizationsOverride
            >,
          ),
          LocalizationsOverride,
          PrefetchHooks Function()
        > {
  $$LocalizationsOverridesTableTableManager(
    _$AppDatabase db,
    $LocalizationsOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalizationsOverridesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalizationsOverridesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalizationsOverridesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> stringKey = const Value.absent(),
                Value<String> customValue = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalizationsOverridesCompanion(
                id: id,
                fileName: fileName,
                stringKey: stringKey,
                customValue: customValue,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String fileName,
                required String stringKey,
                required String customValue,
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalizationsOverridesCompanion.insert(
                id: id,
                fileName: fileName,
                stringKey: stringKey,
                customValue: customValue,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalizationsOverridesTable,
                    LocalizationsOverride
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalizationsOverridesTable,
                    LocalizationsOverride
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalizationsOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalizationsOverridesTable,
      LocalizationsOverride,
      $$LocalizationsOverridesTableFilterComposer,
      $$LocalizationsOverridesTableOrderingComposer,
      $$LocalizationsOverridesTableAnnotationComposer,
      $$LocalizationsOverridesTableCreateCompanionBuilder,
      $$LocalizationsOverridesTableUpdateCompanionBuilder,
      (
        LocalizationsOverride,
        BaseReferences<
          _$AppDatabase,
          $LocalizationsOverridesTable,
          LocalizationsOverride
        >,
      ),
      LocalizationsOverride,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalizationsOverridesTableTableManager get localizationsOverrides =>
      $$LocalizationsOverridesTableTableManager(
        _db,
        _db.localizationsOverrides,
      );
}
