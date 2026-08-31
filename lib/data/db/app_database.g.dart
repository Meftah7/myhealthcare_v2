// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DepartmentsTable extends Departments
    with TableInfo<$DepartmentsTable, DepartmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DepartmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
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
  @override
  List<GeneratedColumn> get $columns => [id, name, description];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'departments';
  @override
  VerificationContext validateIntegrity(
    Insertable<DepartmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DepartmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DepartmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
    );
  }

  @override
  $DepartmentsTable createAlias(String alias) {
    return $DepartmentsTable(attachedDatabase, alias);
  }
}

class DepartmentRow extends DataClass implements Insertable<DepartmentRow> {
  final String id;
  final String name;
  final String? description;
  const DepartmentRow({required this.id, required this.name, this.description});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  DepartmentsCompanion toCompanion(bool nullToAbsent) {
    return DepartmentsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory DepartmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DepartmentRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
    };
  }

  DepartmentRow copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
  }) => DepartmentRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
  );
  DepartmentRow copyWithCompanion(DepartmentsCompanion data) {
    return DepartmentRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DepartmentRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DepartmentRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description);
}

class DepartmentsCompanion extends UpdateCompanion<DepartmentRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> rowid;
  const DepartmentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DepartmentsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<DepartmentRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DepartmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? rowid,
  }) {
    return DepartmentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DepartmentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, UserRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<UserRole, String> role =
      GeneratedColumn<String>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<UserRole>($UsersTable.$converterrole);
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 160,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 254,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordSaltMeta = const VerificationMeta(
    'passwordSalt',
  );
  @override
  late final GeneratedColumn<String> passwordSalt = GeneratedColumn<String>(
    'password_salt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dobMeta = const VerificationMeta('dob');
  @override
  late final GeneratedColumn<DateTime> dob = GeneratedColumn<DateTime>(
    'dob',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Gender?, String> gender =
      GeneratedColumn<String>(
        'gender',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Gender?>($UsersTable.$convertergendern);
  static const VerificationMeta _nationalIdMeta = const VerificationMeta(
    'nationalId',
  );
  @override
  late final GeneratedColumn<String> nationalId = GeneratedColumn<String>(
    'national_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  List<GeneratedColumn> get $columns => [
    id,
    role,
    fullName,
    email,
    passwordHash,
    passwordSalt,
    phone,
    dob,
    gender,
    nationalId,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('password_salt')) {
      context.handle(
        _passwordSaltMeta,
        passwordSalt.isAcceptableOrUnknown(
          data['password_salt']!,
          _passwordSaltMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordSaltMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('dob')) {
      context.handle(
        _dobMeta,
        dob.isAcceptableOrUnknown(data['dob']!, _dobMeta),
      );
    }
    if (data.containsKey('national_id')) {
      context.handle(
        _nationalIdMeta,
        nationalId.isAcceptableOrUnknown(data['national_id']!, _nationalIdMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
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
  UserRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      role: $UsersTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}role'],
        )!,
      ),
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      passwordSalt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_salt'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      dob: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dob'],
      ),
      gender: $UsersTable.$convertergendern.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}gender'],
        ),
      ),
      nationalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}national_id'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<UserRole, String, String> $converterrole =
      const EnumNameConverter<UserRole>(UserRole.values);
  static JsonTypeConverter2<Gender, String, String> $convertergender =
      const EnumNameConverter<Gender>(Gender.values);
  static JsonTypeConverter2<Gender?, String?, String?> $convertergendern =
      JsonTypeConverter2.asNullable($convertergender);
}

class UserRow extends DataClass implements Insertable<UserRow> {
  final String id;
  final UserRole role;
  final String fullName;
  final String email;
  final String passwordHash;
  final String passwordSalt;
  final String? phone;
  final DateTime? dob;
  final Gender? gender;
  final String? nationalId;
  final bool isActive;
  final DateTime createdAt;
  const UserRow({
    required this.id,
    required this.role,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
    this.phone,
    this.dob,
    this.gender,
    this.nationalId,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['role'] = Variable<String>($UsersTable.$converterrole.toSql(role));
    }
    map['full_name'] = Variable<String>(fullName);
    map['email'] = Variable<String>(email);
    map['password_hash'] = Variable<String>(passwordHash);
    map['password_salt'] = Variable<String>(passwordSalt);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || dob != null) {
      map['dob'] = Variable<DateTime>(dob);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(
        $UsersTable.$convertergendern.toSql(gender),
      );
    }
    if (!nullToAbsent || nationalId != null) {
      map['national_id'] = Variable<String>(nationalId);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      role: Value(role),
      fullName: Value(fullName),
      email: Value(email),
      passwordHash: Value(passwordHash),
      passwordSalt: Value(passwordSalt),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      dob: dob == null && nullToAbsent ? const Value.absent() : Value(dob),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      nationalId: nationalId == null && nullToAbsent
          ? const Value.absent()
          : Value(nationalId),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory UserRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRow(
      id: serializer.fromJson<String>(json['id']),
      role: $UsersTable.$converterrole.fromJson(
        serializer.fromJson<String>(json['role']),
      ),
      fullName: serializer.fromJson<String>(json['fullName']),
      email: serializer.fromJson<String>(json['email']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      passwordSalt: serializer.fromJson<String>(json['passwordSalt']),
      phone: serializer.fromJson<String?>(json['phone']),
      dob: serializer.fromJson<DateTime?>(json['dob']),
      gender: $UsersTable.$convertergendern.fromJson(
        serializer.fromJson<String?>(json['gender']),
      ),
      nationalId: serializer.fromJson<String?>(json['nationalId']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'role': serializer.toJson<String>(
        $UsersTable.$converterrole.toJson(role),
      ),
      'fullName': serializer.toJson<String>(fullName),
      'email': serializer.toJson<String>(email),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'passwordSalt': serializer.toJson<String>(passwordSalt),
      'phone': serializer.toJson<String?>(phone),
      'dob': serializer.toJson<DateTime?>(dob),
      'gender': serializer.toJson<String?>(
        $UsersTable.$convertergendern.toJson(gender),
      ),
      'nationalId': serializer.toJson<String?>(nationalId),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserRow copyWith({
    String? id,
    UserRole? role,
    String? fullName,
    String? email,
    String? passwordHash,
    String? passwordSalt,
    Value<String?> phone = const Value.absent(),
    Value<DateTime?> dob = const Value.absent(),
    Value<Gender?> gender = const Value.absent(),
    Value<String?> nationalId = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
  }) => UserRow(
    id: id ?? this.id,
    role: role ?? this.role,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    passwordHash: passwordHash ?? this.passwordHash,
    passwordSalt: passwordSalt ?? this.passwordSalt,
    phone: phone.present ? phone.value : this.phone,
    dob: dob.present ? dob.value : this.dob,
    gender: gender.present ? gender.value : this.gender,
    nationalId: nationalId.present ? nationalId.value : this.nationalId,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  UserRow copyWithCompanion(UsersCompanion data) {
    return UserRow(
      id: data.id.present ? data.id.value : this.id,
      role: data.role.present ? data.role.value : this.role,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      email: data.email.present ? data.email.value : this.email,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      passwordSalt: data.passwordSalt.present
          ? data.passwordSalt.value
          : this.passwordSalt,
      phone: data.phone.present ? data.phone.value : this.phone,
      dob: data.dob.present ? data.dob.value : this.dob,
      gender: data.gender.present ? data.gender.value : this.gender,
      nationalId: data.nationalId.present
          ? data.nationalId.value
          : this.nationalId,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRow(')
          ..write('id: $id, ')
          ..write('role: $role, ')
          ..write('fullName: $fullName, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('passwordSalt: $passwordSalt, ')
          ..write('phone: $phone, ')
          ..write('dob: $dob, ')
          ..write('gender: $gender, ')
          ..write('nationalId: $nationalId, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    role,
    fullName,
    email,
    passwordHash,
    passwordSalt,
    phone,
    dob,
    gender,
    nationalId,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRow &&
          other.id == this.id &&
          other.role == this.role &&
          other.fullName == this.fullName &&
          other.email == this.email &&
          other.passwordHash == this.passwordHash &&
          other.passwordSalt == this.passwordSalt &&
          other.phone == this.phone &&
          other.dob == this.dob &&
          other.gender == this.gender &&
          other.nationalId == this.nationalId &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class UsersCompanion extends UpdateCompanion<UserRow> {
  final Value<String> id;
  final Value<UserRole> role;
  final Value<String> fullName;
  final Value<String> email;
  final Value<String> passwordHash;
  final Value<String> passwordSalt;
  final Value<String?> phone;
  final Value<DateTime?> dob;
  final Value<Gender?> gender;
  final Value<String?> nationalId;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.role = const Value.absent(),
    this.fullName = const Value.absent(),
    this.email = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.passwordSalt = const Value.absent(),
    this.phone = const Value.absent(),
    this.dob = const Value.absent(),
    this.gender = const Value.absent(),
    this.nationalId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required UserRole role,
    required String fullName,
    required String email,
    required String passwordHash,
    required String passwordSalt,
    this.phone = const Value.absent(),
    this.dob = const Value.absent(),
    this.gender = const Value.absent(),
    this.nationalId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       role = Value(role),
       fullName = Value(fullName),
       email = Value(email),
       passwordHash = Value(passwordHash),
       passwordSalt = Value(passwordSalt);
  static Insertable<UserRow> custom({
    Expression<String>? id,
    Expression<String>? role,
    Expression<String>? fullName,
    Expression<String>? email,
    Expression<String>? passwordHash,
    Expression<String>? passwordSalt,
    Expression<String>? phone,
    Expression<DateTime>? dob,
    Expression<String>? gender,
    Expression<String>? nationalId,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (role != null) 'role': role,
      if (fullName != null) 'full_name': fullName,
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (passwordSalt != null) 'password_salt': passwordSalt,
      if (phone != null) 'phone': phone,
      if (dob != null) 'dob': dob,
      if (gender != null) 'gender': gender,
      if (nationalId != null) 'national_id': nationalId,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<UserRole>? role,
    Value<String>? fullName,
    Value<String>? email,
    Value<String>? passwordHash,
    Value<String>? passwordSalt,
    Value<String?>? phone,
    Value<DateTime?>? dob,
    Value<Gender?>? gender,
    Value<String?>? nationalId,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      nationalId: nationalId ?? this.nationalId,
      isActive: isActive ?? this.isActive,
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
    if (role.present) {
      map['role'] = Variable<String>(
        $UsersTable.$converterrole.toSql(role.value),
      );
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (passwordSalt.present) {
      map['password_salt'] = Variable<String>(passwordSalt.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (dob.present) {
      map['dob'] = Variable<DateTime>(dob.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(
        $UsersTable.$convertergendern.toSql(gender.value),
      );
    }
    if (nationalId.present) {
      map['national_id'] = Variable<String>(nationalId.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
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
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('role: $role, ')
          ..write('fullName: $fullName, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('passwordSalt: $passwordSalt, ')
          ..write('phone: $phone, ')
          ..write('dob: $dob, ')
          ..write('gender: $gender, ')
          ..write('nationalId: $nationalId, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PatientProfilesTable extends PatientProfiles
    with TableInfo<$PatientProfilesTable, PatientProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatientProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _bloodTypeMeta = const VerificationMeta(
    'bloodType',
  );
  @override
  late final GeneratedColumn<String> bloodType = GeneratedColumn<String>(
    'blood_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> allergies =
      GeneratedColumn<String>(
        'allergies',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($PatientProfilesTable.$converterallergies);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  chronicConditions =
      GeneratedColumn<String>(
        'chronic_conditions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>(
        $PatientProfilesTable.$converterchronicConditions,
      );
  static const VerificationMeta _emergencyContactMeta = const VerificationMeta(
    'emergencyContact',
  );
  @override
  late final GeneratedColumn<String> emergencyContact = GeneratedColumn<String>(
    'emergency_contact',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    bloodType,
    allergies,
    chronicConditions,
    emergencyContact,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patient_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<PatientProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('blood_type')) {
      context.handle(
        _bloodTypeMeta,
        bloodType.isAcceptableOrUnknown(data['blood_type']!, _bloodTypeMeta),
      );
    }
    if (data.containsKey('emergency_contact')) {
      context.handle(
        _emergencyContactMeta,
        emergencyContact.isAcceptableOrUnknown(
          data['emergency_contact']!,
          _emergencyContactMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  PatientProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PatientProfileRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      bloodType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blood_type'],
      ),
      allergies: $PatientProfilesTable.$converterallergies.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}allergies'],
        )!,
      ),
      chronicConditions: $PatientProfilesTable.$converterchronicConditions
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}chronic_conditions'],
            )!,
          ),
      emergencyContact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emergency_contact'],
      ),
    );
  }

  @override
  $PatientProfilesTable createAlias(String alias) {
    return $PatientProfilesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterallergies =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterchronicConditions =
      const StringListConverter();
}

class PatientProfileRow extends DataClass
    implements Insertable<PatientProfileRow> {
  final String userId;
  final String? bloodType;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String? emergencyContact;
  const PatientProfileRow({
    required this.userId,
    this.bloodType,
    required this.allergies,
    required this.chronicConditions,
    this.emergencyContact,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || bloodType != null) {
      map['blood_type'] = Variable<String>(bloodType);
    }
    {
      map['allergies'] = Variable<String>(
        $PatientProfilesTable.$converterallergies.toSql(allergies),
      );
    }
    {
      map['chronic_conditions'] = Variable<String>(
        $PatientProfilesTable.$converterchronicConditions.toSql(
          chronicConditions,
        ),
      );
    }
    if (!nullToAbsent || emergencyContact != null) {
      map['emergency_contact'] = Variable<String>(emergencyContact);
    }
    return map;
  }

  PatientProfilesCompanion toCompanion(bool nullToAbsent) {
    return PatientProfilesCompanion(
      userId: Value(userId),
      bloodType: bloodType == null && nullToAbsent
          ? const Value.absent()
          : Value(bloodType),
      allergies: Value(allergies),
      chronicConditions: Value(chronicConditions),
      emergencyContact: emergencyContact == null && nullToAbsent
          ? const Value.absent()
          : Value(emergencyContact),
    );
  }

  factory PatientProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PatientProfileRow(
      userId: serializer.fromJson<String>(json['userId']),
      bloodType: serializer.fromJson<String?>(json['bloodType']),
      allergies: serializer.fromJson<List<String>>(json['allergies']),
      chronicConditions: serializer.fromJson<List<String>>(
        json['chronicConditions'],
      ),
      emergencyContact: serializer.fromJson<String?>(json['emergencyContact']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'bloodType': serializer.toJson<String?>(bloodType),
      'allergies': serializer.toJson<List<String>>(allergies),
      'chronicConditions': serializer.toJson<List<String>>(chronicConditions),
      'emergencyContact': serializer.toJson<String?>(emergencyContact),
    };
  }

  PatientProfileRow copyWith({
    String? userId,
    Value<String?> bloodType = const Value.absent(),
    List<String>? allergies,
    List<String>? chronicConditions,
    Value<String?> emergencyContact = const Value.absent(),
  }) => PatientProfileRow(
    userId: userId ?? this.userId,
    bloodType: bloodType.present ? bloodType.value : this.bloodType,
    allergies: allergies ?? this.allergies,
    chronicConditions: chronicConditions ?? this.chronicConditions,
    emergencyContact: emergencyContact.present
        ? emergencyContact.value
        : this.emergencyContact,
  );
  PatientProfileRow copyWithCompanion(PatientProfilesCompanion data) {
    return PatientProfileRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      bloodType: data.bloodType.present ? data.bloodType.value : this.bloodType,
      allergies: data.allergies.present ? data.allergies.value : this.allergies,
      chronicConditions: data.chronicConditions.present
          ? data.chronicConditions.value
          : this.chronicConditions,
      emergencyContact: data.emergencyContact.present
          ? data.emergencyContact.value
          : this.emergencyContact,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PatientProfileRow(')
          ..write('userId: $userId, ')
          ..write('bloodType: $bloodType, ')
          ..write('allergies: $allergies, ')
          ..write('chronicConditions: $chronicConditions, ')
          ..write('emergencyContact: $emergencyContact')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    bloodType,
    allergies,
    chronicConditions,
    emergencyContact,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PatientProfileRow &&
          other.userId == this.userId &&
          other.bloodType == this.bloodType &&
          other.allergies == this.allergies &&
          other.chronicConditions == this.chronicConditions &&
          other.emergencyContact == this.emergencyContact);
}

class PatientProfilesCompanion extends UpdateCompanion<PatientProfileRow> {
  final Value<String> userId;
  final Value<String?> bloodType;
  final Value<List<String>> allergies;
  final Value<List<String>> chronicConditions;
  final Value<String?> emergencyContact;
  final Value<int> rowid;
  const PatientProfilesCompanion({
    this.userId = const Value.absent(),
    this.bloodType = const Value.absent(),
    this.allergies = const Value.absent(),
    this.chronicConditions = const Value.absent(),
    this.emergencyContact = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatientProfilesCompanion.insert({
    required String userId,
    this.bloodType = const Value.absent(),
    this.allergies = const Value.absent(),
    this.chronicConditions = const Value.absent(),
    this.emergencyContact = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<PatientProfileRow> custom({
    Expression<String>? userId,
    Expression<String>? bloodType,
    Expression<String>? allergies,
    Expression<String>? chronicConditions,
    Expression<String>? emergencyContact,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (bloodType != null) 'blood_type': bloodType,
      if (allergies != null) 'allergies': allergies,
      if (chronicConditions != null) 'chronic_conditions': chronicConditions,
      if (emergencyContact != null) 'emergency_contact': emergencyContact,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatientProfilesCompanion copyWith({
    Value<String>? userId,
    Value<String?>? bloodType,
    Value<List<String>>? allergies,
    Value<List<String>>? chronicConditions,
    Value<String?>? emergencyContact,
    Value<int>? rowid,
  }) {
    return PatientProfilesCompanion(
      userId: userId ?? this.userId,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (bloodType.present) {
      map['blood_type'] = Variable<String>(bloodType.value);
    }
    if (allergies.present) {
      map['allergies'] = Variable<String>(
        $PatientProfilesTable.$converterallergies.toSql(allergies.value),
      );
    }
    if (chronicConditions.present) {
      map['chronic_conditions'] = Variable<String>(
        $PatientProfilesTable.$converterchronicConditions.toSql(
          chronicConditions.value,
        ),
      );
    }
    if (emergencyContact.present) {
      map['emergency_contact'] = Variable<String>(emergencyContact.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatientProfilesCompanion(')
          ..write('userId: $userId, ')
          ..write('bloodType: $bloodType, ')
          ..write('allergies: $allergies, ')
          ..write('chronicConditions: $chronicConditions, ')
          ..write('emergencyContact: $emergencyContact, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StaffProfilesTable extends StaffProfiles
    with TableInfo<$StaffProfilesTable, StaffProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StaffProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _specialtyMeta = const VerificationMeta(
    'specialty',
  );
  @override
  late final GeneratedColumn<String> specialty = GeneratedColumn<String>(
    'specialty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _departmentIdMeta = const VerificationMeta(
    'departmentId',
  );
  @override
  late final GeneratedColumn<String> departmentId = GeneratedColumn<String>(
    'department_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES departments (id)',
    ),
  );
  static const VerificationMeta _licenseNoMeta = const VerificationMeta(
    'licenseNo',
  );
  @override
  late final GeneratedColumn<String> licenseNo = GeneratedColumn<String>(
    'license_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jobTitleMeta = const VerificationMeta(
    'jobTitle',
  );
  @override
  late final GeneratedColumn<String> jobTitle = GeneratedColumn<String>(
    'job_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    specialty,
    departmentId,
    licenseNo,
    jobTitle,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staff_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<StaffProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('specialty')) {
      context.handle(
        _specialtyMeta,
        specialty.isAcceptableOrUnknown(data['specialty']!, _specialtyMeta),
      );
    }
    if (data.containsKey('department_id')) {
      context.handle(
        _departmentIdMeta,
        departmentId.isAcceptableOrUnknown(
          data['department_id']!,
          _departmentIdMeta,
        ),
      );
    }
    if (data.containsKey('license_no')) {
      context.handle(
        _licenseNoMeta,
        licenseNo.isAcceptableOrUnknown(data['license_no']!, _licenseNoMeta),
      );
    }
    if (data.containsKey('job_title')) {
      context.handle(
        _jobTitleMeta,
        jobTitle.isAcceptableOrUnknown(data['job_title']!, _jobTitleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  StaffProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StaffProfileRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      specialty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}specialty'],
      ),
      departmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}department_id'],
      ),
      licenseNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license_no'],
      ),
      jobTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_title'],
      ),
    );
  }

  @override
  $StaffProfilesTable createAlias(String alias) {
    return $StaffProfilesTable(attachedDatabase, alias);
  }
}

class StaffProfileRow extends DataClass implements Insertable<StaffProfileRow> {
  final String userId;
  final String? specialty;
  final String? departmentId;
  final String? licenseNo;
  final String? jobTitle;
  const StaffProfileRow({
    required this.userId,
    this.specialty,
    this.departmentId,
    this.licenseNo,
    this.jobTitle,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || specialty != null) {
      map['specialty'] = Variable<String>(specialty);
    }
    if (!nullToAbsent || departmentId != null) {
      map['department_id'] = Variable<String>(departmentId);
    }
    if (!nullToAbsent || licenseNo != null) {
      map['license_no'] = Variable<String>(licenseNo);
    }
    if (!nullToAbsent || jobTitle != null) {
      map['job_title'] = Variable<String>(jobTitle);
    }
    return map;
  }

  StaffProfilesCompanion toCompanion(bool nullToAbsent) {
    return StaffProfilesCompanion(
      userId: Value(userId),
      specialty: specialty == null && nullToAbsent
          ? const Value.absent()
          : Value(specialty),
      departmentId: departmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(departmentId),
      licenseNo: licenseNo == null && nullToAbsent
          ? const Value.absent()
          : Value(licenseNo),
      jobTitle: jobTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(jobTitle),
    );
  }

  factory StaffProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StaffProfileRow(
      userId: serializer.fromJson<String>(json['userId']),
      specialty: serializer.fromJson<String?>(json['specialty']),
      departmentId: serializer.fromJson<String?>(json['departmentId']),
      licenseNo: serializer.fromJson<String?>(json['licenseNo']),
      jobTitle: serializer.fromJson<String?>(json['jobTitle']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'specialty': serializer.toJson<String?>(specialty),
      'departmentId': serializer.toJson<String?>(departmentId),
      'licenseNo': serializer.toJson<String?>(licenseNo),
      'jobTitle': serializer.toJson<String?>(jobTitle),
    };
  }

  StaffProfileRow copyWith({
    String? userId,
    Value<String?> specialty = const Value.absent(),
    Value<String?> departmentId = const Value.absent(),
    Value<String?> licenseNo = const Value.absent(),
    Value<String?> jobTitle = const Value.absent(),
  }) => StaffProfileRow(
    userId: userId ?? this.userId,
    specialty: specialty.present ? specialty.value : this.specialty,
    departmentId: departmentId.present ? departmentId.value : this.departmentId,
    licenseNo: licenseNo.present ? licenseNo.value : this.licenseNo,
    jobTitle: jobTitle.present ? jobTitle.value : this.jobTitle,
  );
  StaffProfileRow copyWithCompanion(StaffProfilesCompanion data) {
    return StaffProfileRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      specialty: data.specialty.present ? data.specialty.value : this.specialty,
      departmentId: data.departmentId.present
          ? data.departmentId.value
          : this.departmentId,
      licenseNo: data.licenseNo.present ? data.licenseNo.value : this.licenseNo,
      jobTitle: data.jobTitle.present ? data.jobTitle.value : this.jobTitle,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StaffProfileRow(')
          ..write('userId: $userId, ')
          ..write('specialty: $specialty, ')
          ..write('departmentId: $departmentId, ')
          ..write('licenseNo: $licenseNo, ')
          ..write('jobTitle: $jobTitle')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, specialty, departmentId, licenseNo, jobTitle);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaffProfileRow &&
          other.userId == this.userId &&
          other.specialty == this.specialty &&
          other.departmentId == this.departmentId &&
          other.licenseNo == this.licenseNo &&
          other.jobTitle == this.jobTitle);
}

class StaffProfilesCompanion extends UpdateCompanion<StaffProfileRow> {
  final Value<String> userId;
  final Value<String?> specialty;
  final Value<String?> departmentId;
  final Value<String?> licenseNo;
  final Value<String?> jobTitle;
  final Value<int> rowid;
  const StaffProfilesCompanion({
    this.userId = const Value.absent(),
    this.specialty = const Value.absent(),
    this.departmentId = const Value.absent(),
    this.licenseNo = const Value.absent(),
    this.jobTitle = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StaffProfilesCompanion.insert({
    required String userId,
    this.specialty = const Value.absent(),
    this.departmentId = const Value.absent(),
    this.licenseNo = const Value.absent(),
    this.jobTitle = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<StaffProfileRow> custom({
    Expression<String>? userId,
    Expression<String>? specialty,
    Expression<String>? departmentId,
    Expression<String>? licenseNo,
    Expression<String>? jobTitle,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (specialty != null) 'specialty': specialty,
      if (departmentId != null) 'department_id': departmentId,
      if (licenseNo != null) 'license_no': licenseNo,
      if (jobTitle != null) 'job_title': jobTitle,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StaffProfilesCompanion copyWith({
    Value<String>? userId,
    Value<String?>? specialty,
    Value<String?>? departmentId,
    Value<String?>? licenseNo,
    Value<String?>? jobTitle,
    Value<int>? rowid,
  }) {
    return StaffProfilesCompanion(
      userId: userId ?? this.userId,
      specialty: specialty ?? this.specialty,
      departmentId: departmentId ?? this.departmentId,
      licenseNo: licenseNo ?? this.licenseNo,
      jobTitle: jobTitle ?? this.jobTitle,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (specialty.present) {
      map['specialty'] = Variable<String>(specialty.value);
    }
    if (departmentId.present) {
      map['department_id'] = Variable<String>(departmentId.value);
    }
    if (licenseNo.present) {
      map['license_no'] = Variable<String>(licenseNo.value);
    }
    if (jobTitle.present) {
      map['job_title'] = Variable<String>(jobTitle.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StaffProfilesCompanion(')
          ..write('userId: $userId, ')
          ..write('specialty: $specialty, ')
          ..write('departmentId: $departmentId, ')
          ..write('licenseNo: $licenseNo, ')
          ..write('jobTitle: $jobTitle, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScheduleTemplatesTable extends ScheduleTemplates
    with TableInfo<$ScheduleTemplatesTable, ScheduleTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _staffIdMeta = const VerificationMeta(
    'staffId',
  );
  @override
  late final GeneratedColumn<String> staffId = GeneratedColumn<String>(
    'staff_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinutesMeta = const VerificationMeta(
    'startMinutes',
  );
  @override
  late final GeneratedColumn<int> startMinutes = GeneratedColumn<int>(
    'start_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMinutesMeta = const VerificationMeta(
    'endMinutes',
  );
  @override
  late final GeneratedColumn<int> endMinutes = GeneratedColumn<int>(
    'end_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotMinutesMeta = const VerificationMeta(
    'slotMinutes',
  );
  @override
  late final GeneratedColumn<int> slotMinutes = GeneratedColumn<int>(
    'slot_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(20),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    staffId,
    weekday,
    startMinutes,
    endMinutes,
    slotMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('staff_id')) {
      context.handle(
        _staffIdMeta,
        staffId.isAcceptableOrUnknown(data['staff_id']!, _staffIdMeta),
      );
    } else if (isInserting) {
      context.missing(_staffIdMeta);
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('start_minutes')) {
      context.handle(
        _startMinutesMeta,
        startMinutes.isAcceptableOrUnknown(
          data['start_minutes']!,
          _startMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startMinutesMeta);
    }
    if (data.containsKey('end_minutes')) {
      context.handle(
        _endMinutesMeta,
        endMinutes.isAcceptableOrUnknown(data['end_minutes']!, _endMinutesMeta),
      );
    } else if (isInserting) {
      context.missing(_endMinutesMeta);
    }
    if (data.containsKey('slot_minutes')) {
      context.handle(
        _slotMinutesMeta,
        slotMinutes.isAcceptableOrUnknown(
          data['slot_minutes']!,
          _slotMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduleTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      staffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staff_id'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      startMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minutes'],
      )!,
      endMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minutes'],
      )!,
      slotMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slot_minutes'],
      )!,
    );
  }

  @override
  $ScheduleTemplatesTable createAlias(String alias) {
    return $ScheduleTemplatesTable(attachedDatabase, alias);
  }
}

class ScheduleTemplateRow extends DataClass
    implements Insertable<ScheduleTemplateRow> {
  final String id;
  final String staffId;

  /// 1 = Monday … 7 = Sunday (`DateTime.weekday`).
  final int weekday;

  /// Minutes from midnight, local clinic time.
  final int startMinutes;
  final int endMinutes;
  final int slotMinutes;
  const ScheduleTemplateRow({
    required this.id,
    required this.staffId,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    required this.slotMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['staff_id'] = Variable<String>(staffId);
    map['weekday'] = Variable<int>(weekday);
    map['start_minutes'] = Variable<int>(startMinutes);
    map['end_minutes'] = Variable<int>(endMinutes);
    map['slot_minutes'] = Variable<int>(slotMinutes);
    return map;
  }

  ScheduleTemplatesCompanion toCompanion(bool nullToAbsent) {
    return ScheduleTemplatesCompanion(
      id: Value(id),
      staffId: Value(staffId),
      weekday: Value(weekday),
      startMinutes: Value(startMinutes),
      endMinutes: Value(endMinutes),
      slotMinutes: Value(slotMinutes),
    );
  }

  factory ScheduleTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleTemplateRow(
      id: serializer.fromJson<String>(json['id']),
      staffId: serializer.fromJson<String>(json['staffId']),
      weekday: serializer.fromJson<int>(json['weekday']),
      startMinutes: serializer.fromJson<int>(json['startMinutes']),
      endMinutes: serializer.fromJson<int>(json['endMinutes']),
      slotMinutes: serializer.fromJson<int>(json['slotMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'staffId': serializer.toJson<String>(staffId),
      'weekday': serializer.toJson<int>(weekday),
      'startMinutes': serializer.toJson<int>(startMinutes),
      'endMinutes': serializer.toJson<int>(endMinutes),
      'slotMinutes': serializer.toJson<int>(slotMinutes),
    };
  }

  ScheduleTemplateRow copyWith({
    String? id,
    String? staffId,
    int? weekday,
    int? startMinutes,
    int? endMinutes,
    int? slotMinutes,
  }) => ScheduleTemplateRow(
    id: id ?? this.id,
    staffId: staffId ?? this.staffId,
    weekday: weekday ?? this.weekday,
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
    slotMinutes: slotMinutes ?? this.slotMinutes,
  );
  ScheduleTemplateRow copyWithCompanion(ScheduleTemplatesCompanion data) {
    return ScheduleTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      startMinutes: data.startMinutes.present
          ? data.startMinutes.value
          : this.startMinutes,
      endMinutes: data.endMinutes.present
          ? data.endMinutes.value
          : this.endMinutes,
      slotMinutes: data.slotMinutes.present
          ? data.slotMinutes.value
          : this.slotMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleTemplateRow(')
          ..write('id: $id, ')
          ..write('staffId: $staffId, ')
          ..write('weekday: $weekday, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('slotMinutes: $slotMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, staffId, weekday, startMinutes, endMinutes, slotMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleTemplateRow &&
          other.id == this.id &&
          other.staffId == this.staffId &&
          other.weekday == this.weekday &&
          other.startMinutes == this.startMinutes &&
          other.endMinutes == this.endMinutes &&
          other.slotMinutes == this.slotMinutes);
}

class ScheduleTemplatesCompanion extends UpdateCompanion<ScheduleTemplateRow> {
  final Value<String> id;
  final Value<String> staffId;
  final Value<int> weekday;
  final Value<int> startMinutes;
  final Value<int> endMinutes;
  final Value<int> slotMinutes;
  final Value<int> rowid;
  const ScheduleTemplatesCompanion({
    this.id = const Value.absent(),
    this.staffId = const Value.absent(),
    this.weekday = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.endMinutes = const Value.absent(),
    this.slotMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScheduleTemplatesCompanion.insert({
    required String id,
    required String staffId,
    required int weekday,
    required int startMinutes,
    required int endMinutes,
    this.slotMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       staffId = Value(staffId),
       weekday = Value(weekday),
       startMinutes = Value(startMinutes),
       endMinutes = Value(endMinutes);
  static Insertable<ScheduleTemplateRow> custom({
    Expression<String>? id,
    Expression<String>? staffId,
    Expression<int>? weekday,
    Expression<int>? startMinutes,
    Expression<int>? endMinutes,
    Expression<int>? slotMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (staffId != null) 'staff_id': staffId,
      if (weekday != null) 'weekday': weekday,
      if (startMinutes != null) 'start_minutes': startMinutes,
      if (endMinutes != null) 'end_minutes': endMinutes,
      if (slotMinutes != null) 'slot_minutes': slotMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScheduleTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? staffId,
    Value<int>? weekday,
    Value<int>? startMinutes,
    Value<int>? endMinutes,
    Value<int>? slotMinutes,
    Value<int>? rowid,
  }) {
    return ScheduleTemplatesCompanion(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      weekday: weekday ?? this.weekday,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      slotMinutes: slotMinutes ?? this.slotMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (staffId.present) {
      map['staff_id'] = Variable<String>(staffId.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (startMinutes.present) {
      map['start_minutes'] = Variable<int>(startMinutes.value);
    }
    if (endMinutes.present) {
      map['end_minutes'] = Variable<int>(endMinutes.value);
    }
    if (slotMinutes.present) {
      map['slot_minutes'] = Variable<int>(slotMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('staffId: $staffId, ')
          ..write('weekday: $weekday, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('slotMinutes: $slotMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppointmentsTable extends Appointments
    with TableInfo<$AppointmentsTable, AppointmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppointmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _staffIdMeta = const VerificationMeta(
    'staffId',
  );
  @override
  late final GeneratedColumn<String> staffId = GeneratedColumn<String>(
    'staff_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _departmentIdMeta = const VerificationMeta(
    'departmentId',
  );
  @override
  late final GeneratedColumn<String> departmentId = GeneratedColumn<String>(
    'department_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES departments (id)',
    ),
  );
  static const VerificationMeta _slotStartMeta = const VerificationMeta(
    'slotStart',
  );
  @override
  late final GeneratedColumn<DateTime> slotStart = GeneratedColumn<DateTime>(
    'slot_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotEndMeta = const VerificationMeta(
    'slotEnd',
  );
  @override
  late final GeneratedColumn<DateTime> slotEnd = GeneratedColumn<DateTime>(
    'slot_end',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<VisitType, String> visitType =
      GeneratedColumn<String>(
        'visit_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<VisitType>($AppointmentsTable.$convertervisitType);
  @override
  late final GeneratedColumnWithTypeConverter<AppointmentStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('booked'),
  ).withConverter<AppointmentStatus>($AppointmentsTable.$converterstatus);
  static const VerificationMeta _reasonTextMeta = const VerificationMeta(
    'reasonText',
  );
  @override
  late final GeneratedColumn<String> reasonText = GeneratedColumn<String>(
    'reason_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookedAtMeta = const VerificationMeta(
    'bookedAt',
  );
  @override
  late final GeneratedColumn<DateTime> bookedAt = GeneratedColumn<DateTime>(
    'booked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _noShowRiskMeta = const VerificationMeta(
    'noShowRisk',
  );
  @override
  late final GeneratedColumn<double> noShowRisk = GeneratedColumn<double>(
    'no_show_risk',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RiskBand?, String> riskBand =
      GeneratedColumn<String>(
        'risk_band',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<RiskBand?>($AppointmentsTable.$converterriskBandn);
  static const VerificationMeta _remindersSentMeta = const VerificationMeta(
    'remindersSent',
  );
  @override
  late final GeneratedColumn<int> remindersSent = GeneratedColumn<int>(
    'reminders_sent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _checkedInAtMeta = const VerificationMeta(
    'checkedInAt',
  );
  @override
  late final GeneratedColumn<DateTime> checkedInAt = GeneratedColumn<DateTime>(
    'checked_in_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    staffId,
    departmentId,
    slotStart,
    slotEnd,
    visitType,
    status,
    reasonText,
    bookedAt,
    noShowRisk,
    riskBand,
    remindersSent,
    checkedInAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'appointments';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppointmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('staff_id')) {
      context.handle(
        _staffIdMeta,
        staffId.isAcceptableOrUnknown(data['staff_id']!, _staffIdMeta),
      );
    } else if (isInserting) {
      context.missing(_staffIdMeta);
    }
    if (data.containsKey('department_id')) {
      context.handle(
        _departmentIdMeta,
        departmentId.isAcceptableOrUnknown(
          data['department_id']!,
          _departmentIdMeta,
        ),
      );
    }
    if (data.containsKey('slot_start')) {
      context.handle(
        _slotStartMeta,
        slotStart.isAcceptableOrUnknown(data['slot_start']!, _slotStartMeta),
      );
    } else if (isInserting) {
      context.missing(_slotStartMeta);
    }
    if (data.containsKey('slot_end')) {
      context.handle(
        _slotEndMeta,
        slotEnd.isAcceptableOrUnknown(data['slot_end']!, _slotEndMeta),
      );
    } else if (isInserting) {
      context.missing(_slotEndMeta);
    }
    if (data.containsKey('reason_text')) {
      context.handle(
        _reasonTextMeta,
        reasonText.isAcceptableOrUnknown(data['reason_text']!, _reasonTextMeta),
      );
    }
    if (data.containsKey('booked_at')) {
      context.handle(
        _bookedAtMeta,
        bookedAt.isAcceptableOrUnknown(data['booked_at']!, _bookedAtMeta),
      );
    }
    if (data.containsKey('no_show_risk')) {
      context.handle(
        _noShowRiskMeta,
        noShowRisk.isAcceptableOrUnknown(
          data['no_show_risk']!,
          _noShowRiskMeta,
        ),
      );
    }
    if (data.containsKey('reminders_sent')) {
      context.handle(
        _remindersSentMeta,
        remindersSent.isAcceptableOrUnknown(
          data['reminders_sent']!,
          _remindersSentMeta,
        ),
      );
    }
    if (data.containsKey('checked_in_at')) {
      context.handle(
        _checkedInAtMeta,
        checkedInAt.isAcceptableOrUnknown(
          data['checked_in_at']!,
          _checkedInAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppointmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppointmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      staffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staff_id'],
      )!,
      departmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}department_id'],
      ),
      slotStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}slot_start'],
      )!,
      slotEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}slot_end'],
      )!,
      visitType: $AppointmentsTable.$convertervisitType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}visit_type'],
        )!,
      ),
      status: $AppointmentsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      reasonText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_text'],
      ),
      bookedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}booked_at'],
      )!,
      noShowRisk: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}no_show_risk'],
      ),
      riskBand: $AppointmentsTable.$converterriskBandn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}risk_band'],
        ),
      ),
      remindersSent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminders_sent'],
      )!,
      checkedInAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}checked_in_at'],
      ),
    );
  }

  @override
  $AppointmentsTable createAlias(String alias) {
    return $AppointmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<VisitType, String, String> $convertervisitType =
      const EnumNameConverter<VisitType>(VisitType.values);
  static JsonTypeConverter2<AppointmentStatus, String, String>
  $converterstatus = const EnumNameConverter<AppointmentStatus>(
    AppointmentStatus.values,
  );
  static JsonTypeConverter2<RiskBand, String, String> $converterriskBand =
      const EnumNameConverter<RiskBand>(RiskBand.values);
  static JsonTypeConverter2<RiskBand?, String?, String?> $converterriskBandn =
      JsonTypeConverter2.asNullable($converterriskBand);
}

class AppointmentRow extends DataClass implements Insertable<AppointmentRow> {
  final String id;
  final String patientId;
  final String staffId;
  final String? departmentId;
  final DateTime slotStart;
  final DateTime slotEnd;
  final VisitType visitType;
  final AppointmentStatus status;
  final String? reasonText;
  final DateTime bookedAt;

  /// Predicted no-show probability (0–1) and its band, written at booking
  /// time by the model (P4-17). Null until scored.
  final double? noShowRisk;
  final RiskBand? riskBand;
  final int remindersSent;
  final DateTime? checkedInAt;
  const AppointmentRow({
    required this.id,
    required this.patientId,
    required this.staffId,
    this.departmentId,
    required this.slotStart,
    required this.slotEnd,
    required this.visitType,
    required this.status,
    this.reasonText,
    required this.bookedAt,
    this.noShowRisk,
    this.riskBand,
    required this.remindersSent,
    this.checkedInAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['staff_id'] = Variable<String>(staffId);
    if (!nullToAbsent || departmentId != null) {
      map['department_id'] = Variable<String>(departmentId);
    }
    map['slot_start'] = Variable<DateTime>(slotStart);
    map['slot_end'] = Variable<DateTime>(slotEnd);
    {
      map['visit_type'] = Variable<String>(
        $AppointmentsTable.$convertervisitType.toSql(visitType),
      );
    }
    {
      map['status'] = Variable<String>(
        $AppointmentsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || reasonText != null) {
      map['reason_text'] = Variable<String>(reasonText);
    }
    map['booked_at'] = Variable<DateTime>(bookedAt);
    if (!nullToAbsent || noShowRisk != null) {
      map['no_show_risk'] = Variable<double>(noShowRisk);
    }
    if (!nullToAbsent || riskBand != null) {
      map['risk_band'] = Variable<String>(
        $AppointmentsTable.$converterriskBandn.toSql(riskBand),
      );
    }
    map['reminders_sent'] = Variable<int>(remindersSent);
    if (!nullToAbsent || checkedInAt != null) {
      map['checked_in_at'] = Variable<DateTime>(checkedInAt);
    }
    return map;
  }

  AppointmentsCompanion toCompanion(bool nullToAbsent) {
    return AppointmentsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      staffId: Value(staffId),
      departmentId: departmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(departmentId),
      slotStart: Value(slotStart),
      slotEnd: Value(slotEnd),
      visitType: Value(visitType),
      status: Value(status),
      reasonText: reasonText == null && nullToAbsent
          ? const Value.absent()
          : Value(reasonText),
      bookedAt: Value(bookedAt),
      noShowRisk: noShowRisk == null && nullToAbsent
          ? const Value.absent()
          : Value(noShowRisk),
      riskBand: riskBand == null && nullToAbsent
          ? const Value.absent()
          : Value(riskBand),
      remindersSent: Value(remindersSent),
      checkedInAt: checkedInAt == null && nullToAbsent
          ? const Value.absent()
          : Value(checkedInAt),
    );
  }

  factory AppointmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppointmentRow(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      staffId: serializer.fromJson<String>(json['staffId']),
      departmentId: serializer.fromJson<String?>(json['departmentId']),
      slotStart: serializer.fromJson<DateTime>(json['slotStart']),
      slotEnd: serializer.fromJson<DateTime>(json['slotEnd']),
      visitType: $AppointmentsTable.$convertervisitType.fromJson(
        serializer.fromJson<String>(json['visitType']),
      ),
      status: $AppointmentsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      reasonText: serializer.fromJson<String?>(json['reasonText']),
      bookedAt: serializer.fromJson<DateTime>(json['bookedAt']),
      noShowRisk: serializer.fromJson<double?>(json['noShowRisk']),
      riskBand: $AppointmentsTable.$converterriskBandn.fromJson(
        serializer.fromJson<String?>(json['riskBand']),
      ),
      remindersSent: serializer.fromJson<int>(json['remindersSent']),
      checkedInAt: serializer.fromJson<DateTime?>(json['checkedInAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'staffId': serializer.toJson<String>(staffId),
      'departmentId': serializer.toJson<String?>(departmentId),
      'slotStart': serializer.toJson<DateTime>(slotStart),
      'slotEnd': serializer.toJson<DateTime>(slotEnd),
      'visitType': serializer.toJson<String>(
        $AppointmentsTable.$convertervisitType.toJson(visitType),
      ),
      'status': serializer.toJson<String>(
        $AppointmentsTable.$converterstatus.toJson(status),
      ),
      'reasonText': serializer.toJson<String?>(reasonText),
      'bookedAt': serializer.toJson<DateTime>(bookedAt),
      'noShowRisk': serializer.toJson<double?>(noShowRisk),
      'riskBand': serializer.toJson<String?>(
        $AppointmentsTable.$converterriskBandn.toJson(riskBand),
      ),
      'remindersSent': serializer.toJson<int>(remindersSent),
      'checkedInAt': serializer.toJson<DateTime?>(checkedInAt),
    };
  }

  AppointmentRow copyWith({
    String? id,
    String? patientId,
    String? staffId,
    Value<String?> departmentId = const Value.absent(),
    DateTime? slotStart,
    DateTime? slotEnd,
    VisitType? visitType,
    AppointmentStatus? status,
    Value<String?> reasonText = const Value.absent(),
    DateTime? bookedAt,
    Value<double?> noShowRisk = const Value.absent(),
    Value<RiskBand?> riskBand = const Value.absent(),
    int? remindersSent,
    Value<DateTime?> checkedInAt = const Value.absent(),
  }) => AppointmentRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    staffId: staffId ?? this.staffId,
    departmentId: departmentId.present ? departmentId.value : this.departmentId,
    slotStart: slotStart ?? this.slotStart,
    slotEnd: slotEnd ?? this.slotEnd,
    visitType: visitType ?? this.visitType,
    status: status ?? this.status,
    reasonText: reasonText.present ? reasonText.value : this.reasonText,
    bookedAt: bookedAt ?? this.bookedAt,
    noShowRisk: noShowRisk.present ? noShowRisk.value : this.noShowRisk,
    riskBand: riskBand.present ? riskBand.value : this.riskBand,
    remindersSent: remindersSent ?? this.remindersSent,
    checkedInAt: checkedInAt.present ? checkedInAt.value : this.checkedInAt,
  );
  AppointmentRow copyWithCompanion(AppointmentsCompanion data) {
    return AppointmentRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      departmentId: data.departmentId.present
          ? data.departmentId.value
          : this.departmentId,
      slotStart: data.slotStart.present ? data.slotStart.value : this.slotStart,
      slotEnd: data.slotEnd.present ? data.slotEnd.value : this.slotEnd,
      visitType: data.visitType.present ? data.visitType.value : this.visitType,
      status: data.status.present ? data.status.value : this.status,
      reasonText: data.reasonText.present
          ? data.reasonText.value
          : this.reasonText,
      bookedAt: data.bookedAt.present ? data.bookedAt.value : this.bookedAt,
      noShowRisk: data.noShowRisk.present
          ? data.noShowRisk.value
          : this.noShowRisk,
      riskBand: data.riskBand.present ? data.riskBand.value : this.riskBand,
      remindersSent: data.remindersSent.present
          ? data.remindersSent.value
          : this.remindersSent,
      checkedInAt: data.checkedInAt.present
          ? data.checkedInAt.value
          : this.checkedInAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppointmentRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('staffId: $staffId, ')
          ..write('departmentId: $departmentId, ')
          ..write('slotStart: $slotStart, ')
          ..write('slotEnd: $slotEnd, ')
          ..write('visitType: $visitType, ')
          ..write('status: $status, ')
          ..write('reasonText: $reasonText, ')
          ..write('bookedAt: $bookedAt, ')
          ..write('noShowRisk: $noShowRisk, ')
          ..write('riskBand: $riskBand, ')
          ..write('remindersSent: $remindersSent, ')
          ..write('checkedInAt: $checkedInAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    staffId,
    departmentId,
    slotStart,
    slotEnd,
    visitType,
    status,
    reasonText,
    bookedAt,
    noShowRisk,
    riskBand,
    remindersSent,
    checkedInAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppointmentRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.staffId == this.staffId &&
          other.departmentId == this.departmentId &&
          other.slotStart == this.slotStart &&
          other.slotEnd == this.slotEnd &&
          other.visitType == this.visitType &&
          other.status == this.status &&
          other.reasonText == this.reasonText &&
          other.bookedAt == this.bookedAt &&
          other.noShowRisk == this.noShowRisk &&
          other.riskBand == this.riskBand &&
          other.remindersSent == this.remindersSent &&
          other.checkedInAt == this.checkedInAt);
}

class AppointmentsCompanion extends UpdateCompanion<AppointmentRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> staffId;
  final Value<String?> departmentId;
  final Value<DateTime> slotStart;
  final Value<DateTime> slotEnd;
  final Value<VisitType> visitType;
  final Value<AppointmentStatus> status;
  final Value<String?> reasonText;
  final Value<DateTime> bookedAt;
  final Value<double?> noShowRisk;
  final Value<RiskBand?> riskBand;
  final Value<int> remindersSent;
  final Value<DateTime?> checkedInAt;
  final Value<int> rowid;
  const AppointmentsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.staffId = const Value.absent(),
    this.departmentId = const Value.absent(),
    this.slotStart = const Value.absent(),
    this.slotEnd = const Value.absent(),
    this.visitType = const Value.absent(),
    this.status = const Value.absent(),
    this.reasonText = const Value.absent(),
    this.bookedAt = const Value.absent(),
    this.noShowRisk = const Value.absent(),
    this.riskBand = const Value.absent(),
    this.remindersSent = const Value.absent(),
    this.checkedInAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppointmentsCompanion.insert({
    required String id,
    required String patientId,
    required String staffId,
    this.departmentId = const Value.absent(),
    required DateTime slotStart,
    required DateTime slotEnd,
    required VisitType visitType,
    this.status = const Value.absent(),
    this.reasonText = const Value.absent(),
    this.bookedAt = const Value.absent(),
    this.noShowRisk = const Value.absent(),
    this.riskBand = const Value.absent(),
    this.remindersSent = const Value.absent(),
    this.checkedInAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       staffId = Value(staffId),
       slotStart = Value(slotStart),
       slotEnd = Value(slotEnd),
       visitType = Value(visitType);
  static Insertable<AppointmentRow> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? staffId,
    Expression<String>? departmentId,
    Expression<DateTime>? slotStart,
    Expression<DateTime>? slotEnd,
    Expression<String>? visitType,
    Expression<String>? status,
    Expression<String>? reasonText,
    Expression<DateTime>? bookedAt,
    Expression<double>? noShowRisk,
    Expression<String>? riskBand,
    Expression<int>? remindersSent,
    Expression<DateTime>? checkedInAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (staffId != null) 'staff_id': staffId,
      if (departmentId != null) 'department_id': departmentId,
      if (slotStart != null) 'slot_start': slotStart,
      if (slotEnd != null) 'slot_end': slotEnd,
      if (visitType != null) 'visit_type': visitType,
      if (status != null) 'status': status,
      if (reasonText != null) 'reason_text': reasonText,
      if (bookedAt != null) 'booked_at': bookedAt,
      if (noShowRisk != null) 'no_show_risk': noShowRisk,
      if (riskBand != null) 'risk_band': riskBand,
      if (remindersSent != null) 'reminders_sent': remindersSent,
      if (checkedInAt != null) 'checked_in_at': checkedInAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppointmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String>? staffId,
    Value<String?>? departmentId,
    Value<DateTime>? slotStart,
    Value<DateTime>? slotEnd,
    Value<VisitType>? visitType,
    Value<AppointmentStatus>? status,
    Value<String?>? reasonText,
    Value<DateTime>? bookedAt,
    Value<double?>? noShowRisk,
    Value<RiskBand?>? riskBand,
    Value<int>? remindersSent,
    Value<DateTime?>? checkedInAt,
    Value<int>? rowid,
  }) {
    return AppointmentsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      staffId: staffId ?? this.staffId,
      departmentId: departmentId ?? this.departmentId,
      slotStart: slotStart ?? this.slotStart,
      slotEnd: slotEnd ?? this.slotEnd,
      visitType: visitType ?? this.visitType,
      status: status ?? this.status,
      reasonText: reasonText ?? this.reasonText,
      bookedAt: bookedAt ?? this.bookedAt,
      noShowRisk: noShowRisk ?? this.noShowRisk,
      riskBand: riskBand ?? this.riskBand,
      remindersSent: remindersSent ?? this.remindersSent,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (staffId.present) {
      map['staff_id'] = Variable<String>(staffId.value);
    }
    if (departmentId.present) {
      map['department_id'] = Variable<String>(departmentId.value);
    }
    if (slotStart.present) {
      map['slot_start'] = Variable<DateTime>(slotStart.value);
    }
    if (slotEnd.present) {
      map['slot_end'] = Variable<DateTime>(slotEnd.value);
    }
    if (visitType.present) {
      map['visit_type'] = Variable<String>(
        $AppointmentsTable.$convertervisitType.toSql(visitType.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $AppointmentsTable.$converterstatus.toSql(status.value),
      );
    }
    if (reasonText.present) {
      map['reason_text'] = Variable<String>(reasonText.value);
    }
    if (bookedAt.present) {
      map['booked_at'] = Variable<DateTime>(bookedAt.value);
    }
    if (noShowRisk.present) {
      map['no_show_risk'] = Variable<double>(noShowRisk.value);
    }
    if (riskBand.present) {
      map['risk_band'] = Variable<String>(
        $AppointmentsTable.$converterriskBandn.toSql(riskBand.value),
      );
    }
    if (remindersSent.present) {
      map['reminders_sent'] = Variable<int>(remindersSent.value);
    }
    if (checkedInAt.present) {
      map['checked_in_at'] = Variable<DateTime>(checkedInAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppointmentsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('staffId: $staffId, ')
          ..write('departmentId: $departmentId, ')
          ..write('slotStart: $slotStart, ')
          ..write('slotEnd: $slotEnd, ')
          ..write('visitType: $visitType, ')
          ..write('status: $status, ')
          ..write('reasonText: $reasonText, ')
          ..write('bookedAt: $bookedAt, ')
          ..write('noShowRisk: $noShowRisk, ')
          ..write('riskBand: $riskBand, ')
          ..write('remindersSent: $remindersSent, ')
          ..write('checkedInAt: $checkedInAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, ReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appointmentIdMeta = const VerificationMeta(
    'appointmentId',
  );
  @override
  late final GeneratedColumn<String> appointmentId = GeneratedColumn<String>(
    'appointment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES appointments (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scheduledForMeta = const VerificationMeta(
    'scheduledFor',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledFor = GeneratedColumn<DateTime>(
    'scheduled_for',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReminderChannel, String> channel =
      GeneratedColumn<String>(
        'channel',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReminderChannel>($RemindersTable.$converterchannel);
  @override
  late final GeneratedColumnWithTypeConverter<ReminderKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('standard'),
      ).withConverter<ReminderKind>($RemindersTable.$converterkind);
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _acknowledgedMeta = const VerificationMeta(
    'acknowledged',
  );
  @override
  late final GeneratedColumn<bool> acknowledged = GeneratedColumn<bool>(
    'acknowledged',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("acknowledged" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    appointmentId,
    scheduledFor,
    channel,
    kind,
    sentAt,
    acknowledged,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('appointment_id')) {
      context.handle(
        _appointmentIdMeta,
        appointmentId.isAcceptableOrUnknown(
          data['appointment_id']!,
          _appointmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appointmentIdMeta);
    }
    if (data.containsKey('scheduled_for')) {
      context.handle(
        _scheduledForMeta,
        scheduledFor.isAcceptableOrUnknown(
          data['scheduled_for']!,
          _scheduledForMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledForMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    if (data.containsKey('acknowledged')) {
      context.handle(
        _acknowledgedMeta,
        acknowledged.isAcceptableOrUnknown(
          data['acknowledged']!,
          _acknowledgedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      appointmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appointment_id'],
      )!,
      scheduledFor: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_for'],
      )!,
      channel: $RemindersTable.$converterchannel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}channel'],
        )!,
      ),
      kind: $RemindersTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      ),
      acknowledged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}acknowledged'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ReminderChannel, String, String> $converterchannel =
      const EnumNameConverter<ReminderChannel>(ReminderChannel.values);
  static JsonTypeConverter2<ReminderKind, String, String> $converterkind =
      const EnumNameConverter<ReminderKind>(ReminderKind.values);
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final String id;
  final String appointmentId;
  final DateTime scheduledFor;
  final ReminderChannel channel;
  final ReminderKind kind;
  final DateTime? sentAt;
  final bool acknowledged;
  const ReminderRow({
    required this.id,
    required this.appointmentId,
    required this.scheduledFor,
    required this.channel,
    required this.kind,
    this.sentAt,
    required this.acknowledged,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['appointment_id'] = Variable<String>(appointmentId);
    map['scheduled_for'] = Variable<DateTime>(scheduledFor);
    {
      map['channel'] = Variable<String>(
        $RemindersTable.$converterchannel.toSql(channel),
      );
    }
    {
      map['kind'] = Variable<String>(
        $RemindersTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<DateTime>(sentAt);
    }
    map['acknowledged'] = Variable<bool>(acknowledged);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      appointmentId: Value(appointmentId),
      scheduledFor: Value(scheduledFor),
      channel: Value(channel),
      kind: Value(kind),
      sentAt: sentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAt),
      acknowledged: Value(acknowledged),
    );
  }

  factory ReminderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<String>(json['id']),
      appointmentId: serializer.fromJson<String>(json['appointmentId']),
      scheduledFor: serializer.fromJson<DateTime>(json['scheduledFor']),
      channel: $RemindersTable.$converterchannel.fromJson(
        serializer.fromJson<String>(json['channel']),
      ),
      kind: $RemindersTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      sentAt: serializer.fromJson<DateTime?>(json['sentAt']),
      acknowledged: serializer.fromJson<bool>(json['acknowledged']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'appointmentId': serializer.toJson<String>(appointmentId),
      'scheduledFor': serializer.toJson<DateTime>(scheduledFor),
      'channel': serializer.toJson<String>(
        $RemindersTable.$converterchannel.toJson(channel),
      ),
      'kind': serializer.toJson<String>(
        $RemindersTable.$converterkind.toJson(kind),
      ),
      'sentAt': serializer.toJson<DateTime?>(sentAt),
      'acknowledged': serializer.toJson<bool>(acknowledged),
    };
  }

  ReminderRow copyWith({
    String? id,
    String? appointmentId,
    DateTime? scheduledFor,
    ReminderChannel? channel,
    ReminderKind? kind,
    Value<DateTime?> sentAt = const Value.absent(),
    bool? acknowledged,
  }) => ReminderRow(
    id: id ?? this.id,
    appointmentId: appointmentId ?? this.appointmentId,
    scheduledFor: scheduledFor ?? this.scheduledFor,
    channel: channel ?? this.channel,
    kind: kind ?? this.kind,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
    acknowledged: acknowledged ?? this.acknowledged,
  );
  ReminderRow copyWithCompanion(RemindersCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      appointmentId: data.appointmentId.present
          ? data.appointmentId.value
          : this.appointmentId,
      scheduledFor: data.scheduledFor.present
          ? data.scheduledFor.value
          : this.scheduledFor,
      channel: data.channel.present ? data.channel.value : this.channel,
      kind: data.kind.present ? data.kind.value : this.kind,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      acknowledged: data.acknowledged.present
          ? data.acknowledged.value
          : this.acknowledged,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
          ..write('id: $id, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('channel: $channel, ')
          ..write('kind: $kind, ')
          ..write('sentAt: $sentAt, ')
          ..write('acknowledged: $acknowledged')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    appointmentId,
    scheduledFor,
    channel,
    kind,
    sentAt,
    acknowledged,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRow &&
          other.id == this.id &&
          other.appointmentId == this.appointmentId &&
          other.scheduledFor == this.scheduledFor &&
          other.channel == this.channel &&
          other.kind == this.kind &&
          other.sentAt == this.sentAt &&
          other.acknowledged == this.acknowledged);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<String> id;
  final Value<String> appointmentId;
  final Value<DateTime> scheduledFor;
  final Value<ReminderChannel> channel;
  final Value<ReminderKind> kind;
  final Value<DateTime?> sentAt;
  final Value<bool> acknowledged;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.appointmentId = const Value.absent(),
    this.scheduledFor = const Value.absent(),
    this.channel = const Value.absent(),
    this.kind = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.acknowledged = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required String appointmentId,
    required DateTime scheduledFor,
    required ReminderChannel channel,
    this.kind = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.acknowledged = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       appointmentId = Value(appointmentId),
       scheduledFor = Value(scheduledFor),
       channel = Value(channel);
  static Insertable<ReminderRow> custom({
    Expression<String>? id,
    Expression<String>? appointmentId,
    Expression<DateTime>? scheduledFor,
    Expression<String>? channel,
    Expression<String>? kind,
    Expression<DateTime>? sentAt,
    Expression<bool>? acknowledged,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (scheduledFor != null) 'scheduled_for': scheduledFor,
      if (channel != null) 'channel': channel,
      if (kind != null) 'kind': kind,
      if (sentAt != null) 'sent_at': sentAt,
      if (acknowledged != null) 'acknowledged': acknowledged,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<String>? id,
    Value<String>? appointmentId,
    Value<DateTime>? scheduledFor,
    Value<ReminderChannel>? channel,
    Value<ReminderKind>? kind,
    Value<DateTime?>? sentAt,
    Value<bool>? acknowledged,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      channel: channel ?? this.channel,
      kind: kind ?? this.kind,
      sentAt: sentAt ?? this.sentAt,
      acknowledged: acknowledged ?? this.acknowledged,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (appointmentId.present) {
      map['appointment_id'] = Variable<String>(appointmentId.value);
    }
    if (scheduledFor.present) {
      map['scheduled_for'] = Variable<DateTime>(scheduledFor.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(
        $RemindersTable.$converterchannel.toSql(channel.value),
      );
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $RemindersTable.$converterkind.toSql(kind.value),
      );
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (acknowledged.present) {
      map['acknowledged'] = Variable<bool>(acknowledged.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('channel: $channel, ')
          ..write('kind: $kind, ')
          ..write('sentAt: $sentAt, ')
          ..write('acknowledged: $acknowledged, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicalRecordsTable extends MedicalRecords
    with TableInfo<$MedicalRecordsTable, MedicalRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicalRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _authorStaffIdMeta = const VerificationMeta(
    'authorStaffId',
  );
  @override
  late final GeneratedColumn<String> authorStaffId = GeneratedColumn<String>(
    'author_staff_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<RecordType, String> recordType =
      GeneratedColumn<String>(
        'record_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RecordType>($MedicalRecordsTable.$converterrecordType);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceFacilityMeta = const VerificationMeta(
    'sourceFacility',
  );
  @override
  late final GeneratedColumn<String> sourceFacility = GeneratedColumn<String>(
    'source_facility',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attachmentPathMeta = const VerificationMeta(
    'attachmentPath',
  );
  @override
  late final GeneratedColumn<String> attachmentPath = GeneratedColumn<String>(
    'attachment_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extractedTextMeta = const VerificationMeta(
    'extractedText',
  );
  @override
  late final GeneratedColumn<String> extractedText = GeneratedColumn<String>(
    'extracted_text',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    authorStaffId,
    recordType,
    title,
    body,
    occurredAt,
    sourceFacility,
    attachmentPath,
    extractedText,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medical_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicalRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('author_staff_id')) {
      context.handle(
        _authorStaffIdMeta,
        authorStaffId.isAcceptableOrUnknown(
          data['author_staff_id']!,
          _authorStaffIdMeta,
        ),
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
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('source_facility')) {
      context.handle(
        _sourceFacilityMeta,
        sourceFacility.isAcceptableOrUnknown(
          data['source_facility']!,
          _sourceFacilityMeta,
        ),
      );
    }
    if (data.containsKey('attachment_path')) {
      context.handle(
        _attachmentPathMeta,
        attachmentPath.isAcceptableOrUnknown(
          data['attachment_path']!,
          _attachmentPathMeta,
        ),
      );
    }
    if (data.containsKey('extracted_text')) {
      context.handle(
        _extractedTextMeta,
        extractedText.isAcceptableOrUnknown(
          data['extracted_text']!,
          _extractedTextMeta,
        ),
      );
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
  MedicalRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicalRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      authorStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_staff_id'],
      ),
      recordType: $MedicalRecordsTable.$converterrecordType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}record_type'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      sourceFacility: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_facility'],
      ),
      attachmentPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_path'],
      ),
      extractedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_text'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MedicalRecordsTable createAlias(String alias) {
    return $MedicalRecordsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RecordType, String, String> $converterrecordType =
      const EnumNameConverter<RecordType>(RecordType.values);
}

class MedicalRecordRow extends DataClass
    implements Insertable<MedicalRecordRow> {
  final String id;
  final String patientId;

  /// Null for patient-imported records (P2-12).
  final String? authorStaffId;
  final RecordType recordType;
  final String title;
  final String? body;
  final DateTime occurredAt;
  final String? sourceFacility;

  /// Local path to an imported file (PDF, image), copied into app storage.
  final String? attachmentPath;

  /// Text pulled out of [attachmentPath] by the PDF extractor (P2-11), fed to
  /// the AI context builder (P3-02).
  final String? extractedText;
  final DateTime createdAt;
  const MedicalRecordRow({
    required this.id,
    required this.patientId,
    this.authorStaffId,
    required this.recordType,
    required this.title,
    this.body,
    required this.occurredAt,
    this.sourceFacility,
    this.attachmentPath,
    this.extractedText,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    if (!nullToAbsent || authorStaffId != null) {
      map['author_staff_id'] = Variable<String>(authorStaffId);
    }
    {
      map['record_type'] = Variable<String>(
        $MedicalRecordsTable.$converterrecordType.toSql(recordType),
      );
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || sourceFacility != null) {
      map['source_facility'] = Variable<String>(sourceFacility);
    }
    if (!nullToAbsent || attachmentPath != null) {
      map['attachment_path'] = Variable<String>(attachmentPath);
    }
    if (!nullToAbsent || extractedText != null) {
      map['extracted_text'] = Variable<String>(extractedText);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MedicalRecordsCompanion toCompanion(bool nullToAbsent) {
    return MedicalRecordsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      authorStaffId: authorStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(authorStaffId),
      recordType: Value(recordType),
      title: Value(title),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      occurredAt: Value(occurredAt),
      sourceFacility: sourceFacility == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceFacility),
      attachmentPath: attachmentPath == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentPath),
      extractedText: extractedText == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedText),
      createdAt: Value(createdAt),
    );
  }

  factory MedicalRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicalRecordRow(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      authorStaffId: serializer.fromJson<String?>(json['authorStaffId']),
      recordType: $MedicalRecordsTable.$converterrecordType.fromJson(
        serializer.fromJson<String>(json['recordType']),
      ),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String?>(json['body']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      sourceFacility: serializer.fromJson<String?>(json['sourceFacility']),
      attachmentPath: serializer.fromJson<String?>(json['attachmentPath']),
      extractedText: serializer.fromJson<String?>(json['extractedText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'authorStaffId': serializer.toJson<String?>(authorStaffId),
      'recordType': serializer.toJson<String>(
        $MedicalRecordsTable.$converterrecordType.toJson(recordType),
      ),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String?>(body),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'sourceFacility': serializer.toJson<String?>(sourceFacility),
      'attachmentPath': serializer.toJson<String?>(attachmentPath),
      'extractedText': serializer.toJson<String?>(extractedText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MedicalRecordRow copyWith({
    String? id,
    String? patientId,
    Value<String?> authorStaffId = const Value.absent(),
    RecordType? recordType,
    String? title,
    Value<String?> body = const Value.absent(),
    DateTime? occurredAt,
    Value<String?> sourceFacility = const Value.absent(),
    Value<String?> attachmentPath = const Value.absent(),
    Value<String?> extractedText = const Value.absent(),
    DateTime? createdAt,
  }) => MedicalRecordRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    authorStaffId: authorStaffId.present
        ? authorStaffId.value
        : this.authorStaffId,
    recordType: recordType ?? this.recordType,
    title: title ?? this.title,
    body: body.present ? body.value : this.body,
    occurredAt: occurredAt ?? this.occurredAt,
    sourceFacility: sourceFacility.present
        ? sourceFacility.value
        : this.sourceFacility,
    attachmentPath: attachmentPath.present
        ? attachmentPath.value
        : this.attachmentPath,
    extractedText: extractedText.present
        ? extractedText.value
        : this.extractedText,
    createdAt: createdAt ?? this.createdAt,
  );
  MedicalRecordRow copyWithCompanion(MedicalRecordsCompanion data) {
    return MedicalRecordRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      authorStaffId: data.authorStaffId.present
          ? data.authorStaffId.value
          : this.authorStaffId,
      recordType: data.recordType.present
          ? data.recordType.value
          : this.recordType,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      sourceFacility: data.sourceFacility.present
          ? data.sourceFacility.value
          : this.sourceFacility,
      attachmentPath: data.attachmentPath.present
          ? data.attachmentPath.value
          : this.attachmentPath,
      extractedText: data.extractedText.present
          ? data.extractedText.value
          : this.extractedText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicalRecordRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('authorStaffId: $authorStaffId, ')
          ..write('recordType: $recordType, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('sourceFacility: $sourceFacility, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('extractedText: $extractedText, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    authorStaffId,
    recordType,
    title,
    body,
    occurredAt,
    sourceFacility,
    attachmentPath,
    extractedText,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicalRecordRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.authorStaffId == this.authorStaffId &&
          other.recordType == this.recordType &&
          other.title == this.title &&
          other.body == this.body &&
          other.occurredAt == this.occurredAt &&
          other.sourceFacility == this.sourceFacility &&
          other.attachmentPath == this.attachmentPath &&
          other.extractedText == this.extractedText &&
          other.createdAt == this.createdAt);
}

class MedicalRecordsCompanion extends UpdateCompanion<MedicalRecordRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String?> authorStaffId;
  final Value<RecordType> recordType;
  final Value<String> title;
  final Value<String?> body;
  final Value<DateTime> occurredAt;
  final Value<String?> sourceFacility;
  final Value<String?> attachmentPath;
  final Value<String?> extractedText;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MedicalRecordsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.authorStaffId = const Value.absent(),
    this.recordType = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.sourceFacility = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.extractedText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicalRecordsCompanion.insert({
    required String id,
    required String patientId,
    this.authorStaffId = const Value.absent(),
    required RecordType recordType,
    required String title,
    this.body = const Value.absent(),
    required DateTime occurredAt,
    this.sourceFacility = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.extractedText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       recordType = Value(recordType),
       title = Value(title),
       occurredAt = Value(occurredAt);
  static Insertable<MedicalRecordRow> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? authorStaffId,
    Expression<String>? recordType,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? occurredAt,
    Expression<String>? sourceFacility,
    Expression<String>? attachmentPath,
    Expression<String>? extractedText,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (authorStaffId != null) 'author_staff_id': authorStaffId,
      if (recordType != null) 'record_type': recordType,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (sourceFacility != null) 'source_facility': sourceFacility,
      if (attachmentPath != null) 'attachment_path': attachmentPath,
      if (extractedText != null) 'extracted_text': extractedText,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicalRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String?>? authorStaffId,
    Value<RecordType>? recordType,
    Value<String>? title,
    Value<String?>? body,
    Value<DateTime>? occurredAt,
    Value<String?>? sourceFacility,
    Value<String?>? attachmentPath,
    Value<String?>? extractedText,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MedicalRecordsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      authorStaffId: authorStaffId ?? this.authorStaffId,
      recordType: recordType ?? this.recordType,
      title: title ?? this.title,
      body: body ?? this.body,
      occurredAt: occurredAt ?? this.occurredAt,
      sourceFacility: sourceFacility ?? this.sourceFacility,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      extractedText: extractedText ?? this.extractedText,
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
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (authorStaffId.present) {
      map['author_staff_id'] = Variable<String>(authorStaffId.value);
    }
    if (recordType.present) {
      map['record_type'] = Variable<String>(
        $MedicalRecordsTable.$converterrecordType.toSql(recordType.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (sourceFacility.present) {
      map['source_facility'] = Variable<String>(sourceFacility.value);
    }
    if (attachmentPath.present) {
      map['attachment_path'] = Variable<String>(attachmentPath.value);
    }
    if (extractedText.present) {
      map['extracted_text'] = Variable<String>(extractedText.value);
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
    return (StringBuffer('MedicalRecordsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('authorStaffId: $authorStaffId, ')
          ..write('recordType: $recordType, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('sourceFacility: $sourceFacility, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('extractedText: $extractedText, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LabValuesTable extends LabValues
    with TableInfo<$LabValuesTable, LabValueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LabValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medical_records (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _analyteMeta = const VerificationMeta(
    'analyte',
  );
  @override
  late final GeneratedColumn<String> analyte = GeneratedColumn<String>(
    'analyte',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refLowMeta = const VerificationMeta('refLow');
  @override
  late final GeneratedColumn<double> refLow = GeneratedColumn<double>(
    'ref_low',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refHighMeta = const VerificationMeta(
    'refHigh',
  );
  @override
  late final GeneratedColumn<double> refHigh = GeneratedColumn<double>(
    'ref_high',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AbnormalFlag, String>
  abnormalFlag = GeneratedColumn<String>(
    'abnormal_flag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  ).withConverter<AbnormalFlag>($LabValuesTable.$converterabnormalFlag);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordId,
    analyte,
    value,
    unit,
    refLow,
    refHigh,
    abnormalFlag,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lab_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<LabValueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('analyte')) {
      context.handle(
        _analyteMeta,
        analyte.isAcceptableOrUnknown(data['analyte']!, _analyteMeta),
      );
    } else if (isInserting) {
      context.missing(_analyteMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('ref_low')) {
      context.handle(
        _refLowMeta,
        refLow.isAcceptableOrUnknown(data['ref_low']!, _refLowMeta),
      );
    }
    if (data.containsKey('ref_high')) {
      context.handle(
        _refHighMeta,
        refHigh.isAcceptableOrUnknown(data['ref_high']!, _refHighMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LabValueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LabValueRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      analyte: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}analyte'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      refLow: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ref_low'],
      ),
      refHigh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ref_high'],
      ),
      abnormalFlag: $LabValuesTable.$converterabnormalFlag.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}abnormal_flag'],
        )!,
      ),
    );
  }

  @override
  $LabValuesTable createAlias(String alias) {
    return $LabValuesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AbnormalFlag, String, String>
  $converterabnormalFlag = const EnumNameConverter<AbnormalFlag>(
    AbnormalFlag.values,
  );
}

class LabValueRow extends DataClass implements Insertable<LabValueRow> {
  final String id;
  final String recordId;
  final String analyte;
  final double value;
  final String? unit;
  final double? refLow;
  final double? refHigh;
  final AbnormalFlag abnormalFlag;
  const LabValueRow({
    required this.id,
    required this.recordId,
    required this.analyte,
    required this.value,
    this.unit,
    this.refLow,
    this.refHigh,
    required this.abnormalFlag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['record_id'] = Variable<String>(recordId);
    map['analyte'] = Variable<String>(analyte);
    map['value'] = Variable<double>(value);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || refLow != null) {
      map['ref_low'] = Variable<double>(refLow);
    }
    if (!nullToAbsent || refHigh != null) {
      map['ref_high'] = Variable<double>(refHigh);
    }
    {
      map['abnormal_flag'] = Variable<String>(
        $LabValuesTable.$converterabnormalFlag.toSql(abnormalFlag),
      );
    }
    return map;
  }

  LabValuesCompanion toCompanion(bool nullToAbsent) {
    return LabValuesCompanion(
      id: Value(id),
      recordId: Value(recordId),
      analyte: Value(analyte),
      value: Value(value),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      refLow: refLow == null && nullToAbsent
          ? const Value.absent()
          : Value(refLow),
      refHigh: refHigh == null && nullToAbsent
          ? const Value.absent()
          : Value(refHigh),
      abnormalFlag: Value(abnormalFlag),
    );
  }

  factory LabValueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LabValueRow(
      id: serializer.fromJson<String>(json['id']),
      recordId: serializer.fromJson<String>(json['recordId']),
      analyte: serializer.fromJson<String>(json['analyte']),
      value: serializer.fromJson<double>(json['value']),
      unit: serializer.fromJson<String?>(json['unit']),
      refLow: serializer.fromJson<double?>(json['refLow']),
      refHigh: serializer.fromJson<double?>(json['refHigh']),
      abnormalFlag: $LabValuesTable.$converterabnormalFlag.fromJson(
        serializer.fromJson<String>(json['abnormalFlag']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recordId': serializer.toJson<String>(recordId),
      'analyte': serializer.toJson<String>(analyte),
      'value': serializer.toJson<double>(value),
      'unit': serializer.toJson<String?>(unit),
      'refLow': serializer.toJson<double?>(refLow),
      'refHigh': serializer.toJson<double?>(refHigh),
      'abnormalFlag': serializer.toJson<String>(
        $LabValuesTable.$converterabnormalFlag.toJson(abnormalFlag),
      ),
    };
  }

  LabValueRow copyWith({
    String? id,
    String? recordId,
    String? analyte,
    double? value,
    Value<String?> unit = const Value.absent(),
    Value<double?> refLow = const Value.absent(),
    Value<double?> refHigh = const Value.absent(),
    AbnormalFlag? abnormalFlag,
  }) => LabValueRow(
    id: id ?? this.id,
    recordId: recordId ?? this.recordId,
    analyte: analyte ?? this.analyte,
    value: value ?? this.value,
    unit: unit.present ? unit.value : this.unit,
    refLow: refLow.present ? refLow.value : this.refLow,
    refHigh: refHigh.present ? refHigh.value : this.refHigh,
    abnormalFlag: abnormalFlag ?? this.abnormalFlag,
  );
  LabValueRow copyWithCompanion(LabValuesCompanion data) {
    return LabValueRow(
      id: data.id.present ? data.id.value : this.id,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      analyte: data.analyte.present ? data.analyte.value : this.analyte,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
      refLow: data.refLow.present ? data.refLow.value : this.refLow,
      refHigh: data.refHigh.present ? data.refHigh.value : this.refHigh,
      abnormalFlag: data.abnormalFlag.present
          ? data.abnormalFlag.value
          : this.abnormalFlag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LabValueRow(')
          ..write('id: $id, ')
          ..write('recordId: $recordId, ')
          ..write('analyte: $analyte, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('refLow: $refLow, ')
          ..write('refHigh: $refHigh, ')
          ..write('abnormalFlag: $abnormalFlag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recordId,
    analyte,
    value,
    unit,
    refLow,
    refHigh,
    abnormalFlag,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LabValueRow &&
          other.id == this.id &&
          other.recordId == this.recordId &&
          other.analyte == this.analyte &&
          other.value == this.value &&
          other.unit == this.unit &&
          other.refLow == this.refLow &&
          other.refHigh == this.refHigh &&
          other.abnormalFlag == this.abnormalFlag);
}

class LabValuesCompanion extends UpdateCompanion<LabValueRow> {
  final Value<String> id;
  final Value<String> recordId;
  final Value<String> analyte;
  final Value<double> value;
  final Value<String?> unit;
  final Value<double?> refLow;
  final Value<double?> refHigh;
  final Value<AbnormalFlag> abnormalFlag;
  final Value<int> rowid;
  const LabValuesCompanion({
    this.id = const Value.absent(),
    this.recordId = const Value.absent(),
    this.analyte = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.refLow = const Value.absent(),
    this.refHigh = const Value.absent(),
    this.abnormalFlag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LabValuesCompanion.insert({
    required String id,
    required String recordId,
    required String analyte,
    required double value,
    this.unit = const Value.absent(),
    this.refLow = const Value.absent(),
    this.refHigh = const Value.absent(),
    this.abnormalFlag = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recordId = Value(recordId),
       analyte = Value(analyte),
       value = Value(value);
  static Insertable<LabValueRow> custom({
    Expression<String>? id,
    Expression<String>? recordId,
    Expression<String>? analyte,
    Expression<double>? value,
    Expression<String>? unit,
    Expression<double>? refLow,
    Expression<double>? refHigh,
    Expression<String>? abnormalFlag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordId != null) 'record_id': recordId,
      if (analyte != null) 'analyte': analyte,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (refLow != null) 'ref_low': refLow,
      if (refHigh != null) 'ref_high': refHigh,
      if (abnormalFlag != null) 'abnormal_flag': abnormalFlag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LabValuesCompanion copyWith({
    Value<String>? id,
    Value<String>? recordId,
    Value<String>? analyte,
    Value<double>? value,
    Value<String?>? unit,
    Value<double?>? refLow,
    Value<double?>? refHigh,
    Value<AbnormalFlag>? abnormalFlag,
    Value<int>? rowid,
  }) {
    return LabValuesCompanion(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      analyte: analyte ?? this.analyte,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      refLow: refLow ?? this.refLow,
      refHigh: refHigh ?? this.refHigh,
      abnormalFlag: abnormalFlag ?? this.abnormalFlag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (analyte.present) {
      map['analyte'] = Variable<String>(analyte.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (refLow.present) {
      map['ref_low'] = Variable<double>(refLow.value);
    }
    if (refHigh.present) {
      map['ref_high'] = Variable<double>(refHigh.value);
    }
    if (abnormalFlag.present) {
      map['abnormal_flag'] = Variable<String>(
        $LabValuesTable.$converterabnormalFlag.toSql(abnormalFlag.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LabValuesCompanion(')
          ..write('id: $id, ')
          ..write('recordId: $recordId, ')
          ..write('analyte: $analyte, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('refLow: $refLow, ')
          ..write('refHigh: $refHigh, ')
          ..write('abnormalFlag: $abnormalFlag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VitalsTable extends Vitals with TableInfo<$VitalsTable, VitalsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VitalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _systolicMeta = const VerificationMeta(
    'systolic',
  );
  @override
  late final GeneratedColumn<int> systolic = GeneratedColumn<int>(
    'systolic',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diastolicMeta = const VerificationMeta(
    'diastolic',
  );
  @override
  late final GeneratedColumn<int> diastolic = GeneratedColumn<int>(
    'diastolic',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heartRateMeta = const VerificationMeta(
    'heartRate',
  );
  @override
  late final GeneratedColumn<int> heartRate = GeneratedColumn<int>(
    'heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tempCMeta = const VerificationMeta('tempC');
  @override
  late final GeneratedColumn<double> tempC = GeneratedColumn<double>(
    'temp_c',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spo2Meta = const VerificationMeta('spo2');
  @override
  late final GeneratedColumn<int> spo2 = GeneratedColumn<int>(
    'spo2',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _glucoseMeta = const VerificationMeta(
    'glucose',
  );
  @override
  late final GeneratedColumn<double> glucose = GeneratedColumn<double>(
    'glucose',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedByStaffIdMeta = const VerificationMeta(
    'recordedByStaffId',
  );
  @override
  late final GeneratedColumn<String> recordedByStaffId =
      GeneratedColumn<String>(
        'recorded_by_staff_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES users (id)',
        ),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    recordedAt,
    systolic,
    diastolic,
    heartRate,
    tempC,
    weightKg,
    heightCm,
    spo2,
    glucose,
    recordedByStaffId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vitals';
  @override
  VerificationContext validateIntegrity(
    Insertable<VitalsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('systolic')) {
      context.handle(
        _systolicMeta,
        systolic.isAcceptableOrUnknown(data['systolic']!, _systolicMeta),
      );
    }
    if (data.containsKey('diastolic')) {
      context.handle(
        _diastolicMeta,
        diastolic.isAcceptableOrUnknown(data['diastolic']!, _diastolicMeta),
      );
    }
    if (data.containsKey('heart_rate')) {
      context.handle(
        _heartRateMeta,
        heartRate.isAcceptableOrUnknown(data['heart_rate']!, _heartRateMeta),
      );
    }
    if (data.containsKey('temp_c')) {
      context.handle(
        _tempCMeta,
        tempC.isAcceptableOrUnknown(data['temp_c']!, _tempCMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    }
    if (data.containsKey('spo2')) {
      context.handle(
        _spo2Meta,
        spo2.isAcceptableOrUnknown(data['spo2']!, _spo2Meta),
      );
    }
    if (data.containsKey('glucose')) {
      context.handle(
        _glucoseMeta,
        glucose.isAcceptableOrUnknown(data['glucose']!, _glucoseMeta),
      );
    }
    if (data.containsKey('recorded_by_staff_id')) {
      context.handle(
        _recordedByStaffIdMeta,
        recordedByStaffId.isAcceptableOrUnknown(
          data['recorded_by_staff_id']!,
          _recordedByStaffIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VitalsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VitalsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      systolic: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}systolic'],
      ),
      diastolic: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}diastolic'],
      ),
      heartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heart_rate'],
      ),
      tempC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temp_c'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      ),
      spo2: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spo2'],
      ),
      glucose: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}glucose'],
      ),
      recordedByStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by_staff_id'],
      ),
    );
  }

  @override
  $VitalsTable createAlias(String alias) {
    return $VitalsTable(attachedDatabase, alias);
  }
}

class VitalsRow extends DataClass implements Insertable<VitalsRow> {
  final String id;
  final String patientId;
  final DateTime recordedAt;
  final int? systolic;
  final int? diastolic;
  final int? heartRate;
  final double? tempC;
  final double? weightKg;
  final double? heightCm;
  final int? spo2;
  final double? glucose;

  /// Null for self-entered vitals (P2-14).
  final String? recordedByStaffId;
  const VitalsRow({
    required this.id,
    required this.patientId,
    required this.recordedAt,
    this.systolic,
    this.diastolic,
    this.heartRate,
    this.tempC,
    this.weightKg,
    this.heightCm,
    this.spo2,
    this.glucose,
    this.recordedByStaffId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || systolic != null) {
      map['systolic'] = Variable<int>(systolic);
    }
    if (!nullToAbsent || diastolic != null) {
      map['diastolic'] = Variable<int>(diastolic);
    }
    if (!nullToAbsent || heartRate != null) {
      map['heart_rate'] = Variable<int>(heartRate);
    }
    if (!nullToAbsent || tempC != null) {
      map['temp_c'] = Variable<double>(tempC);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || spo2 != null) {
      map['spo2'] = Variable<int>(spo2);
    }
    if (!nullToAbsent || glucose != null) {
      map['glucose'] = Variable<double>(glucose);
    }
    if (!nullToAbsent || recordedByStaffId != null) {
      map['recorded_by_staff_id'] = Variable<String>(recordedByStaffId);
    }
    return map;
  }

  VitalsCompanion toCompanion(bool nullToAbsent) {
    return VitalsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      recordedAt: Value(recordedAt),
      systolic: systolic == null && nullToAbsent
          ? const Value.absent()
          : Value(systolic),
      diastolic: diastolic == null && nullToAbsent
          ? const Value.absent()
          : Value(diastolic),
      heartRate: heartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(heartRate),
      tempC: tempC == null && nullToAbsent
          ? const Value.absent()
          : Value(tempC),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      spo2: spo2 == null && nullToAbsent ? const Value.absent() : Value(spo2),
      glucose: glucose == null && nullToAbsent
          ? const Value.absent()
          : Value(glucose),
      recordedByStaffId: recordedByStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(recordedByStaffId),
    );
  }

  factory VitalsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VitalsRow(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      systolic: serializer.fromJson<int?>(json['systolic']),
      diastolic: serializer.fromJson<int?>(json['diastolic']),
      heartRate: serializer.fromJson<int?>(json['heartRate']),
      tempC: serializer.fromJson<double?>(json['tempC']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      spo2: serializer.fromJson<int?>(json['spo2']),
      glucose: serializer.fromJson<double?>(json['glucose']),
      recordedByStaffId: serializer.fromJson<String?>(
        json['recordedByStaffId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'systolic': serializer.toJson<int?>(systolic),
      'diastolic': serializer.toJson<int?>(diastolic),
      'heartRate': serializer.toJson<int?>(heartRate),
      'tempC': serializer.toJson<double?>(tempC),
      'weightKg': serializer.toJson<double?>(weightKg),
      'heightCm': serializer.toJson<double?>(heightCm),
      'spo2': serializer.toJson<int?>(spo2),
      'glucose': serializer.toJson<double?>(glucose),
      'recordedByStaffId': serializer.toJson<String?>(recordedByStaffId),
    };
  }

  VitalsRow copyWith({
    String? id,
    String? patientId,
    DateTime? recordedAt,
    Value<int?> systolic = const Value.absent(),
    Value<int?> diastolic = const Value.absent(),
    Value<int?> heartRate = const Value.absent(),
    Value<double?> tempC = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<double?> heightCm = const Value.absent(),
    Value<int?> spo2 = const Value.absent(),
    Value<double?> glucose = const Value.absent(),
    Value<String?> recordedByStaffId = const Value.absent(),
  }) => VitalsRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    recordedAt: recordedAt ?? this.recordedAt,
    systolic: systolic.present ? systolic.value : this.systolic,
    diastolic: diastolic.present ? diastolic.value : this.diastolic,
    heartRate: heartRate.present ? heartRate.value : this.heartRate,
    tempC: tempC.present ? tempC.value : this.tempC,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    heightCm: heightCm.present ? heightCm.value : this.heightCm,
    spo2: spo2.present ? spo2.value : this.spo2,
    glucose: glucose.present ? glucose.value : this.glucose,
    recordedByStaffId: recordedByStaffId.present
        ? recordedByStaffId.value
        : this.recordedByStaffId,
  );
  VitalsRow copyWithCompanion(VitalsCompanion data) {
    return VitalsRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      systolic: data.systolic.present ? data.systolic.value : this.systolic,
      diastolic: data.diastolic.present ? data.diastolic.value : this.diastolic,
      heartRate: data.heartRate.present ? data.heartRate.value : this.heartRate,
      tempC: data.tempC.present ? data.tempC.value : this.tempC,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      spo2: data.spo2.present ? data.spo2.value : this.spo2,
      glucose: data.glucose.present ? data.glucose.value : this.glucose,
      recordedByStaffId: data.recordedByStaffId.present
          ? data.recordedByStaffId.value
          : this.recordedByStaffId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VitalsRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('systolic: $systolic, ')
          ..write('diastolic: $diastolic, ')
          ..write('heartRate: $heartRate, ')
          ..write('tempC: $tempC, ')
          ..write('weightKg: $weightKg, ')
          ..write('heightCm: $heightCm, ')
          ..write('spo2: $spo2, ')
          ..write('glucose: $glucose, ')
          ..write('recordedByStaffId: $recordedByStaffId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    recordedAt,
    systolic,
    diastolic,
    heartRate,
    tempC,
    weightKg,
    heightCm,
    spo2,
    glucose,
    recordedByStaffId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VitalsRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.recordedAt == this.recordedAt &&
          other.systolic == this.systolic &&
          other.diastolic == this.diastolic &&
          other.heartRate == this.heartRate &&
          other.tempC == this.tempC &&
          other.weightKg == this.weightKg &&
          other.heightCm == this.heightCm &&
          other.spo2 == this.spo2 &&
          other.glucose == this.glucose &&
          other.recordedByStaffId == this.recordedByStaffId);
}

class VitalsCompanion extends UpdateCompanion<VitalsRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<DateTime> recordedAt;
  final Value<int?> systolic;
  final Value<int?> diastolic;
  final Value<int?> heartRate;
  final Value<double?> tempC;
  final Value<double?> weightKg;
  final Value<double?> heightCm;
  final Value<int?> spo2;
  final Value<double?> glucose;
  final Value<String?> recordedByStaffId;
  final Value<int> rowid;
  const VitalsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.systolic = const Value.absent(),
    this.diastolic = const Value.absent(),
    this.heartRate = const Value.absent(),
    this.tempC = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.spo2 = const Value.absent(),
    this.glucose = const Value.absent(),
    this.recordedByStaffId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VitalsCompanion.insert({
    required String id,
    required String patientId,
    required DateTime recordedAt,
    this.systolic = const Value.absent(),
    this.diastolic = const Value.absent(),
    this.heartRate = const Value.absent(),
    this.tempC = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.spo2 = const Value.absent(),
    this.glucose = const Value.absent(),
    this.recordedByStaffId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       recordedAt = Value(recordedAt);
  static Insertable<VitalsRow> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<DateTime>? recordedAt,
    Expression<int>? systolic,
    Expression<int>? diastolic,
    Expression<int>? heartRate,
    Expression<double>? tempC,
    Expression<double>? weightKg,
    Expression<double>? heightCm,
    Expression<int>? spo2,
    Expression<double>? glucose,
    Expression<String>? recordedByStaffId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (systolic != null) 'systolic': systolic,
      if (diastolic != null) 'diastolic': diastolic,
      if (heartRate != null) 'heart_rate': heartRate,
      if (tempC != null) 'temp_c': tempC,
      if (weightKg != null) 'weight_kg': weightKg,
      if (heightCm != null) 'height_cm': heightCm,
      if (spo2 != null) 'spo2': spo2,
      if (glucose != null) 'glucose': glucose,
      if (recordedByStaffId != null) 'recorded_by_staff_id': recordedByStaffId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VitalsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<DateTime>? recordedAt,
    Value<int?>? systolic,
    Value<int?>? diastolic,
    Value<int?>? heartRate,
    Value<double?>? tempC,
    Value<double?>? weightKg,
    Value<double?>? heightCm,
    Value<int?>? spo2,
    Value<double?>? glucose,
    Value<String?>? recordedByStaffId,
    Value<int>? rowid,
  }) {
    return VitalsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      recordedAt: recordedAt ?? this.recordedAt,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      heartRate: heartRate ?? this.heartRate,
      tempC: tempC ?? this.tempC,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      spo2: spo2 ?? this.spo2,
      glucose: glucose ?? this.glucose,
      recordedByStaffId: recordedByStaffId ?? this.recordedByStaffId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (systolic.present) {
      map['systolic'] = Variable<int>(systolic.value);
    }
    if (diastolic.present) {
      map['diastolic'] = Variable<int>(diastolic.value);
    }
    if (heartRate.present) {
      map['heart_rate'] = Variable<int>(heartRate.value);
    }
    if (tempC.present) {
      map['temp_c'] = Variable<double>(tempC.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (spo2.present) {
      map['spo2'] = Variable<int>(spo2.value);
    }
    if (glucose.present) {
      map['glucose'] = Variable<double>(glucose.value);
    }
    if (recordedByStaffId.present) {
      map['recorded_by_staff_id'] = Variable<String>(recordedByStaffId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VitalsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('systolic: $systolic, ')
          ..write('diastolic: $diastolic, ')
          ..write('heartRate: $heartRate, ')
          ..write('tempC: $tempC, ')
          ..write('weightKg: $weightKg, ')
          ..write('heightCm: $heightCm, ')
          ..write('spo2: $spo2, ')
          ..write('glucose: $glucose, ')
          ..write('recordedByStaffId: $recordedByStaffId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationsTable extends Medications
    with TableInfo<$MedicationsTable, MedicationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _prescriberIdMeta = const VerificationMeta(
    'prescriberId',
  );
  @override
  late final GeneratedColumn<String> prescriberId = GeneratedColumn<String>(
    'prescriber_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doseMeta = const VerificationMeta('dose');
  @override
  late final GeneratedColumn<String> dose = GeneratedColumn<String>(
    'dose',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    prescriberId,
    name,
    dose,
    frequency,
    startDate,
    endDate,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('prescriber_id')) {
      context.handle(
        _prescriberIdMeta,
        prescriberId.isAcceptableOrUnknown(
          data['prescriber_id']!,
          _prescriberIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dose')) {
      context.handle(
        _doseMeta,
        dose.isAcceptableOrUnknown(data['dose']!, _doseMeta),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      prescriberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prescriber_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      dose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dose'],
      ),
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $MedicationsTable createAlias(String alias) {
    return $MedicationsTable(attachedDatabase, alias);
  }
}

class MedicationRow extends DataClass implements Insertable<MedicationRow> {
  final String id;
  final String patientId;
  final String? prescriberId;
  final String name;
  final String? dose;
  final String? frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  const MedicationRow({
    required this.id,
    required this.patientId,
    this.prescriberId,
    required this.name,
    this.dose,
    this.frequency,
    required this.startDate,
    this.endDate,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    if (!nullToAbsent || prescriberId != null) {
      map['prescriber_id'] = Variable<String>(prescriberId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || dose != null) {
      map['dose'] = Variable<String>(dose);
    }
    if (!nullToAbsent || frequency != null) {
      map['frequency'] = Variable<String>(frequency);
    }
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      prescriberId: prescriberId == null && nullToAbsent
          ? const Value.absent()
          : Value(prescriberId),
      name: Value(name),
      dose: dose == null && nullToAbsent ? const Value.absent() : Value(dose),
      frequency: frequency == null && nullToAbsent
          ? const Value.absent()
          : Value(frequency),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      isActive: Value(isActive),
    );
  }

  factory MedicationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationRow(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      prescriberId: serializer.fromJson<String?>(json['prescriberId']),
      name: serializer.fromJson<String>(json['name']),
      dose: serializer.fromJson<String?>(json['dose']),
      frequency: serializer.fromJson<String?>(json['frequency']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'prescriberId': serializer.toJson<String?>(prescriberId),
      'name': serializer.toJson<String>(name),
      'dose': serializer.toJson<String?>(dose),
      'frequency': serializer.toJson<String?>(frequency),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  MedicationRow copyWith({
    String? id,
    String? patientId,
    Value<String?> prescriberId = const Value.absent(),
    String? name,
    Value<String?> dose = const Value.absent(),
    Value<String?> frequency = const Value.absent(),
    DateTime? startDate,
    Value<DateTime?> endDate = const Value.absent(),
    bool? isActive,
  }) => MedicationRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    prescriberId: prescriberId.present ? prescriberId.value : this.prescriberId,
    name: name ?? this.name,
    dose: dose.present ? dose.value : this.dose,
    frequency: frequency.present ? frequency.value : this.frequency,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    isActive: isActive ?? this.isActive,
  );
  MedicationRow copyWithCompanion(MedicationsCompanion data) {
    return MedicationRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      prescriberId: data.prescriberId.present
          ? data.prescriberId.value
          : this.prescriberId,
      name: data.name.present ? data.name.value : this.name,
      dose: data.dose.present ? data.dose.value : this.dose,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('prescriberId: $prescriberId, ')
          ..write('name: $name, ')
          ..write('dose: $dose, ')
          ..write('frequency: $frequency, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    prescriberId,
    name,
    dose,
    frequency,
    startDate,
    endDate,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.prescriberId == this.prescriberId &&
          other.name == this.name &&
          other.dose == this.dose &&
          other.frequency == this.frequency &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.isActive == this.isActive);
}

class MedicationsCompanion extends UpdateCompanion<MedicationRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String?> prescriberId;
  final Value<String> name;
  final Value<String?> dose;
  final Value<String?> frequency;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<bool> isActive;
  final Value<int> rowid;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.prescriberId = const Value.absent(),
    this.name = const Value.absent(),
    this.dose = const Value.absent(),
    this.frequency = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationsCompanion.insert({
    required String id,
    required String patientId,
    this.prescriberId = const Value.absent(),
    required String name,
    this.dose = const Value.absent(),
    this.frequency = const Value.absent(),
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       name = Value(name),
       startDate = Value(startDate);
  static Insertable<MedicationRow> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? prescriberId,
    Expression<String>? name,
    Expression<String>? dose,
    Expression<String>? frequency,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (prescriberId != null) 'prescriber_id': prescriberId,
      if (name != null) 'name': name,
      if (dose != null) 'dose': dose,
      if (frequency != null) 'frequency': frequency,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String?>? prescriberId,
    Value<String>? name,
    Value<String?>? dose,
    Value<String?>? frequency,
    Value<DateTime>? startDate,
    Value<DateTime?>? endDate,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return MedicationsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      prescriberId: prescriberId ?? this.prescriberId,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (prescriberId.present) {
      map['prescriber_id'] = Variable<String>(prescriberId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dose.present) {
      map['dose'] = Variable<String>(dose.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('prescriberId: $prescriberId, ')
          ..write('name: $name, ')
          ..write('dose: $dose, ')
          ..write('frequency: $frequency, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiSummariesTable extends AiSummaries
    with TableInfo<$AiSummariesTable, AiSummaryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiSummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _generatedAtMeta = const VerificationMeta(
    'generatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
    'generated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptVersionMeta = const VerificationMeta(
    'promptVersion',
  );
  @override
  late final GeneratedColumn<String> promptVersion = GeneratedColumn<String>(
    'prompt_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMarkdownMeta = const VerificationMeta(
    'summaryMarkdown',
  );
  @override
  late final GeneratedColumn<String> summaryMarkdown = GeneratedColumn<String>(
    'summary_markdown',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyEventsJsonMeta = const VerificationMeta(
    'keyEventsJson',
  );
  @override
  late final GeneratedColumn<String> keyEventsJson = GeneratedColumn<String>(
    'key_events_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _trendsJsonMeta = const VerificationMeta(
    'trendsJson',
  );
  @override
  late final GeneratedColumn<String> trendsJson = GeneratedColumn<String>(
    'trends_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _redFlagsJsonMeta = const VerificationMeta(
    'redFlagsJson',
  );
  @override
  late final GeneratedColumn<String> redFlagsJson = GeneratedColumn<String>(
    'red_flags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _inputHashMeta = const VerificationMeta(
    'inputHash',
  );
  @override
  late final GeneratedColumn<String> inputHash = GeneratedColumn<String>(
    'input_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    generatedAt,
    modelId,
    promptVersion,
    summaryMarkdown,
    keyEventsJson,
    trendsJson,
    redFlagsJson,
    inputHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_summaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiSummaryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
        _generatedAtMeta,
        generatedAt.isAcceptableOrUnknown(
          data['generated_at']!,
          _generatedAtMeta,
        ),
      );
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('prompt_version')) {
      context.handle(
        _promptVersionMeta,
        promptVersion.isAcceptableOrUnknown(
          data['prompt_version']!,
          _promptVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_promptVersionMeta);
    }
    if (data.containsKey('summary_markdown')) {
      context.handle(
        _summaryMarkdownMeta,
        summaryMarkdown.isAcceptableOrUnknown(
          data['summary_markdown']!,
          _summaryMarkdownMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_summaryMarkdownMeta);
    }
    if (data.containsKey('key_events_json')) {
      context.handle(
        _keyEventsJsonMeta,
        keyEventsJson.isAcceptableOrUnknown(
          data['key_events_json']!,
          _keyEventsJsonMeta,
        ),
      );
    }
    if (data.containsKey('trends_json')) {
      context.handle(
        _trendsJsonMeta,
        trendsJson.isAcceptableOrUnknown(data['trends_json']!, _trendsJsonMeta),
      );
    }
    if (data.containsKey('red_flags_json')) {
      context.handle(
        _redFlagsJsonMeta,
        redFlagsJson.isAcceptableOrUnknown(
          data['red_flags_json']!,
          _redFlagsJsonMeta,
        ),
      );
    }
    if (data.containsKey('input_hash')) {
      context.handle(
        _inputHashMeta,
        inputHash.isAcceptableOrUnknown(data['input_hash']!, _inputHashMeta),
      );
    } else if (isInserting) {
      context.missing(_inputHashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiSummaryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiSummaryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      generatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}generated_at'],
      )!,
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      )!,
      promptVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt_version'],
      )!,
      summaryMarkdown: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_markdown'],
      )!,
      keyEventsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_events_json'],
      )!,
      trendsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trends_json'],
      )!,
      redFlagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}red_flags_json'],
      )!,
      inputHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_hash'],
      )!,
    );
  }

  @override
  $AiSummariesTable createAlias(String alias) {
    return $AiSummariesTable(attachedDatabase, alias);
  }
}

class AiSummaryRow extends DataClass implements Insertable<AiSummaryRow> {
  final String id;
  final String patientId;
  final DateTime generatedAt;

  /// Traceability (P3-14).
  final String modelId;
  final String promptVersion;
  final String summaryMarkdown;

  /// JSON arrays — parsed into typed models by the AI layer.
  final String keyEventsJson;
  final String trendsJson;
  final String redFlagsJson;

  /// Hash of the context the summary was generated from (cache key).
  final String inputHash;
  const AiSummaryRow({
    required this.id,
    required this.patientId,
    required this.generatedAt,
    required this.modelId,
    required this.promptVersion,
    required this.summaryMarkdown,
    required this.keyEventsJson,
    required this.trendsJson,
    required this.redFlagsJson,
    required this.inputHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['model_id'] = Variable<String>(modelId);
    map['prompt_version'] = Variable<String>(promptVersion);
    map['summary_markdown'] = Variable<String>(summaryMarkdown);
    map['key_events_json'] = Variable<String>(keyEventsJson);
    map['trends_json'] = Variable<String>(trendsJson);
    map['red_flags_json'] = Variable<String>(redFlagsJson);
    map['input_hash'] = Variable<String>(inputHash);
    return map;
  }

  AiSummariesCompanion toCompanion(bool nullToAbsent) {
    return AiSummariesCompanion(
      id: Value(id),
      patientId: Value(patientId),
      generatedAt: Value(generatedAt),
      modelId: Value(modelId),
      promptVersion: Value(promptVersion),
      summaryMarkdown: Value(summaryMarkdown),
      keyEventsJson: Value(keyEventsJson),
      trendsJson: Value(trendsJson),
      redFlagsJson: Value(redFlagsJson),
      inputHash: Value(inputHash),
    );
  }

  factory AiSummaryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiSummaryRow(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      modelId: serializer.fromJson<String>(json['modelId']),
      promptVersion: serializer.fromJson<String>(json['promptVersion']),
      summaryMarkdown: serializer.fromJson<String>(json['summaryMarkdown']),
      keyEventsJson: serializer.fromJson<String>(json['keyEventsJson']),
      trendsJson: serializer.fromJson<String>(json['trendsJson']),
      redFlagsJson: serializer.fromJson<String>(json['redFlagsJson']),
      inputHash: serializer.fromJson<String>(json['inputHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'modelId': serializer.toJson<String>(modelId),
      'promptVersion': serializer.toJson<String>(promptVersion),
      'summaryMarkdown': serializer.toJson<String>(summaryMarkdown),
      'keyEventsJson': serializer.toJson<String>(keyEventsJson),
      'trendsJson': serializer.toJson<String>(trendsJson),
      'redFlagsJson': serializer.toJson<String>(redFlagsJson),
      'inputHash': serializer.toJson<String>(inputHash),
    };
  }

  AiSummaryRow copyWith({
    String? id,
    String? patientId,
    DateTime? generatedAt,
    String? modelId,
    String? promptVersion,
    String? summaryMarkdown,
    String? keyEventsJson,
    String? trendsJson,
    String? redFlagsJson,
    String? inputHash,
  }) => AiSummaryRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    generatedAt: generatedAt ?? this.generatedAt,
    modelId: modelId ?? this.modelId,
    promptVersion: promptVersion ?? this.promptVersion,
    summaryMarkdown: summaryMarkdown ?? this.summaryMarkdown,
    keyEventsJson: keyEventsJson ?? this.keyEventsJson,
    trendsJson: trendsJson ?? this.trendsJson,
    redFlagsJson: redFlagsJson ?? this.redFlagsJson,
    inputHash: inputHash ?? this.inputHash,
  );
  AiSummaryRow copyWithCompanion(AiSummariesCompanion data) {
    return AiSummaryRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      generatedAt: data.generatedAt.present
          ? data.generatedAt.value
          : this.generatedAt,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      promptVersion: data.promptVersion.present
          ? data.promptVersion.value
          : this.promptVersion,
      summaryMarkdown: data.summaryMarkdown.present
          ? data.summaryMarkdown.value
          : this.summaryMarkdown,
      keyEventsJson: data.keyEventsJson.present
          ? data.keyEventsJson.value
          : this.keyEventsJson,
      trendsJson: data.trendsJson.present
          ? data.trendsJson.value
          : this.trendsJson,
      redFlagsJson: data.redFlagsJson.present
          ? data.redFlagsJson.value
          : this.redFlagsJson,
      inputHash: data.inputHash.present ? data.inputHash.value : this.inputHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiSummaryRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('modelId: $modelId, ')
          ..write('promptVersion: $promptVersion, ')
          ..write('summaryMarkdown: $summaryMarkdown, ')
          ..write('keyEventsJson: $keyEventsJson, ')
          ..write('trendsJson: $trendsJson, ')
          ..write('redFlagsJson: $redFlagsJson, ')
          ..write('inputHash: $inputHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    generatedAt,
    modelId,
    promptVersion,
    summaryMarkdown,
    keyEventsJson,
    trendsJson,
    redFlagsJson,
    inputHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiSummaryRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.generatedAt == this.generatedAt &&
          other.modelId == this.modelId &&
          other.promptVersion == this.promptVersion &&
          other.summaryMarkdown == this.summaryMarkdown &&
          other.keyEventsJson == this.keyEventsJson &&
          other.trendsJson == this.trendsJson &&
          other.redFlagsJson == this.redFlagsJson &&
          other.inputHash == this.inputHash);
}

class AiSummariesCompanion extends UpdateCompanion<AiSummaryRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<DateTime> generatedAt;
  final Value<String> modelId;
  final Value<String> promptVersion;
  final Value<String> summaryMarkdown;
  final Value<String> keyEventsJson;
  final Value<String> trendsJson;
  final Value<String> redFlagsJson;
  final Value<String> inputHash;
  final Value<int> rowid;
  const AiSummariesCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.modelId = const Value.absent(),
    this.promptVersion = const Value.absent(),
    this.summaryMarkdown = const Value.absent(),
    this.keyEventsJson = const Value.absent(),
    this.trendsJson = const Value.absent(),
    this.redFlagsJson = const Value.absent(),
    this.inputHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiSummariesCompanion.insert({
    required String id,
    required String patientId,
    this.generatedAt = const Value.absent(),
    required String modelId,
    required String promptVersion,
    required String summaryMarkdown,
    this.keyEventsJson = const Value.absent(),
    this.trendsJson = const Value.absent(),
    this.redFlagsJson = const Value.absent(),
    required String inputHash,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       modelId = Value(modelId),
       promptVersion = Value(promptVersion),
       summaryMarkdown = Value(summaryMarkdown),
       inputHash = Value(inputHash);
  static Insertable<AiSummaryRow> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<DateTime>? generatedAt,
    Expression<String>? modelId,
    Expression<String>? promptVersion,
    Expression<String>? summaryMarkdown,
    Expression<String>? keyEventsJson,
    Expression<String>? trendsJson,
    Expression<String>? redFlagsJson,
    Expression<String>? inputHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (modelId != null) 'model_id': modelId,
      if (promptVersion != null) 'prompt_version': promptVersion,
      if (summaryMarkdown != null) 'summary_markdown': summaryMarkdown,
      if (keyEventsJson != null) 'key_events_json': keyEventsJson,
      if (trendsJson != null) 'trends_json': trendsJson,
      if (redFlagsJson != null) 'red_flags_json': redFlagsJson,
      if (inputHash != null) 'input_hash': inputHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiSummariesCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<DateTime>? generatedAt,
    Value<String>? modelId,
    Value<String>? promptVersion,
    Value<String>? summaryMarkdown,
    Value<String>? keyEventsJson,
    Value<String>? trendsJson,
    Value<String>? redFlagsJson,
    Value<String>? inputHash,
    Value<int>? rowid,
  }) {
    return AiSummariesCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      generatedAt: generatedAt ?? this.generatedAt,
      modelId: modelId ?? this.modelId,
      promptVersion: promptVersion ?? this.promptVersion,
      summaryMarkdown: summaryMarkdown ?? this.summaryMarkdown,
      keyEventsJson: keyEventsJson ?? this.keyEventsJson,
      trendsJson: trendsJson ?? this.trendsJson,
      redFlagsJson: redFlagsJson ?? this.redFlagsJson,
      inputHash: inputHash ?? this.inputHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (promptVersion.present) {
      map['prompt_version'] = Variable<String>(promptVersion.value);
    }
    if (summaryMarkdown.present) {
      map['summary_markdown'] = Variable<String>(summaryMarkdown.value);
    }
    if (keyEventsJson.present) {
      map['key_events_json'] = Variable<String>(keyEventsJson.value);
    }
    if (trendsJson.present) {
      map['trends_json'] = Variable<String>(trendsJson.value);
    }
    if (redFlagsJson.present) {
      map['red_flags_json'] = Variable<String>(redFlagsJson.value);
    }
    if (inputHash.present) {
      map['input_hash'] = Variable<String>(inputHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiSummariesCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('modelId: $modelId, ')
          ..write('promptVersion: $promptVersion, ')
          ..write('summaryMarkdown: $summaryMarkdown, ')
          ..write('keyEventsJson: $keyEventsJson, ')
          ..write('trendsJson: $trendsJson, ')
          ..write('redFlagsJson: $redFlagsJson, ')
          ..write('inputHash: $inputHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StaffTasksTable extends StaffTasks
    with TableInfo<$StaffTasksTable, StaffTaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StaffTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _staffIdMeta = const VerificationMeta(
    'staffId',
  );
  @override
  late final GeneratedColumn<String> staffId = GeneratedColumn<String>(
    'staff_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TaskKind>($StaffTasksTable.$converterkind);
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('open'),
      ).withConverter<TaskStatus>($StaffTasksTable.$converterstatus);
  static const VerificationMeta _ruleScoreMeta = const VerificationMeta(
    'ruleScore',
  );
  @override
  late final GeneratedColumn<double> ruleScore = GeneratedColumn<double>(
    'rule_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _aiPriorityScoreMeta = const VerificationMeta(
    'aiPriorityScore',
  );
  @override
  late final GeneratedColumn<double> aiPriorityScore = GeneratedColumn<double>(
    'ai_priority_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiRationaleMeta = const VerificationMeta(
    'aiRationale',
  );
  @override
  late final GeneratedColumn<String> aiRationale = GeneratedColumn<String>(
    'ai_rationale',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    staffId,
    patientId,
    title,
    kind,
    dueAt,
    status,
    ruleScore,
    aiPriorityScore,
    aiRationale,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staff_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<StaffTaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('staff_id')) {
      context.handle(
        _staffIdMeta,
        staffId.isAcceptableOrUnknown(data['staff_id']!, _staffIdMeta),
      );
    } else if (isInserting) {
      context.missing(_staffIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
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
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('rule_score')) {
      context.handle(
        _ruleScoreMeta,
        ruleScore.isAcceptableOrUnknown(data['rule_score']!, _ruleScoreMeta),
      );
    }
    if (data.containsKey('ai_priority_score')) {
      context.handle(
        _aiPriorityScoreMeta,
        aiPriorityScore.isAcceptableOrUnknown(
          data['ai_priority_score']!,
          _aiPriorityScoreMeta,
        ),
      );
    }
    if (data.containsKey('ai_rationale')) {
      context.handle(
        _aiRationaleMeta,
        aiRationale.isAcceptableOrUnknown(
          data['ai_rationale']!,
          _aiRationaleMeta,
        ),
      );
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
  StaffTaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StaffTaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      staffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staff_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      kind: $StaffTasksTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      status: $StaffTasksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      ruleScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rule_score'],
      )!,
      aiPriorityScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ai_priority_score'],
      ),
      aiRationale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_rationale'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StaffTasksTable createAlias(String alias) {
    return $StaffTasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskKind, String, String> $converterkind =
      const EnumNameConverter<TaskKind>(TaskKind.values);
  static JsonTypeConverter2<TaskStatus, String, String> $converterstatus =
      const EnumNameConverter<TaskStatus>(TaskStatus.values);
}

class StaffTaskRow extends DataClass implements Insertable<StaffTaskRow> {
  final String id;
  final String staffId;
  final String? patientId;
  final String title;
  final TaskKind kind;
  final DateTime? dueAt;
  final TaskStatus status;

  /// Deterministic rule score (P5-03) — always present.
  final double ruleScore;

  /// LLM priority + rationale (P5-10) — null when AI is off.
  final double? aiPriorityScore;
  final String? aiRationale;
  final DateTime createdAt;
  const StaffTaskRow({
    required this.id,
    required this.staffId,
    this.patientId,
    required this.title,
    required this.kind,
    this.dueAt,
    required this.status,
    required this.ruleScore,
    this.aiPriorityScore,
    this.aiRationale,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['staff_id'] = Variable<String>(staffId);
    if (!nullToAbsent || patientId != null) {
      map['patient_id'] = Variable<String>(patientId);
    }
    map['title'] = Variable<String>(title);
    {
      map['kind'] = Variable<String>(
        $StaffTasksTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    {
      map['status'] = Variable<String>(
        $StaffTasksTable.$converterstatus.toSql(status),
      );
    }
    map['rule_score'] = Variable<double>(ruleScore);
    if (!nullToAbsent || aiPriorityScore != null) {
      map['ai_priority_score'] = Variable<double>(aiPriorityScore);
    }
    if (!nullToAbsent || aiRationale != null) {
      map['ai_rationale'] = Variable<String>(aiRationale);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StaffTasksCompanion toCompanion(bool nullToAbsent) {
    return StaffTasksCompanion(
      id: Value(id),
      staffId: Value(staffId),
      patientId: patientId == null && nullToAbsent
          ? const Value.absent()
          : Value(patientId),
      title: Value(title),
      kind: Value(kind),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      status: Value(status),
      ruleScore: Value(ruleScore),
      aiPriorityScore: aiPriorityScore == null && nullToAbsent
          ? const Value.absent()
          : Value(aiPriorityScore),
      aiRationale: aiRationale == null && nullToAbsent
          ? const Value.absent()
          : Value(aiRationale),
      createdAt: Value(createdAt),
    );
  }

  factory StaffTaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StaffTaskRow(
      id: serializer.fromJson<String>(json['id']),
      staffId: serializer.fromJson<String>(json['staffId']),
      patientId: serializer.fromJson<String?>(json['patientId']),
      title: serializer.fromJson<String>(json['title']),
      kind: $StaffTasksTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      status: $StaffTasksTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      ruleScore: serializer.fromJson<double>(json['ruleScore']),
      aiPriorityScore: serializer.fromJson<double?>(json['aiPriorityScore']),
      aiRationale: serializer.fromJson<String?>(json['aiRationale']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'staffId': serializer.toJson<String>(staffId),
      'patientId': serializer.toJson<String?>(patientId),
      'title': serializer.toJson<String>(title),
      'kind': serializer.toJson<String>(
        $StaffTasksTable.$converterkind.toJson(kind),
      ),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'status': serializer.toJson<String>(
        $StaffTasksTable.$converterstatus.toJson(status),
      ),
      'ruleScore': serializer.toJson<double>(ruleScore),
      'aiPriorityScore': serializer.toJson<double?>(aiPriorityScore),
      'aiRationale': serializer.toJson<String?>(aiRationale),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StaffTaskRow copyWith({
    String? id,
    String? staffId,
    Value<String?> patientId = const Value.absent(),
    String? title,
    TaskKind? kind,
    Value<DateTime?> dueAt = const Value.absent(),
    TaskStatus? status,
    double? ruleScore,
    Value<double?> aiPriorityScore = const Value.absent(),
    Value<String?> aiRationale = const Value.absent(),
    DateTime? createdAt,
  }) => StaffTaskRow(
    id: id ?? this.id,
    staffId: staffId ?? this.staffId,
    patientId: patientId.present ? patientId.value : this.patientId,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    status: status ?? this.status,
    ruleScore: ruleScore ?? this.ruleScore,
    aiPriorityScore: aiPriorityScore.present
        ? aiPriorityScore.value
        : this.aiPriorityScore,
    aiRationale: aiRationale.present ? aiRationale.value : this.aiRationale,
    createdAt: createdAt ?? this.createdAt,
  );
  StaffTaskRow copyWithCompanion(StaffTasksCompanion data) {
    return StaffTaskRow(
      id: data.id.present ? data.id.value : this.id,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      title: data.title.present ? data.title.value : this.title,
      kind: data.kind.present ? data.kind.value : this.kind,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      status: data.status.present ? data.status.value : this.status,
      ruleScore: data.ruleScore.present ? data.ruleScore.value : this.ruleScore,
      aiPriorityScore: data.aiPriorityScore.present
          ? data.aiPriorityScore.value
          : this.aiPriorityScore,
      aiRationale: data.aiRationale.present
          ? data.aiRationale.value
          : this.aiRationale,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StaffTaskRow(')
          ..write('id: $id, ')
          ..write('staffId: $staffId, ')
          ..write('patientId: $patientId, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('dueAt: $dueAt, ')
          ..write('status: $status, ')
          ..write('ruleScore: $ruleScore, ')
          ..write('aiPriorityScore: $aiPriorityScore, ')
          ..write('aiRationale: $aiRationale, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    staffId,
    patientId,
    title,
    kind,
    dueAt,
    status,
    ruleScore,
    aiPriorityScore,
    aiRationale,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaffTaskRow &&
          other.id == this.id &&
          other.staffId == this.staffId &&
          other.patientId == this.patientId &&
          other.title == this.title &&
          other.kind == this.kind &&
          other.dueAt == this.dueAt &&
          other.status == this.status &&
          other.ruleScore == this.ruleScore &&
          other.aiPriorityScore == this.aiPriorityScore &&
          other.aiRationale == this.aiRationale &&
          other.createdAt == this.createdAt);
}

class StaffTasksCompanion extends UpdateCompanion<StaffTaskRow> {
  final Value<String> id;
  final Value<String> staffId;
  final Value<String?> patientId;
  final Value<String> title;
  final Value<TaskKind> kind;
  final Value<DateTime?> dueAt;
  final Value<TaskStatus> status;
  final Value<double> ruleScore;
  final Value<double?> aiPriorityScore;
  final Value<String?> aiRationale;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StaffTasksCompanion({
    this.id = const Value.absent(),
    this.staffId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.title = const Value.absent(),
    this.kind = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.status = const Value.absent(),
    this.ruleScore = const Value.absent(),
    this.aiPriorityScore = const Value.absent(),
    this.aiRationale = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StaffTasksCompanion.insert({
    required String id,
    required String staffId,
    this.patientId = const Value.absent(),
    required String title,
    required TaskKind kind,
    this.dueAt = const Value.absent(),
    this.status = const Value.absent(),
    this.ruleScore = const Value.absent(),
    this.aiPriorityScore = const Value.absent(),
    this.aiRationale = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       staffId = Value(staffId),
       title = Value(title),
       kind = Value(kind);
  static Insertable<StaffTaskRow> custom({
    Expression<String>? id,
    Expression<String>? staffId,
    Expression<String>? patientId,
    Expression<String>? title,
    Expression<String>? kind,
    Expression<DateTime>? dueAt,
    Expression<String>? status,
    Expression<double>? ruleScore,
    Expression<double>? aiPriorityScore,
    Expression<String>? aiRationale,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (staffId != null) 'staff_id': staffId,
      if (patientId != null) 'patient_id': patientId,
      if (title != null) 'title': title,
      if (kind != null) 'kind': kind,
      if (dueAt != null) 'due_at': dueAt,
      if (status != null) 'status': status,
      if (ruleScore != null) 'rule_score': ruleScore,
      if (aiPriorityScore != null) 'ai_priority_score': aiPriorityScore,
      if (aiRationale != null) 'ai_rationale': aiRationale,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StaffTasksCompanion copyWith({
    Value<String>? id,
    Value<String>? staffId,
    Value<String?>? patientId,
    Value<String>? title,
    Value<TaskKind>? kind,
    Value<DateTime?>? dueAt,
    Value<TaskStatus>? status,
    Value<double>? ruleScore,
    Value<double?>? aiPriorityScore,
    Value<String?>? aiRationale,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return StaffTasksCompanion(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      dueAt: dueAt ?? this.dueAt,
      status: status ?? this.status,
      ruleScore: ruleScore ?? this.ruleScore,
      aiPriorityScore: aiPriorityScore ?? this.aiPriorityScore,
      aiRationale: aiRationale ?? this.aiRationale,
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
    if (staffId.present) {
      map['staff_id'] = Variable<String>(staffId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $StaffTasksTable.$converterkind.toSql(kind.value),
      );
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $StaffTasksTable.$converterstatus.toSql(status.value),
      );
    }
    if (ruleScore.present) {
      map['rule_score'] = Variable<double>(ruleScore.value);
    }
    if (aiPriorityScore.present) {
      map['ai_priority_score'] = Variable<double>(aiPriorityScore.value);
    }
    if (aiRationale.present) {
      map['ai_rationale'] = Variable<String>(aiRationale.value);
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
    return (StringBuffer('StaffTasksCompanion(')
          ..write('id: $id, ')
          ..write('staffId: $staffId, ')
          ..write('patientId: $patientId, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('dueAt: $dueAt, ')
          ..write('status: $status, ')
          ..write('ruleScore: $ruleScore, ')
          ..write('aiPriorityScore: $aiPriorityScore, ')
          ..write('aiRationale: $aiRationale, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RiskFlagsTable extends RiskFlags
    with TableInfo<$RiskFlagsTable, RiskFlagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RiskFlagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<RiskFlagKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RiskFlagKind>($RiskFlagsTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<Severity, String> severity =
      GeneratedColumn<String>(
        'severity',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Severity>($RiskFlagsTable.$converterseverity);
  static const VerificationMeta _rationaleMeta = const VerificationMeta(
    'rationale',
  );
  @override
  late final GeneratedColumn<String> rationale = GeneratedColumn<String>(
    'rationale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detectedAtMeta = const VerificationMeta(
    'detectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> detectedAt = GeneratedColumn<DateTime>(
    'detected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FlagSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('rule'),
      ).withConverter<FlagSource>($RiskFlagsTable.$convertersource);
  static const VerificationMeta _dedupeKeyMeta = const VerificationMeta(
    'dedupeKey',
  );
  @override
  late final GeneratedColumn<String> dedupeKey = GeneratedColumn<String>(
    'dedupe_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acknowledgedByMeta = const VerificationMeta(
    'acknowledgedBy',
  );
  @override
  late final GeneratedColumn<String> acknowledgedBy = GeneratedColumn<String>(
    'acknowledged_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _acknowledgedAtMeta = const VerificationMeta(
    'acknowledgedAt',
  );
  @override
  late final GeneratedColumn<DateTime> acknowledgedAt =
      GeneratedColumn<DateTime>(
        'acknowledged_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    kind,
    severity,
    rationale,
    detectedAt,
    source,
    dedupeKey,
    acknowledgedBy,
    acknowledgedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'risk_flags';
  @override
  VerificationContext validateIntegrity(
    Insertable<RiskFlagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('rationale')) {
      context.handle(
        _rationaleMeta,
        rationale.isAcceptableOrUnknown(data['rationale']!, _rationaleMeta),
      );
    } else if (isInserting) {
      context.missing(_rationaleMeta);
    }
    if (data.containsKey('detected_at')) {
      context.handle(
        _detectedAtMeta,
        detectedAt.isAcceptableOrUnknown(data['detected_at']!, _detectedAtMeta),
      );
    }
    if (data.containsKey('dedupe_key')) {
      context.handle(
        _dedupeKeyMeta,
        dedupeKey.isAcceptableOrUnknown(data['dedupe_key']!, _dedupeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dedupeKeyMeta);
    }
    if (data.containsKey('acknowledged_by')) {
      context.handle(
        _acknowledgedByMeta,
        acknowledgedBy.isAcceptableOrUnknown(
          data['acknowledged_by']!,
          _acknowledgedByMeta,
        ),
      );
    }
    if (data.containsKey('acknowledged_at')) {
      context.handle(
        _acknowledgedAtMeta,
        acknowledgedAt.isAcceptableOrUnknown(
          data['acknowledged_at']!,
          _acknowledgedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RiskFlagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RiskFlagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      kind: $RiskFlagsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      severity: $RiskFlagsTable.$converterseverity.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}severity'],
        )!,
      ),
      rationale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rationale'],
      )!,
      detectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}detected_at'],
      )!,
      source: $RiskFlagsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      dedupeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dedupe_key'],
      )!,
      acknowledgedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}acknowledged_by'],
      ),
      acknowledgedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}acknowledged_at'],
      ),
    );
  }

  @override
  $RiskFlagsTable createAlias(String alias) {
    return $RiskFlagsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RiskFlagKind, String, String> $converterkind =
      const EnumNameConverter<RiskFlagKind>(RiskFlagKind.values);
  static JsonTypeConverter2<Severity, String, String> $converterseverity =
      const EnumNameConverter<Severity>(Severity.values);
  static JsonTypeConverter2<FlagSource, String, String> $convertersource =
      const EnumNameConverter<FlagSource>(FlagSource.values);
}

class RiskFlagRow extends DataClass implements Insertable<RiskFlagRow> {
  final String id;
  final String patientId;
  final RiskFlagKind kind;
  final Severity severity;
  final String rationale;
  final DateTime detectedAt;
  final FlagSource source;

  /// De-duplication key so the same finding isn't re-flagged daily (P5-02).
  final String dedupeKey;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  const RiskFlagRow({
    required this.id,
    required this.patientId,
    required this.kind,
    required this.severity,
    required this.rationale,
    required this.detectedAt,
    required this.source,
    required this.dedupeKey,
    this.acknowledgedBy,
    this.acknowledgedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    {
      map['kind'] = Variable<String>(
        $RiskFlagsTable.$converterkind.toSql(kind),
      );
    }
    {
      map['severity'] = Variable<String>(
        $RiskFlagsTable.$converterseverity.toSql(severity),
      );
    }
    map['rationale'] = Variable<String>(rationale);
    map['detected_at'] = Variable<DateTime>(detectedAt);
    {
      map['source'] = Variable<String>(
        $RiskFlagsTable.$convertersource.toSql(source),
      );
    }
    map['dedupe_key'] = Variable<String>(dedupeKey);
    if (!nullToAbsent || acknowledgedBy != null) {
      map['acknowledged_by'] = Variable<String>(acknowledgedBy);
    }
    if (!nullToAbsent || acknowledgedAt != null) {
      map['acknowledged_at'] = Variable<DateTime>(acknowledgedAt);
    }
    return map;
  }

  RiskFlagsCompanion toCompanion(bool nullToAbsent) {
    return RiskFlagsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      kind: Value(kind),
      severity: Value(severity),
      rationale: Value(rationale),
      detectedAt: Value(detectedAt),
      source: Value(source),
      dedupeKey: Value(dedupeKey),
      acknowledgedBy: acknowledgedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(acknowledgedBy),
      acknowledgedAt: acknowledgedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(acknowledgedAt),
    );
  }

  factory RiskFlagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RiskFlagRow(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      kind: $RiskFlagsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      severity: $RiskFlagsTable.$converterseverity.fromJson(
        serializer.fromJson<String>(json['severity']),
      ),
      rationale: serializer.fromJson<String>(json['rationale']),
      detectedAt: serializer.fromJson<DateTime>(json['detectedAt']),
      source: $RiskFlagsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      dedupeKey: serializer.fromJson<String>(json['dedupeKey']),
      acknowledgedBy: serializer.fromJson<String?>(json['acknowledgedBy']),
      acknowledgedAt: serializer.fromJson<DateTime?>(json['acknowledgedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'kind': serializer.toJson<String>(
        $RiskFlagsTable.$converterkind.toJson(kind),
      ),
      'severity': serializer.toJson<String>(
        $RiskFlagsTable.$converterseverity.toJson(severity),
      ),
      'rationale': serializer.toJson<String>(rationale),
      'detectedAt': serializer.toJson<DateTime>(detectedAt),
      'source': serializer.toJson<String>(
        $RiskFlagsTable.$convertersource.toJson(source),
      ),
      'dedupeKey': serializer.toJson<String>(dedupeKey),
      'acknowledgedBy': serializer.toJson<String?>(acknowledgedBy),
      'acknowledgedAt': serializer.toJson<DateTime?>(acknowledgedAt),
    };
  }

  RiskFlagRow copyWith({
    String? id,
    String? patientId,
    RiskFlagKind? kind,
    Severity? severity,
    String? rationale,
    DateTime? detectedAt,
    FlagSource? source,
    String? dedupeKey,
    Value<String?> acknowledgedBy = const Value.absent(),
    Value<DateTime?> acknowledgedAt = const Value.absent(),
  }) => RiskFlagRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    kind: kind ?? this.kind,
    severity: severity ?? this.severity,
    rationale: rationale ?? this.rationale,
    detectedAt: detectedAt ?? this.detectedAt,
    source: source ?? this.source,
    dedupeKey: dedupeKey ?? this.dedupeKey,
    acknowledgedBy: acknowledgedBy.present
        ? acknowledgedBy.value
        : this.acknowledgedBy,
    acknowledgedAt: acknowledgedAt.present
        ? acknowledgedAt.value
        : this.acknowledgedAt,
  );
  RiskFlagRow copyWithCompanion(RiskFlagsCompanion data) {
    return RiskFlagRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      kind: data.kind.present ? data.kind.value : this.kind,
      severity: data.severity.present ? data.severity.value : this.severity,
      rationale: data.rationale.present ? data.rationale.value : this.rationale,
      detectedAt: data.detectedAt.present
          ? data.detectedAt.value
          : this.detectedAt,
      source: data.source.present ? data.source.value : this.source,
      dedupeKey: data.dedupeKey.present ? data.dedupeKey.value : this.dedupeKey,
      acknowledgedBy: data.acknowledgedBy.present
          ? data.acknowledgedBy.value
          : this.acknowledgedBy,
      acknowledgedAt: data.acknowledgedAt.present
          ? data.acknowledgedAt.value
          : this.acknowledgedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RiskFlagRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('kind: $kind, ')
          ..write('severity: $severity, ')
          ..write('rationale: $rationale, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('source: $source, ')
          ..write('dedupeKey: $dedupeKey, ')
          ..write('acknowledgedBy: $acknowledgedBy, ')
          ..write('acknowledgedAt: $acknowledgedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    kind,
    severity,
    rationale,
    detectedAt,
    source,
    dedupeKey,
    acknowledgedBy,
    acknowledgedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RiskFlagRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.kind == this.kind &&
          other.severity == this.severity &&
          other.rationale == this.rationale &&
          other.detectedAt == this.detectedAt &&
          other.source == this.source &&
          other.dedupeKey == this.dedupeKey &&
          other.acknowledgedBy == this.acknowledgedBy &&
          other.acknowledgedAt == this.acknowledgedAt);
}

class RiskFlagsCompanion extends UpdateCompanion<RiskFlagRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<RiskFlagKind> kind;
  final Value<Severity> severity;
  final Value<String> rationale;
  final Value<DateTime> detectedAt;
  final Value<FlagSource> source;
  final Value<String> dedupeKey;
  final Value<String?> acknowledgedBy;
  final Value<DateTime?> acknowledgedAt;
  final Value<int> rowid;
  const RiskFlagsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.kind = const Value.absent(),
    this.severity = const Value.absent(),
    this.rationale = const Value.absent(),
    this.detectedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.dedupeKey = const Value.absent(),
    this.acknowledgedBy = const Value.absent(),
    this.acknowledgedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RiskFlagsCompanion.insert({
    required String id,
    required String patientId,
    required RiskFlagKind kind,
    required Severity severity,
    required String rationale,
    this.detectedAt = const Value.absent(),
    this.source = const Value.absent(),
    required String dedupeKey,
    this.acknowledgedBy = const Value.absent(),
    this.acknowledgedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       kind = Value(kind),
       severity = Value(severity),
       rationale = Value(rationale),
       dedupeKey = Value(dedupeKey);
  static Insertable<RiskFlagRow> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? kind,
    Expression<String>? severity,
    Expression<String>? rationale,
    Expression<DateTime>? detectedAt,
    Expression<String>? source,
    Expression<String>? dedupeKey,
    Expression<String>? acknowledgedBy,
    Expression<DateTime>? acknowledgedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (kind != null) 'kind': kind,
      if (severity != null) 'severity': severity,
      if (rationale != null) 'rationale': rationale,
      if (detectedAt != null) 'detected_at': detectedAt,
      if (source != null) 'source': source,
      if (dedupeKey != null) 'dedupe_key': dedupeKey,
      if (acknowledgedBy != null) 'acknowledged_by': acknowledgedBy,
      if (acknowledgedAt != null) 'acknowledged_at': acknowledgedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RiskFlagsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<RiskFlagKind>? kind,
    Value<Severity>? severity,
    Value<String>? rationale,
    Value<DateTime>? detectedAt,
    Value<FlagSource>? source,
    Value<String>? dedupeKey,
    Value<String?>? acknowledgedBy,
    Value<DateTime?>? acknowledgedAt,
    Value<int>? rowid,
  }) {
    return RiskFlagsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      kind: kind ?? this.kind,
      severity: severity ?? this.severity,
      rationale: rationale ?? this.rationale,
      detectedAt: detectedAt ?? this.detectedAt,
      source: source ?? this.source,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $RiskFlagsTable.$converterkind.toSql(kind.value),
      );
    }
    if (severity.present) {
      map['severity'] = Variable<String>(
        $RiskFlagsTable.$converterseverity.toSql(severity.value),
      );
    }
    if (rationale.present) {
      map['rationale'] = Variable<String>(rationale.value);
    }
    if (detectedAt.present) {
      map['detected_at'] = Variable<DateTime>(detectedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $RiskFlagsTable.$convertersource.toSql(source.value),
      );
    }
    if (dedupeKey.present) {
      map['dedupe_key'] = Variable<String>(dedupeKey.value);
    }
    if (acknowledgedBy.present) {
      map['acknowledged_by'] = Variable<String>(acknowledgedBy.value);
    }
    if (acknowledgedAt.present) {
      map['acknowledged_at'] = Variable<DateTime>(acknowledgedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RiskFlagsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('kind: $kind, ')
          ..write('severity: $severity, ')
          ..write('rationale: $rationale, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('source: $source, ')
          ..write('dedupeKey: $dedupeKey, ')
          ..write('acknowledgedBy: $acknowledgedBy, ')
          ..write('acknowledgedAt: $acknowledgedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog
    with TableInfo<$AuditLogTable, AuditLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorUserIdMeta = const VerificationMeta(
    'actorUserId',
  );
  @override
  late final GeneratedColumn<String> actorUserId = GeneratedColumn<String>(
    'actor_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    actorUserId,
    action,
    entityType,
    entityId,
    detail,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('actor_user_id')) {
      context.handle(
        _actorUserIdMeta,
        actorUserId.isAcceptableOrUnknown(
          data['actor_user_id']!,
          _actorUserIdMeta,
        ),
      );
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      actorUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_user_id'],
      ),
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }
}

class AuditLogRow extends DataClass implements Insertable<AuditLogRow> {
  final String id;
  final String? actorUserId;
  final String action;
  final String entityType;
  final String? entityId;
  final String? detail;
  final DateTime at;
  const AuditLogRow({
    required this.id,
    this.actorUserId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.detail,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || actorUserId != null) {
      map['actor_user_id'] = Variable<String>(actorUserId);
    }
    map['action'] = Variable<String>(action);
    map['entity_type'] = Variable<String>(entityType);
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    if (!nullToAbsent || detail != null) {
      map['detail'] = Variable<String>(detail);
    }
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      actorUserId: actorUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorUserId),
      action: Value(action),
      entityType: Value(entityType),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      detail: detail == null && nullToAbsent
          ? const Value.absent()
          : Value(detail),
      at: Value(at),
    );
  }

  factory AuditLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogRow(
      id: serializer.fromJson<String>(json['id']),
      actorUserId: serializer.fromJson<String?>(json['actorUserId']),
      action: serializer.fromJson<String>(json['action']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      detail: serializer.fromJson<String?>(json['detail']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'actorUserId': serializer.toJson<String?>(actorUserId),
      'action': serializer.toJson<String>(action),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String?>(entityId),
      'detail': serializer.toJson<String?>(detail),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  AuditLogRow copyWith({
    String? id,
    Value<String?> actorUserId = const Value.absent(),
    String? action,
    String? entityType,
    Value<String?> entityId = const Value.absent(),
    Value<String?> detail = const Value.absent(),
    DateTime? at,
  }) => AuditLogRow(
    id: id ?? this.id,
    actorUserId: actorUserId.present ? actorUserId.value : this.actorUserId,
    action: action ?? this.action,
    entityType: entityType ?? this.entityType,
    entityId: entityId.present ? entityId.value : this.entityId,
    detail: detail.present ? detail.value : this.detail,
    at: at ?? this.at,
  );
  AuditLogRow copyWithCompanion(AuditLogCompanion data) {
    return AuditLogRow(
      id: data.id.present ? data.id.value : this.id,
      actorUserId: data.actorUserId.present
          ? data.actorUserId.value
          : this.actorUserId,
      action: data.action.present ? data.action.value : this.action,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      detail: data.detail.present ? data.detail.value : this.detail,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogRow(')
          ..write('id: $id, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('detail: $detail, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, actorUserId, action, entityType, entityId, detail, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogRow &&
          other.id == this.id &&
          other.actorUserId == this.actorUserId &&
          other.action == this.action &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.detail == this.detail &&
          other.at == this.at);
}

class AuditLogCompanion extends UpdateCompanion<AuditLogRow> {
  final Value<String> id;
  final Value<String?> actorUserId;
  final Value<String> action;
  final Value<String> entityType;
  final Value<String?> entityId;
  final Value<String?> detail;
  final Value<DateTime> at;
  final Value<int> rowid;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.actorUserId = const Value.absent(),
    this.action = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.detail = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogCompanion.insert({
    required String id,
    this.actorUserId = const Value.absent(),
    required String action,
    required String entityType,
    this.entityId = const Value.absent(),
    this.detail = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       action = Value(action),
       entityType = Value(entityType);
  static Insertable<AuditLogRow> custom({
    Expression<String>? id,
    Expression<String>? actorUserId,
    Expression<String>? action,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? detail,
    Expression<DateTime>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actorUserId != null) 'actor_user_id': actorUserId,
      if (action != null) 'action': action,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (detail != null) 'detail': detail,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogCompanion copyWith({
    Value<String>? id,
    Value<String?>? actorUserId,
    Value<String>? action,
    Value<String>? entityType,
    Value<String?>? entityId,
    Value<String?>? detail,
    Value<DateTime>? at,
    Value<int>? rowid,
  }) {
    return AuditLogCompanion(
      id: id ?? this.id,
      actorUserId: actorUserId ?? this.actorUserId,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      detail: detail ?? this.detail,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (actorUserId.present) {
      map['actor_user_id'] = Variable<String>(actorUserId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('detail: $detail, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _aiEnabledMeta = const VerificationMeta(
    'aiEnabled',
  );
  @override
  late final GeneratedColumn<bool> aiEnabled = GeneratedColumn<bool>(
    'ai_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ai_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _mockModeMeta = const VerificationMeta(
    'mockMode',
  );
  @override
  late final GeneratedColumn<bool> mockMode = GeneratedColumn<bool>(
    'mock_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("mock_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('gemini-2.0-flash'),
  );
  static const VerificationMeta _aiTaskWeightMeta = const VerificationMeta(
    'aiTaskWeight',
  );
  @override
  late final GeneratedColumn<double> aiTaskWeight = GeneratedColumn<double>(
    'ai_task_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.5),
  );
  static const VerificationMeta _seedVersionMeta = const VerificationMeta(
    'seedVersion',
  );
  @override
  late final GeneratedColumn<int> seedVersion = GeneratedColumn<int>(
    'seed_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    aiEnabled,
    mockMode,
    modelId,
    aiTaskWeight,
    seedVersion,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ai_enabled')) {
      context.handle(
        _aiEnabledMeta,
        aiEnabled.isAcceptableOrUnknown(data['ai_enabled']!, _aiEnabledMeta),
      );
    }
    if (data.containsKey('mock_mode')) {
      context.handle(
        _mockModeMeta,
        mockMode.isAcceptableOrUnknown(data['mock_mode']!, _mockModeMeta),
      );
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    }
    if (data.containsKey('ai_task_weight')) {
      context.handle(
        _aiTaskWeightMeta,
        aiTaskWeight.isAcceptableOrUnknown(
          data['ai_task_weight']!,
          _aiTaskWeightMeta,
        ),
      );
    }
    if (data.containsKey('seed_version')) {
      context.handle(
        _seedVersionMeta,
        seedVersion.isAcceptableOrUnknown(
          data['seed_version']!,
          _seedVersionMeta,
        ),
      );
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
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      aiEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ai_enabled'],
      )!,
      mockMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}mock_mode'],
      )!,
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      )!,
      aiTaskWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ai_task_weight'],
      )!,
      seedVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seed_version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final int id;
  final bool aiEnabled;

  /// When true, the app uses MockAiService regardless of key presence (P3-07).
  final bool mockMode;
  final String modelId;

  /// AI-score weight when blended with the deterministic rule score (P5-10),
  /// 0.0–1.0.
  final double aiTaskWeight;

  /// Bumped by the seeder so re-seeds are detectable (P1-21).
  final int seedVersion;
  final DateTime updatedAt;
  const AppSettingsRow({
    required this.id,
    required this.aiEnabled,
    required this.mockMode,
    required this.modelId,
    required this.aiTaskWeight,
    required this.seedVersion,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ai_enabled'] = Variable<bool>(aiEnabled);
    map['mock_mode'] = Variable<bool>(mockMode);
    map['model_id'] = Variable<String>(modelId);
    map['ai_task_weight'] = Variable<double>(aiTaskWeight);
    map['seed_version'] = Variable<int>(seedVersion);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      aiEnabled: Value(aiEnabled),
      mockMode: Value(mockMode),
      modelId: Value(modelId),
      aiTaskWeight: Value(aiTaskWeight),
      seedVersion: Value(seedVersion),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      aiEnabled: serializer.fromJson<bool>(json['aiEnabled']),
      mockMode: serializer.fromJson<bool>(json['mockMode']),
      modelId: serializer.fromJson<String>(json['modelId']),
      aiTaskWeight: serializer.fromJson<double>(json['aiTaskWeight']),
      seedVersion: serializer.fromJson<int>(json['seedVersion']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'aiEnabled': serializer.toJson<bool>(aiEnabled),
      'mockMode': serializer.toJson<bool>(mockMode),
      'modelId': serializer.toJson<String>(modelId),
      'aiTaskWeight': serializer.toJson<double>(aiTaskWeight),
      'seedVersion': serializer.toJson<int>(seedVersion),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSettingsRow copyWith({
    int? id,
    bool? aiEnabled,
    bool? mockMode,
    String? modelId,
    double? aiTaskWeight,
    int? seedVersion,
    DateTime? updatedAt,
  }) => AppSettingsRow(
    id: id ?? this.id,
    aiEnabled: aiEnabled ?? this.aiEnabled,
    mockMode: mockMode ?? this.mockMode,
    modelId: modelId ?? this.modelId,
    aiTaskWeight: aiTaskWeight ?? this.aiTaskWeight,
    seedVersion: seedVersion ?? this.seedVersion,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSettingsRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      aiEnabled: data.aiEnabled.present ? data.aiEnabled.value : this.aiEnabled,
      mockMode: data.mockMode.present ? data.mockMode.value : this.mockMode,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      aiTaskWeight: data.aiTaskWeight.present
          ? data.aiTaskWeight.value
          : this.aiTaskWeight,
      seedVersion: data.seedVersion.present
          ? data.seedVersion.value
          : this.seedVersion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('id: $id, ')
          ..write('aiEnabled: $aiEnabled, ')
          ..write('mockMode: $mockMode, ')
          ..write('modelId: $modelId, ')
          ..write('aiTaskWeight: $aiTaskWeight, ')
          ..write('seedVersion: $seedVersion, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    aiEnabled,
    mockMode,
    modelId,
    aiTaskWeight,
    seedVersion,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.id == this.id &&
          other.aiEnabled == this.aiEnabled &&
          other.mockMode == this.mockMode &&
          other.modelId == this.modelId &&
          other.aiTaskWeight == this.aiTaskWeight &&
          other.seedVersion == this.seedVersion &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<int> id;
  final Value<bool> aiEnabled;
  final Value<bool> mockMode;
  final Value<String> modelId;
  final Value<double> aiTaskWeight;
  final Value<int> seedVersion;
  final Value<DateTime> updatedAt;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.aiEnabled = const Value.absent(),
    this.mockMode = const Value.absent(),
    this.modelId = const Value.absent(),
    this.aiTaskWeight = const Value.absent(),
    this.seedVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.aiEnabled = const Value.absent(),
    this.mockMode = const Value.absent(),
    this.modelId = const Value.absent(),
    this.aiTaskWeight = const Value.absent(),
    this.seedVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<AppSettingsRow> custom({
    Expression<int>? id,
    Expression<bool>? aiEnabled,
    Expression<bool>? mockMode,
    Expression<String>? modelId,
    Expression<double>? aiTaskWeight,
    Expression<int>? seedVersion,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aiEnabled != null) 'ai_enabled': aiEnabled,
      if (mockMode != null) 'mock_mode': mockMode,
      if (modelId != null) 'model_id': modelId,
      if (aiTaskWeight != null) 'ai_task_weight': aiTaskWeight,
      if (seedVersion != null) 'seed_version': seedVersion,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? aiEnabled,
    Value<bool>? mockMode,
    Value<String>? modelId,
    Value<double>? aiTaskWeight,
    Value<int>? seedVersion,
    Value<DateTime>? updatedAt,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      mockMode: mockMode ?? this.mockMode,
      modelId: modelId ?? this.modelId,
      aiTaskWeight: aiTaskWeight ?? this.aiTaskWeight,
      seedVersion: seedVersion ?? this.seedVersion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (aiEnabled.present) {
      map['ai_enabled'] = Variable<bool>(aiEnabled.value);
    }
    if (mockMode.present) {
      map['mock_mode'] = Variable<bool>(mockMode.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (aiTaskWeight.present) {
      map['ai_task_weight'] = Variable<double>(aiTaskWeight.value);
    }
    if (seedVersion.present) {
      map['seed_version'] = Variable<int>(seedVersion.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('aiEnabled: $aiEnabled, ')
          ..write('mockMode: $mockMode, ')
          ..write('modelId: $modelId, ')
          ..write('aiTaskWeight: $aiTaskWeight, ')
          ..write('seedVersion: $seedVersion, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $DepartmentsTable departments = $DepartmentsTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $PatientProfilesTable patientProfiles = $PatientProfilesTable(
    this,
  );
  late final $StaffProfilesTable staffProfiles = $StaffProfilesTable(this);
  late final $ScheduleTemplatesTable scheduleTemplates =
      $ScheduleTemplatesTable(this);
  late final $AppointmentsTable appointments = $AppointmentsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $MedicalRecordsTable medicalRecords = $MedicalRecordsTable(this);
  late final $LabValuesTable labValues = $LabValuesTable(this);
  late final $VitalsTable vitals = $VitalsTable(this);
  late final $MedicationsTable medications = $MedicationsTable(this);
  late final $AiSummariesTable aiSummaries = $AiSummariesTable(this);
  late final $StaffTasksTable staffTasks = $StaffTasksTable(this);
  late final $RiskFlagsTable riskFlags = $RiskFlagsTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    departments,
    users,
    patientProfiles,
    staffProfiles,
    scheduleTemplates,
    appointments,
    reminders,
    medicalRecords,
    labValues,
    vitals,
    medications,
    aiSummaries,
    staffTasks,
    riskFlags,
    auditLog,
    appSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('patient_profiles', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('staff_profiles', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('schedule_templates', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('appointments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'appointments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reminders', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('medical_records', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'medical_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lab_values', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('vitals', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('medications', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ai_summaries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('staff_tasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('risk_flags', kind: UpdateKind.delete)],
    ),
  ]);
}
