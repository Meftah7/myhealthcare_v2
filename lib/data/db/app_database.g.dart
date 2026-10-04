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
  static const VerificationMeta _avatarPathMeta = const VerificationMeta(
    'avatarPath',
  );
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
    'avatar_path',
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
  static const VerificationMeta _failedLoginAttemptsMeta =
      const VerificationMeta('failedLoginAttempts');
  @override
  late final GeneratedColumn<int> failedLoginAttempts = GeneratedColumn<int>(
    'failed_login_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lockedUntilMeta = const VerificationMeta(
    'lockedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> lockedUntil = GeneratedColumn<DateTime>(
    'locked_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasLoginMeta = const VerificationMeta(
    'hasLogin',
  );
  @override
  late final GeneratedColumn<bool> hasLogin = GeneratedColumn<bool>(
    'has_login',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_login" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    avatarPath,
    isActive,
    createdAt,
    failedLoginAttempts,
    lockedUntil,
    hasLogin,
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
    if (data.containsKey('avatar_path')) {
      context.handle(
        _avatarPathMeta,
        avatarPath.isAcceptableOrUnknown(data['avatar_path']!, _avatarPathMeta),
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
    if (data.containsKey('failed_login_attempts')) {
      context.handle(
        _failedLoginAttemptsMeta,
        failedLoginAttempts.isAcceptableOrUnknown(
          data['failed_login_attempts']!,
          _failedLoginAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('locked_until')) {
      context.handle(
        _lockedUntilMeta,
        lockedUntil.isAcceptableOrUnknown(
          data['locked_until']!,
          _lockedUntilMeta,
        ),
      );
    }
    if (data.containsKey('has_login')) {
      context.handle(
        _hasLoginMeta,
        hasLogin.isAcceptableOrUnknown(data['has_login']!, _hasLoginMeta),
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
      avatarPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_path'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      failedLoginAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_login_attempts'],
      )!,
      lockedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}locked_until'],
      ),
      hasLogin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_login'],
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

  /// Local file path to the account's profile photo, or null for the
  /// generated-monogram fallback. Never a remote URL — the app is
  /// offline-first, so the image lives on-device alongside the database.
  final String? avatarPath;
  final bool isActive;
  final DateTime createdAt;

  /// Consecutive wrong-password attempts since the last success — backs
  /// login throttling. Reset to 0 on a successful login.
  final int failedLoginAttempts;

  /// Set once [failedLoginAttempts] crosses the threshold; login is refused
  /// (with a generic message) while this is in the future.
  final DateTime? lockedUntil;

  /// False for a dependent patient (a child, or an adult someone cares for)
  /// who has a patient record but no login of their own. Sign-in and
  /// recovery always refuse such a row; a guardian reaches it through a
  /// proxy grant.
  final bool hasLogin;
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
    this.avatarPath,
    required this.isActive,
    required this.createdAt,
    required this.failedLoginAttempts,
    this.lockedUntil,
    required this.hasLogin,
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
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['failed_login_attempts'] = Variable<int>(failedLoginAttempts);
    if (!nullToAbsent || lockedUntil != null) {
      map['locked_until'] = Variable<DateTime>(lockedUntil);
    }
    map['has_login'] = Variable<bool>(hasLogin);
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
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      failedLoginAttempts: Value(failedLoginAttempts),
      lockedUntil: lockedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(lockedUntil),
      hasLogin: Value(hasLogin),
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
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      failedLoginAttempts: serializer.fromJson<int>(
        json['failedLoginAttempts'],
      ),
      lockedUntil: serializer.fromJson<DateTime?>(json['lockedUntil']),
      hasLogin: serializer.fromJson<bool>(json['hasLogin']),
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
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'failedLoginAttempts': serializer.toJson<int>(failedLoginAttempts),
      'lockedUntil': serializer.toJson<DateTime?>(lockedUntil),
      'hasLogin': serializer.toJson<bool>(hasLogin),
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
    Value<String?> avatarPath = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    int? failedLoginAttempts,
    Value<DateTime?> lockedUntil = const Value.absent(),
    bool? hasLogin,
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
    avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    failedLoginAttempts: failedLoginAttempts ?? this.failedLoginAttempts,
    lockedUntil: lockedUntil.present ? lockedUntil.value : this.lockedUntil,
    hasLogin: hasLogin ?? this.hasLogin,
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
      avatarPath: data.avatarPath.present
          ? data.avatarPath.value
          : this.avatarPath,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      failedLoginAttempts: data.failedLoginAttempts.present
          ? data.failedLoginAttempts.value
          : this.failedLoginAttempts,
      lockedUntil: data.lockedUntil.present
          ? data.lockedUntil.value
          : this.lockedUntil,
      hasLogin: data.hasLogin.present ? data.hasLogin.value : this.hasLogin,
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
          ..write('avatarPath: $avatarPath, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('failedLoginAttempts: $failedLoginAttempts, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('hasLogin: $hasLogin')
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
    avatarPath,
    isActive,
    createdAt,
    failedLoginAttempts,
    lockedUntil,
    hasLogin,
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
          other.avatarPath == this.avatarPath &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.failedLoginAttempts == this.failedLoginAttempts &&
          other.lockedUntil == this.lockedUntil &&
          other.hasLogin == this.hasLogin);
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
  final Value<String?> avatarPath;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> failedLoginAttempts;
  final Value<DateTime?> lockedUntil;
  final Value<bool> hasLogin;
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
    this.avatarPath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.failedLoginAttempts = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    this.hasLogin = const Value.absent(),
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
    this.avatarPath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.failedLoginAttempts = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    this.hasLogin = const Value.absent(),
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
    Expression<String>? avatarPath,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? failedLoginAttempts,
    Expression<DateTime>? lockedUntil,
    Expression<bool>? hasLogin,
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
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (failedLoginAttempts != null)
        'failed_login_attempts': failedLoginAttempts,
      if (lockedUntil != null) 'locked_until': lockedUntil,
      if (hasLogin != null) 'has_login': hasLogin,
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
    Value<String?>? avatarPath,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<int>? failedLoginAttempts,
    Value<DateTime?>? lockedUntil,
    Value<bool>? hasLogin,
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
      avatarPath: avatarPath ?? this.avatarPath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      failedLoginAttempts: failedLoginAttempts ?? this.failedLoginAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      hasLogin: hasLogin ?? this.hasLogin,
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
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (failedLoginAttempts.present) {
      map['failed_login_attempts'] = Variable<int>(failedLoginAttempts.value);
    }
    if (lockedUntil.present) {
      map['locked_until'] = Variable<DateTime>(lockedUntil.value);
    }
    if (hasLogin.present) {
      map['has_login'] = Variable<bool>(hasLogin.value);
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
          ..write('avatarPath: $avatarPath, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('failedLoginAttempts: $failedLoginAttempts, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('hasLogin: $hasLogin, ')
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
  late final GeneratedColumnWithTypeConverter<List<FamilyMember>, String>
  familyMembers =
      GeneratedColumn<String>(
        'family_members',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<FamilyMember>>(
        $PatientProfilesTable.$converterfamilyMembers,
      );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    bloodType,
    allergies,
    chronicConditions,
    emergencyContact,
    familyMembers,
    version,
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
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
      familyMembers: $PatientProfilesTable.$converterfamilyMembers.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}family_members'],
        )!,
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
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
  static TypeConverter<List<FamilyMember>, String> $converterfamilyMembers =
      const FamilyMemberListConverter();
}

class PatientProfileRow extends DataClass
    implements Insertable<PatientProfileRow> {
  final String userId;
  final String? bloodType;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String? emergencyContact;

  /// Linked family members (redesign v2 patient dashboard: Family Network).
  /// The whole list round-trips as one JSON blob — no table of its own.
  final List<FamilyMember> familyMembers;

  /// Optimistic-concurrency version (trigger-bumped, schema v19): two
  /// devices editing one profile can't silently overwrite each other.
  final int version;
  const PatientProfileRow({
    required this.userId,
    this.bloodType,
    required this.allergies,
    required this.chronicConditions,
    this.emergencyContact,
    required this.familyMembers,
    required this.version,
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
    {
      map['family_members'] = Variable<String>(
        $PatientProfilesTable.$converterfamilyMembers.toSql(familyMembers),
      );
    }
    map['version'] = Variable<int>(version);
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
      familyMembers: Value(familyMembers),
      version: Value(version),
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
      familyMembers: serializer.fromJson<List<FamilyMember>>(
        json['familyMembers'],
      ),
      version: serializer.fromJson<int>(json['version']),
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
      'familyMembers': serializer.toJson<List<FamilyMember>>(familyMembers),
      'version': serializer.toJson<int>(version),
    };
  }

  PatientProfileRow copyWith({
    String? userId,
    Value<String?> bloodType = const Value.absent(),
    List<String>? allergies,
    List<String>? chronicConditions,
    Value<String?> emergencyContact = const Value.absent(),
    List<FamilyMember>? familyMembers,
    int? version,
  }) => PatientProfileRow(
    userId: userId ?? this.userId,
    bloodType: bloodType.present ? bloodType.value : this.bloodType,
    allergies: allergies ?? this.allergies,
    chronicConditions: chronicConditions ?? this.chronicConditions,
    emergencyContact: emergencyContact.present
        ? emergencyContact.value
        : this.emergencyContact,
    familyMembers: familyMembers ?? this.familyMembers,
    version: version ?? this.version,
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
      familyMembers: data.familyMembers.present
          ? data.familyMembers.value
          : this.familyMembers,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PatientProfileRow(')
          ..write('userId: $userId, ')
          ..write('bloodType: $bloodType, ')
          ..write('allergies: $allergies, ')
          ..write('chronicConditions: $chronicConditions, ')
          ..write('emergencyContact: $emergencyContact, ')
          ..write('familyMembers: $familyMembers, ')
          ..write('version: $version')
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
    familyMembers,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PatientProfileRow &&
          other.userId == this.userId &&
          other.bloodType == this.bloodType &&
          other.allergies == this.allergies &&
          other.chronicConditions == this.chronicConditions &&
          other.emergencyContact == this.emergencyContact &&
          other.familyMembers == this.familyMembers &&
          other.version == this.version);
}

class PatientProfilesCompanion extends UpdateCompanion<PatientProfileRow> {
  final Value<String> userId;
  final Value<String?> bloodType;
  final Value<List<String>> allergies;
  final Value<List<String>> chronicConditions;
  final Value<String?> emergencyContact;
  final Value<List<FamilyMember>> familyMembers;
  final Value<int> version;
  final Value<int> rowid;
  const PatientProfilesCompanion({
    this.userId = const Value.absent(),
    this.bloodType = const Value.absent(),
    this.allergies = const Value.absent(),
    this.chronicConditions = const Value.absent(),
    this.emergencyContact = const Value.absent(),
    this.familyMembers = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatientProfilesCompanion.insert({
    required String userId,
    this.bloodType = const Value.absent(),
    this.allergies = const Value.absent(),
    this.chronicConditions = const Value.absent(),
    this.emergencyContact = const Value.absent(),
    this.familyMembers = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<PatientProfileRow> custom({
    Expression<String>? userId,
    Expression<String>? bloodType,
    Expression<String>? allergies,
    Expression<String>? chronicConditions,
    Expression<String>? emergencyContact,
    Expression<String>? familyMembers,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (bloodType != null) 'blood_type': bloodType,
      if (allergies != null) 'allergies': allergies,
      if (chronicConditions != null) 'chronic_conditions': chronicConditions,
      if (emergencyContact != null) 'emergency_contact': emergencyContact,
      if (familyMembers != null) 'family_members': familyMembers,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatientProfilesCompanion copyWith({
    Value<String>? userId,
    Value<String?>? bloodType,
    Value<List<String>>? allergies,
    Value<List<String>>? chronicConditions,
    Value<String?>? emergencyContact,
    Value<List<FamilyMember>>? familyMembers,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return PatientProfilesCompanion(
      userId: userId ?? this.userId,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      familyMembers: familyMembers ?? this.familyMembers,
      version: version ?? this.version,
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
    if (familyMembers.present) {
      map['family_members'] = Variable<String>(
        $PatientProfilesTable.$converterfamilyMembers.toSql(
          familyMembers.value,
        ),
      );
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
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
          ..write('familyMembers: $familyMembers, ')
          ..write('version: $version, ')
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
  late final GeneratedColumnWithTypeConverter<PresenceStatus?, String>
  presence = GeneratedColumn<String>(
    'presence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<PresenceStatus?>($StaffProfilesTable.$converterpresencen);
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    specialty,
    departmentId,
    licenseNo,
    jobTitle,
    presence,
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
      presence: $StaffProfilesTable.$converterpresencen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}presence'],
        ),
      ),
    );
  }

  @override
  $StaffProfilesTable createAlias(String alias) {
    return $StaffProfilesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PresenceStatus, String, String> $converterpresence =
      const EnumNameConverter<PresenceStatus>(PresenceStatus.values);
  static JsonTypeConverter2<PresenceStatus?, String?, String?>
  $converterpresencen = JsonTypeConverter2.asNullable($converterpresence);
}

class StaffProfileRow extends DataClass implements Insertable<StaffProfileRow> {
  final String userId;
  final String? specialty;
  final String? departmentId;
  final String? licenseNo;
  final String? jobTitle;

  /// Live availability shown on the staff dashboard + directory. Null rows
  /// (pre-migration) read as [PresenceStatus.offShift].
  final PresenceStatus? presence;
  const StaffProfileRow({
    required this.userId,
    this.specialty,
    this.departmentId,
    this.licenseNo,
    this.jobTitle,
    this.presence,
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
    if (!nullToAbsent || presence != null) {
      map['presence'] = Variable<String>(
        $StaffProfilesTable.$converterpresencen.toSql(presence),
      );
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
      presence: presence == null && nullToAbsent
          ? const Value.absent()
          : Value(presence),
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
      presence: $StaffProfilesTable.$converterpresencen.fromJson(
        serializer.fromJson<String?>(json['presence']),
      ),
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
      'presence': serializer.toJson<String?>(
        $StaffProfilesTable.$converterpresencen.toJson(presence),
      ),
    };
  }

  StaffProfileRow copyWith({
    String? userId,
    Value<String?> specialty = const Value.absent(),
    Value<String?> departmentId = const Value.absent(),
    Value<String?> licenseNo = const Value.absent(),
    Value<String?> jobTitle = const Value.absent(),
    Value<PresenceStatus?> presence = const Value.absent(),
  }) => StaffProfileRow(
    userId: userId ?? this.userId,
    specialty: specialty.present ? specialty.value : this.specialty,
    departmentId: departmentId.present ? departmentId.value : this.departmentId,
    licenseNo: licenseNo.present ? licenseNo.value : this.licenseNo,
    jobTitle: jobTitle.present ? jobTitle.value : this.jobTitle,
    presence: presence.present ? presence.value : this.presence,
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
      presence: data.presence.present ? data.presence.value : this.presence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StaffProfileRow(')
          ..write('userId: $userId, ')
          ..write('specialty: $specialty, ')
          ..write('departmentId: $departmentId, ')
          ..write('licenseNo: $licenseNo, ')
          ..write('jobTitle: $jobTitle, ')
          ..write('presence: $presence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    specialty,
    departmentId,
    licenseNo,
    jobTitle,
    presence,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaffProfileRow &&
          other.userId == this.userId &&
          other.specialty == this.specialty &&
          other.departmentId == this.departmentId &&
          other.licenseNo == this.licenseNo &&
          other.jobTitle == this.jobTitle &&
          other.presence == this.presence);
}

class StaffProfilesCompanion extends UpdateCompanion<StaffProfileRow> {
  final Value<String> userId;
  final Value<String?> specialty;
  final Value<String?> departmentId;
  final Value<String?> licenseNo;
  final Value<String?> jobTitle;
  final Value<PresenceStatus?> presence;
  final Value<int> rowid;
  const StaffProfilesCompanion({
    this.userId = const Value.absent(),
    this.specialty = const Value.absent(),
    this.departmentId = const Value.absent(),
    this.licenseNo = const Value.absent(),
    this.jobTitle = const Value.absent(),
    this.presence = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StaffProfilesCompanion.insert({
    required String userId,
    this.specialty = const Value.absent(),
    this.departmentId = const Value.absent(),
    this.licenseNo = const Value.absent(),
    this.jobTitle = const Value.absent(),
    this.presence = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<StaffProfileRow> custom({
    Expression<String>? userId,
    Expression<String>? specialty,
    Expression<String>? departmentId,
    Expression<String>? licenseNo,
    Expression<String>? jobTitle,
    Expression<String>? presence,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (specialty != null) 'specialty': specialty,
      if (departmentId != null) 'department_id': departmentId,
      if (licenseNo != null) 'license_no': licenseNo,
      if (jobTitle != null) 'job_title': jobTitle,
      if (presence != null) 'presence': presence,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StaffProfilesCompanion copyWith({
    Value<String>? userId,
    Value<String?>? specialty,
    Value<String?>? departmentId,
    Value<String?>? licenseNo,
    Value<String?>? jobTitle,
    Value<PresenceStatus?>? presence,
    Value<int>? rowid,
  }) {
    return StaffProfilesCompanion(
      userId: userId ?? this.userId,
      specialty: specialty ?? this.specialty,
      departmentId: departmentId ?? this.departmentId,
      licenseNo: licenseNo ?? this.licenseNo,
      jobTitle: jobTitle ?? this.jobTitle,
      presence: presence ?? this.presence,
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
    if (presence.present) {
      map['presence'] = Variable<String>(
        $StaffProfilesTable.$converterpresencen.toSql(presence.value),
      );
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
          ..write('presence: $presence, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PasswordResetRequestsTable extends PasswordResetRequests
    with TableInfo<$PasswordResetRequestsTable, PasswordResetRequestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PasswordResetRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _identifierEnteredMeta = const VerificationMeta(
    'identifierEntered',
  );
  @override
  late final GeneratedColumn<String> identifierEntered =
      GeneratedColumn<String>(
        'identifier_entered',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _requestedAtMeta = const VerificationMeta(
    'requestedAt',
  );
  @override
  late final GeneratedColumn<DateTime> requestedAt = GeneratedColumn<DateTime>(
    'requested_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _resolvedMeta = const VerificationMeta(
    'resolved',
  );
  @override
  late final GeneratedColumn<bool> resolved = GeneratedColumn<bool>(
    'resolved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("resolved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _resolvedByStaffIdMeta = const VerificationMeta(
    'resolvedByStaffId',
  );
  @override
  late final GeneratedColumn<String> resolvedByStaffId =
      GeneratedColumn<String>(
        'resolved_by_staff_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES users (id)',
        ),
      );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    identifierEntered,
    requestedAt,
    resolved,
    resolvedByStaffId,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'password_reset_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<PasswordResetRequestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('identifier_entered')) {
      context.handle(
        _identifierEnteredMeta,
        identifierEntered.isAcceptableOrUnknown(
          data['identifier_entered']!,
          _identifierEnteredMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_identifierEnteredMeta);
    }
    if (data.containsKey('requested_at')) {
      context.handle(
        _requestedAtMeta,
        requestedAt.isAcceptableOrUnknown(
          data['requested_at']!,
          _requestedAtMeta,
        ),
      );
    }
    if (data.containsKey('resolved')) {
      context.handle(
        _resolvedMeta,
        resolved.isAcceptableOrUnknown(data['resolved']!, _resolvedMeta),
      );
    }
    if (data.containsKey('resolved_by_staff_id')) {
      context.handle(
        _resolvedByStaffIdMeta,
        resolvedByStaffId.isAcceptableOrUnknown(
          data['resolved_by_staff_id']!,
          _resolvedByStaffIdMeta,
        ),
      );
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PasswordResetRequestRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PasswordResetRequestRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      identifierEntered: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identifier_entered'],
      )!,
      requestedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}requested_at'],
      )!,
      resolved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}resolved'],
      )!,
      resolvedByStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolved_by_staff_id'],
      ),
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
    );
  }

  @override
  $PasswordResetRequestsTable createAlias(String alias) {
    return $PasswordResetRequestsTable(attachedDatabase, alias);
  }
}

class PasswordResetRequestRow extends DataClass
    implements Insertable<PasswordResetRequestRow> {
  final String id;
  final String userId;

  /// What the requester typed (email or national ID) — shown to the admin
  /// for context; never used to bypass looking the account up server-side.
  final String identifierEntered;
  final DateTime requestedAt;
  final bool resolved;
  final String? resolvedByStaffId;
  final DateTime? resolvedAt;
  const PasswordResetRequestRow({
    required this.id,
    required this.userId,
    required this.identifierEntered,
    required this.requestedAt,
    required this.resolved,
    this.resolvedByStaffId,
    this.resolvedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['identifier_entered'] = Variable<String>(identifierEntered);
    map['requested_at'] = Variable<DateTime>(requestedAt);
    map['resolved'] = Variable<bool>(resolved);
    if (!nullToAbsent || resolvedByStaffId != null) {
      map['resolved_by_staff_id'] = Variable<String>(resolvedByStaffId);
    }
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    return map;
  }

  PasswordResetRequestsCompanion toCompanion(bool nullToAbsent) {
    return PasswordResetRequestsCompanion(
      id: Value(id),
      userId: Value(userId),
      identifierEntered: Value(identifierEntered),
      requestedAt: Value(requestedAt),
      resolved: Value(resolved),
      resolvedByStaffId: resolvedByStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedByStaffId),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory PasswordResetRequestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PasswordResetRequestRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      identifierEntered: serializer.fromJson<String>(json['identifierEntered']),
      requestedAt: serializer.fromJson<DateTime>(json['requestedAt']),
      resolved: serializer.fromJson<bool>(json['resolved']),
      resolvedByStaffId: serializer.fromJson<String?>(
        json['resolvedByStaffId'],
      ),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'identifierEntered': serializer.toJson<String>(identifierEntered),
      'requestedAt': serializer.toJson<DateTime>(requestedAt),
      'resolved': serializer.toJson<bool>(resolved),
      'resolvedByStaffId': serializer.toJson<String?>(resolvedByStaffId),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
    };
  }

  PasswordResetRequestRow copyWith({
    String? id,
    String? userId,
    String? identifierEntered,
    DateTime? requestedAt,
    bool? resolved,
    Value<String?> resolvedByStaffId = const Value.absent(),
    Value<DateTime?> resolvedAt = const Value.absent(),
  }) => PasswordResetRequestRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    identifierEntered: identifierEntered ?? this.identifierEntered,
    requestedAt: requestedAt ?? this.requestedAt,
    resolved: resolved ?? this.resolved,
    resolvedByStaffId: resolvedByStaffId.present
        ? resolvedByStaffId.value
        : this.resolvedByStaffId,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
  );
  PasswordResetRequestRow copyWithCompanion(
    PasswordResetRequestsCompanion data,
  ) {
    return PasswordResetRequestRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      identifierEntered: data.identifierEntered.present
          ? data.identifierEntered.value
          : this.identifierEntered,
      requestedAt: data.requestedAt.present
          ? data.requestedAt.value
          : this.requestedAt,
      resolved: data.resolved.present ? data.resolved.value : this.resolved,
      resolvedByStaffId: data.resolvedByStaffId.present
          ? data.resolvedByStaffId.value
          : this.resolvedByStaffId,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PasswordResetRequestRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('identifierEntered: $identifierEntered, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('resolved: $resolved, ')
          ..write('resolvedByStaffId: $resolvedByStaffId, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    identifierEntered,
    requestedAt,
    resolved,
    resolvedByStaffId,
    resolvedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PasswordResetRequestRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.identifierEntered == this.identifierEntered &&
          other.requestedAt == this.requestedAt &&
          other.resolved == this.resolved &&
          other.resolvedByStaffId == this.resolvedByStaffId &&
          other.resolvedAt == this.resolvedAt);
}

class PasswordResetRequestsCompanion
    extends UpdateCompanion<PasswordResetRequestRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> identifierEntered;
  final Value<DateTime> requestedAt;
  final Value<bool> resolved;
  final Value<String?> resolvedByStaffId;
  final Value<DateTime?> resolvedAt;
  final Value<int> rowid;
  const PasswordResetRequestsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.identifierEntered = const Value.absent(),
    this.requestedAt = const Value.absent(),
    this.resolved = const Value.absent(),
    this.resolvedByStaffId = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PasswordResetRequestsCompanion.insert({
    required String id,
    required String userId,
    required String identifierEntered,
    this.requestedAt = const Value.absent(),
    this.resolved = const Value.absent(),
    this.resolvedByStaffId = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       identifierEntered = Value(identifierEntered);
  static Insertable<PasswordResetRequestRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? identifierEntered,
    Expression<DateTime>? requestedAt,
    Expression<bool>? resolved,
    Expression<String>? resolvedByStaffId,
    Expression<DateTime>? resolvedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (identifierEntered != null) 'identifier_entered': identifierEntered,
      if (requestedAt != null) 'requested_at': requestedAt,
      if (resolved != null) 'resolved': resolved,
      if (resolvedByStaffId != null) 'resolved_by_staff_id': resolvedByStaffId,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PasswordResetRequestsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? identifierEntered,
    Value<DateTime>? requestedAt,
    Value<bool>? resolved,
    Value<String?>? resolvedByStaffId,
    Value<DateTime?>? resolvedAt,
    Value<int>? rowid,
  }) {
    return PasswordResetRequestsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      identifierEntered: identifierEntered ?? this.identifierEntered,
      requestedAt: requestedAt ?? this.requestedAt,
      resolved: resolved ?? this.resolved,
      resolvedByStaffId: resolvedByStaffId ?? this.resolvedByStaffId,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (identifierEntered.present) {
      map['identifier_entered'] = Variable<String>(identifierEntered.value);
    }
    if (requestedAt.present) {
      map['requested_at'] = Variable<DateTime>(requestedAt.value);
    }
    if (resolved.present) {
      map['resolved'] = Variable<bool>(resolved.value);
    }
    if (resolvedByStaffId.present) {
      map['resolved_by_staff_id'] = Variable<String>(resolvedByStaffId.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PasswordResetRequestsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('identifierEntered: $identifierEntered, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('resolved: $resolved, ')
          ..write('resolvedByStaffId: $resolvedByStaffId, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountRecoveryTokensTable extends AccountRecoveryTokens
    with TableInfo<$AccountRecoveryTokensTable, AccountRecoveryTokenRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountRecoveryTokensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _codeHashMeta = const VerificationMeta(
    'codeHash',
  );
  @override
  late final GeneratedColumn<String> codeHash = GeneratedColumn<String>(
    'code_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeSaltMeta = const VerificationMeta(
    'codeSalt',
  );
  @override
  late final GeneratedColumn<String> codeSalt = GeneratedColumn<String>(
    'code_salt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentToMeta = const VerificationMeta('sentTo');
  @override
  late final GeneratedColumn<String> sentTo = GeneratedColumn<String>(
    'sent_to',
    aliasedName,
    false,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _failedAttemptsMeta = const VerificationMeta(
    'failedAttempts',
  );
  @override
  late final GeneratedColumn<int> failedAttempts = GeneratedColumn<int>(
    'failed_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _consumedAtMeta = const VerificationMeta(
    'consumedAt',
  );
  @override
  late final GeneratedColumn<DateTime> consumedAt = GeneratedColumn<DateTime>(
    'consumed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invalidatedAtMeta = const VerificationMeta(
    'invalidatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> invalidatedAt =
      GeneratedColumn<DateTime>(
        'invalidated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    codeHash,
    codeSalt,
    sentTo,
    createdAt,
    expiresAt,
    failedAttempts,
    consumedAt,
    invalidatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_recovery_tokens';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRecoveryTokenRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('code_hash')) {
      context.handle(
        _codeHashMeta,
        codeHash.isAcceptableOrUnknown(data['code_hash']!, _codeHashMeta),
      );
    } else if (isInserting) {
      context.missing(_codeHashMeta);
    }
    if (data.containsKey('code_salt')) {
      context.handle(
        _codeSaltMeta,
        codeSalt.isAcceptableOrUnknown(data['code_salt']!, _codeSaltMeta),
      );
    } else if (isInserting) {
      context.missing(_codeSaltMeta);
    }
    if (data.containsKey('sent_to')) {
      context.handle(
        _sentToMeta,
        sentTo.isAcceptableOrUnknown(data['sent_to']!, _sentToMeta),
      );
    } else if (isInserting) {
      context.missing(_sentToMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('failed_attempts')) {
      context.handle(
        _failedAttemptsMeta,
        failedAttempts.isAcceptableOrUnknown(
          data['failed_attempts']!,
          _failedAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('consumed_at')) {
      context.handle(
        _consumedAtMeta,
        consumedAt.isAcceptableOrUnknown(data['consumed_at']!, _consumedAtMeta),
      );
    }
    if (data.containsKey('invalidated_at')) {
      context.handle(
        _invalidatedAtMeta,
        invalidatedAt.isAcceptableOrUnknown(
          data['invalidated_at']!,
          _invalidatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRecoveryTokenRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRecoveryTokenRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      codeHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_hash'],
      )!,
      codeSalt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_salt'],
      )!,
      sentTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sent_to'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      failedAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_attempts'],
      )!,
      consumedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}consumed_at'],
      ),
      invalidatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}invalidated_at'],
      ),
    );
  }

  @override
  $AccountRecoveryTokensTable createAlias(String alias) {
    return $AccountRecoveryTokensTable(attachedDatabase, alias);
  }
}

class AccountRecoveryTokenRow extends DataClass
    implements Insertable<AccountRecoveryTokenRow> {
  final String id;
  final String userId;
  final String codeHash;
  final String codeSalt;

  /// Where the code was sent, masked (e.g. `p***@myhealth.demo`).
  final String sentTo;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int failedAttempts;
  final DateTime? consumedAt;
  final DateTime? invalidatedAt;
  const AccountRecoveryTokenRow({
    required this.id,
    required this.userId,
    required this.codeHash,
    required this.codeSalt,
    required this.sentTo,
    required this.createdAt,
    required this.expiresAt,
    required this.failedAttempts,
    this.consumedAt,
    this.invalidatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['code_hash'] = Variable<String>(codeHash);
    map['code_salt'] = Variable<String>(codeSalt);
    map['sent_to'] = Variable<String>(sentTo);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    map['failed_attempts'] = Variable<int>(failedAttempts);
    if (!nullToAbsent || consumedAt != null) {
      map['consumed_at'] = Variable<DateTime>(consumedAt);
    }
    if (!nullToAbsent || invalidatedAt != null) {
      map['invalidated_at'] = Variable<DateTime>(invalidatedAt);
    }
    return map;
  }

  AccountRecoveryTokensCompanion toCompanion(bool nullToAbsent) {
    return AccountRecoveryTokensCompanion(
      id: Value(id),
      userId: Value(userId),
      codeHash: Value(codeHash),
      codeSalt: Value(codeSalt),
      sentTo: Value(sentTo),
      createdAt: Value(createdAt),
      expiresAt: Value(expiresAt),
      failedAttempts: Value(failedAttempts),
      consumedAt: consumedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(consumedAt),
      invalidatedAt: invalidatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(invalidatedAt),
    );
  }

  factory AccountRecoveryTokenRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRecoveryTokenRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      codeHash: serializer.fromJson<String>(json['codeHash']),
      codeSalt: serializer.fromJson<String>(json['codeSalt']),
      sentTo: serializer.fromJson<String>(json['sentTo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      failedAttempts: serializer.fromJson<int>(json['failedAttempts']),
      consumedAt: serializer.fromJson<DateTime?>(json['consumedAt']),
      invalidatedAt: serializer.fromJson<DateTime?>(json['invalidatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'codeHash': serializer.toJson<String>(codeHash),
      'codeSalt': serializer.toJson<String>(codeSalt),
      'sentTo': serializer.toJson<String>(sentTo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'failedAttempts': serializer.toJson<int>(failedAttempts),
      'consumedAt': serializer.toJson<DateTime?>(consumedAt),
      'invalidatedAt': serializer.toJson<DateTime?>(invalidatedAt),
    };
  }

  AccountRecoveryTokenRow copyWith({
    String? id,
    String? userId,
    String? codeHash,
    String? codeSalt,
    String? sentTo,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? failedAttempts,
    Value<DateTime?> consumedAt = const Value.absent(),
    Value<DateTime?> invalidatedAt = const Value.absent(),
  }) => AccountRecoveryTokenRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    codeHash: codeHash ?? this.codeHash,
    codeSalt: codeSalt ?? this.codeSalt,
    sentTo: sentTo ?? this.sentTo,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    consumedAt: consumedAt.present ? consumedAt.value : this.consumedAt,
    invalidatedAt: invalidatedAt.present
        ? invalidatedAt.value
        : this.invalidatedAt,
  );
  AccountRecoveryTokenRow copyWithCompanion(
    AccountRecoveryTokensCompanion data,
  ) {
    return AccountRecoveryTokenRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      codeHash: data.codeHash.present ? data.codeHash.value : this.codeHash,
      codeSalt: data.codeSalt.present ? data.codeSalt.value : this.codeSalt,
      sentTo: data.sentTo.present ? data.sentTo.value : this.sentTo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      failedAttempts: data.failedAttempts.present
          ? data.failedAttempts.value
          : this.failedAttempts,
      consumedAt: data.consumedAt.present
          ? data.consumedAt.value
          : this.consumedAt,
      invalidatedAt: data.invalidatedAt.present
          ? data.invalidatedAt.value
          : this.invalidatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRecoveryTokenRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('codeHash: $codeHash, ')
          ..write('codeSalt: $codeSalt, ')
          ..write('sentTo: $sentTo, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('invalidatedAt: $invalidatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    codeHash,
    codeSalt,
    sentTo,
    createdAt,
    expiresAt,
    failedAttempts,
    consumedAt,
    invalidatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRecoveryTokenRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.codeHash == this.codeHash &&
          other.codeSalt == this.codeSalt &&
          other.sentTo == this.sentTo &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt &&
          other.failedAttempts == this.failedAttempts &&
          other.consumedAt == this.consumedAt &&
          other.invalidatedAt == this.invalidatedAt);
}

class AccountRecoveryTokensCompanion
    extends UpdateCompanion<AccountRecoveryTokenRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> codeHash;
  final Value<String> codeSalt;
  final Value<String> sentTo;
  final Value<DateTime> createdAt;
  final Value<DateTime> expiresAt;
  final Value<int> failedAttempts;
  final Value<DateTime?> consumedAt;
  final Value<DateTime?> invalidatedAt;
  final Value<int> rowid;
  const AccountRecoveryTokensCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.codeHash = const Value.absent(),
    this.codeSalt = const Value.absent(),
    this.sentTo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.failedAttempts = const Value.absent(),
    this.consumedAt = const Value.absent(),
    this.invalidatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountRecoveryTokensCompanion.insert({
    required String id,
    required String userId,
    required String codeHash,
    required String codeSalt,
    required String sentTo,
    required DateTime createdAt,
    required DateTime expiresAt,
    this.failedAttempts = const Value.absent(),
    this.consumedAt = const Value.absent(),
    this.invalidatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       codeHash = Value(codeHash),
       codeSalt = Value(codeSalt),
       sentTo = Value(sentTo),
       createdAt = Value(createdAt),
       expiresAt = Value(expiresAt);
  static Insertable<AccountRecoveryTokenRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? codeHash,
    Expression<String>? codeSalt,
    Expression<String>? sentTo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? failedAttempts,
    Expression<DateTime>? consumedAt,
    Expression<DateTime>? invalidatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (codeHash != null) 'code_hash': codeHash,
      if (codeSalt != null) 'code_salt': codeSalt,
      if (sentTo != null) 'sent_to': sentTo,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (failedAttempts != null) 'failed_attempts': failedAttempts,
      if (consumedAt != null) 'consumed_at': consumedAt,
      if (invalidatedAt != null) 'invalidated_at': invalidatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountRecoveryTokensCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? codeHash,
    Value<String>? codeSalt,
    Value<String>? sentTo,
    Value<DateTime>? createdAt,
    Value<DateTime>? expiresAt,
    Value<int>? failedAttempts,
    Value<DateTime?>? consumedAt,
    Value<DateTime?>? invalidatedAt,
    Value<int>? rowid,
  }) {
    return AccountRecoveryTokensCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      codeHash: codeHash ?? this.codeHash,
      codeSalt: codeSalt ?? this.codeSalt,
      sentTo: sentTo ?? this.sentTo,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      consumedAt: consumedAt ?? this.consumedAt,
      invalidatedAt: invalidatedAt ?? this.invalidatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (codeHash.present) {
      map['code_hash'] = Variable<String>(codeHash.value);
    }
    if (codeSalt.present) {
      map['code_salt'] = Variable<String>(codeSalt.value);
    }
    if (sentTo.present) {
      map['sent_to'] = Variable<String>(sentTo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (failedAttempts.present) {
      map['failed_attempts'] = Variable<int>(failedAttempts.value);
    }
    if (consumedAt.present) {
      map['consumed_at'] = Variable<DateTime>(consumedAt.value);
    }
    if (invalidatedAt.present) {
      map['invalidated_at'] = Variable<DateTime>(invalidatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountRecoveryTokensCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('codeHash: $codeHash, ')
          ..write('codeSalt: $codeSalt, ')
          ..write('sentTo: $sentTo, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('invalidatedAt: $invalidatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareTeamAssignmentsTable extends CareTeamAssignments
    with TableInfo<$CareTeamAssignmentsTable, CareTeamAssignmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareTeamAssignmentsTable(this.attachedDatabase, [this._alias]);
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
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CareTeamRole, String> role =
      GeneratedColumn<String>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CareTeamRole>($CareTeamAssignmentsTable.$converterrole);
  static const VerificationMeta _assignedAtMeta = const VerificationMeta(
    'assignedAt',
  );
  @override
  late final GeneratedColumn<DateTime> assignedAt = GeneratedColumn<DateTime>(
    'assigned_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assignedByMeta = const VerificationMeta(
    'assignedBy',
  );
  @override
  late final GeneratedColumn<String> assignedBy = GeneratedColumn<String>(
    'assigned_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
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
    role,
    assignedAt,
    assignedBy,
    endedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'care_team_assignments';
  @override
  VerificationContext validateIntegrity(
    Insertable<CareTeamAssignmentRow> instance, {
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
    if (data.containsKey('assigned_at')) {
      context.handle(
        _assignedAtMeta,
        assignedAt.isAcceptableOrUnknown(data['assigned_at']!, _assignedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_assignedAtMeta);
    }
    if (data.containsKey('assigned_by')) {
      context.handle(
        _assignedByMeta,
        assignedBy.isAcceptableOrUnknown(data['assigned_by']!, _assignedByMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CareTeamAssignmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CareTeamAssignmentRow(
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
      role: $CareTeamAssignmentsTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}role'],
        )!,
      ),
      assignedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}assigned_at'],
      )!,
      assignedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_by'],
      ),
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
    );
  }

  @override
  $CareTeamAssignmentsTable createAlias(String alias) {
    return $CareTeamAssignmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CareTeamRole, String, String> $converterrole =
      const EnumNameConverter<CareTeamRole>(CareTeamRole.values);
}

class CareTeamAssignmentRow extends DataClass
    implements Insertable<CareTeamAssignmentRow> {
  final String id;
  final String patientId;
  final String staffId;
  final CareTeamRole role;
  final DateTime assignedAt;
  final String? assignedBy;
  final DateTime? endedAt;
  const CareTeamAssignmentRow({
    required this.id,
    required this.patientId,
    required this.staffId,
    required this.role,
    required this.assignedAt,
    this.assignedBy,
    this.endedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['staff_id'] = Variable<String>(staffId);
    {
      map['role'] = Variable<String>(
        $CareTeamAssignmentsTable.$converterrole.toSql(role),
      );
    }
    map['assigned_at'] = Variable<DateTime>(assignedAt);
    if (!nullToAbsent || assignedBy != null) {
      map['assigned_by'] = Variable<String>(assignedBy);
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    return map;
  }

  CareTeamAssignmentsCompanion toCompanion(bool nullToAbsent) {
    return CareTeamAssignmentsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      staffId: Value(staffId),
      role: Value(role),
      assignedAt: Value(assignedAt),
      assignedBy: assignedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedBy),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
    );
  }

  factory CareTeamAssignmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CareTeamAssignmentRow(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      staffId: serializer.fromJson<String>(json['staffId']),
      role: $CareTeamAssignmentsTable.$converterrole.fromJson(
        serializer.fromJson<String>(json['role']),
      ),
      assignedAt: serializer.fromJson<DateTime>(json['assignedAt']),
      assignedBy: serializer.fromJson<String?>(json['assignedBy']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'staffId': serializer.toJson<String>(staffId),
      'role': serializer.toJson<String>(
        $CareTeamAssignmentsTable.$converterrole.toJson(role),
      ),
      'assignedAt': serializer.toJson<DateTime>(assignedAt),
      'assignedBy': serializer.toJson<String?>(assignedBy),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
    };
  }

  CareTeamAssignmentRow copyWith({
    String? id,
    String? patientId,
    String? staffId,
    CareTeamRole? role,
    DateTime? assignedAt,
    Value<String?> assignedBy = const Value.absent(),
    Value<DateTime?> endedAt = const Value.absent(),
  }) => CareTeamAssignmentRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    staffId: staffId ?? this.staffId,
    role: role ?? this.role,
    assignedAt: assignedAt ?? this.assignedAt,
    assignedBy: assignedBy.present ? assignedBy.value : this.assignedBy,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
  );
  CareTeamAssignmentRow copyWithCompanion(CareTeamAssignmentsCompanion data) {
    return CareTeamAssignmentRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      role: data.role.present ? data.role.value : this.role,
      assignedAt: data.assignedAt.present
          ? data.assignedAt.value
          : this.assignedAt,
      assignedBy: data.assignedBy.present
          ? data.assignedBy.value
          : this.assignedBy,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CareTeamAssignmentRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('staffId: $staffId, ')
          ..write('role: $role, ')
          ..write('assignedAt: $assignedAt, ')
          ..write('assignedBy: $assignedBy, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    staffId,
    role,
    assignedAt,
    assignedBy,
    endedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CareTeamAssignmentRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.staffId == this.staffId &&
          other.role == this.role &&
          other.assignedAt == this.assignedAt &&
          other.assignedBy == this.assignedBy &&
          other.endedAt == this.endedAt);
}

class CareTeamAssignmentsCompanion
    extends UpdateCompanion<CareTeamAssignmentRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> staffId;
  final Value<CareTeamRole> role;
  final Value<DateTime> assignedAt;
  final Value<String?> assignedBy;
  final Value<DateTime?> endedAt;
  final Value<int> rowid;
  const CareTeamAssignmentsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.staffId = const Value.absent(),
    this.role = const Value.absent(),
    this.assignedAt = const Value.absent(),
    this.assignedBy = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareTeamAssignmentsCompanion.insert({
    required String id,
    required String patientId,
    required String staffId,
    required CareTeamRole role,
    required DateTime assignedAt,
    this.assignedBy = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       staffId = Value(staffId),
       role = Value(role),
       assignedAt = Value(assignedAt);
  static Insertable<CareTeamAssignmentRow> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? staffId,
    Expression<String>? role,
    Expression<DateTime>? assignedAt,
    Expression<String>? assignedBy,
    Expression<DateTime>? endedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (staffId != null) 'staff_id': staffId,
      if (role != null) 'role': role,
      if (assignedAt != null) 'assigned_at': assignedAt,
      if (assignedBy != null) 'assigned_by': assignedBy,
      if (endedAt != null) 'ended_at': endedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareTeamAssignmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String>? staffId,
    Value<CareTeamRole>? role,
    Value<DateTime>? assignedAt,
    Value<String?>? assignedBy,
    Value<DateTime?>? endedAt,
    Value<int>? rowid,
  }) {
    return CareTeamAssignmentsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      staffId: staffId ?? this.staffId,
      role: role ?? this.role,
      assignedAt: assignedAt ?? this.assignedAt,
      assignedBy: assignedBy ?? this.assignedBy,
      endedAt: endedAt ?? this.endedAt,
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
    if (role.present) {
      map['role'] = Variable<String>(
        $CareTeamAssignmentsTable.$converterrole.toSql(role.value),
      );
    }
    if (assignedAt.present) {
      map['assigned_at'] = Variable<DateTime>(assignedAt.value);
    }
    if (assignedBy.present) {
      map['assigned_by'] = Variable<String>(assignedBy.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareTeamAssignmentsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('staffId: $staffId, ')
          ..write('role: $role, ')
          ..write('assignedAt: $assignedAt, ')
          ..write('assignedBy: $assignedBy, ')
          ..write('endedAt: $endedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StaffCredentialsTable extends StaffCredentials
    with TableInfo<$StaffCredentialsTable, StaffCredentialRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StaffCredentialsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<CredentialKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CredentialKind>($StaffCredentialsTable.$converterkind);
  static const VerificationMeta _identifierMeta = const VerificationMeta(
    'identifier',
  );
  @override
  late final GeneratedColumn<String> identifier = GeneratedColumn<String>(
    'identifier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issuerMeta = const VerificationMeta('issuer');
  @override
  late final GeneratedColumn<String> issuer = GeneratedColumn<String>(
    'issuer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _validUntilMeta = const VerificationMeta(
    'validUntil',
  );
  @override
  late final GeneratedColumn<DateTime> validUntil = GeneratedColumn<DateTime>(
    'valid_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verifiedAtMeta = const VerificationMeta(
    'verifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> verifiedAt = GeneratedColumn<DateTime>(
    'verified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revokedAtMeta = const VerificationMeta(
    'revokedAt',
  );
  @override
  late final GeneratedColumn<DateTime> revokedAt = GeneratedColumn<DateTime>(
    'revoked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    staffId,
    kind,
    identifier,
    issuer,
    recordedAt,
    validUntil,
    verifiedAt,
    revokedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staff_credentials';
  @override
  VerificationContext validateIntegrity(
    Insertable<StaffCredentialRow> instance, {
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
    if (data.containsKey('identifier')) {
      context.handle(
        _identifierMeta,
        identifier.isAcceptableOrUnknown(data['identifier']!, _identifierMeta),
      );
    } else if (isInserting) {
      context.missing(_identifierMeta);
    }
    if (data.containsKey('issuer')) {
      context.handle(
        _issuerMeta,
        issuer.isAcceptableOrUnknown(data['issuer']!, _issuerMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('valid_until')) {
      context.handle(
        _validUntilMeta,
        validUntil.isAcceptableOrUnknown(data['valid_until']!, _validUntilMeta),
      );
    }
    if (data.containsKey('verified_at')) {
      context.handle(
        _verifiedAtMeta,
        verifiedAt.isAcceptableOrUnknown(data['verified_at']!, _verifiedAtMeta),
      );
    }
    if (data.containsKey('revoked_at')) {
      context.handle(
        _revokedAtMeta,
        revokedAt.isAcceptableOrUnknown(data['revoked_at']!, _revokedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StaffCredentialRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StaffCredentialRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      staffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staff_id'],
      )!,
      kind: $StaffCredentialsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      identifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identifier'],
      )!,
      issuer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issuer'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      validUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valid_until'],
      ),
      verifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}verified_at'],
      ),
      revokedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}revoked_at'],
      ),
    );
  }

  @override
  $StaffCredentialsTable createAlias(String alias) {
    return $StaffCredentialsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CredentialKind, String, String> $converterkind =
      const EnumNameConverter<CredentialKind>(CredentialKind.values);
}

class StaffCredentialRow extends DataClass
    implements Insertable<StaffCredentialRow> {
  final String id;
  final String staffId;
  final CredentialKind kind;
  final String identifier;
  final String? issuer;
  final DateTime recordedAt;
  final DateTime? validUntil;
  final DateTime? verifiedAt;
  final DateTime? revokedAt;
  const StaffCredentialRow({
    required this.id,
    required this.staffId,
    required this.kind,
    required this.identifier,
    this.issuer,
    required this.recordedAt,
    this.validUntil,
    this.verifiedAt,
    this.revokedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['staff_id'] = Variable<String>(staffId);
    {
      map['kind'] = Variable<String>(
        $StaffCredentialsTable.$converterkind.toSql(kind),
      );
    }
    map['identifier'] = Variable<String>(identifier);
    if (!nullToAbsent || issuer != null) {
      map['issuer'] = Variable<String>(issuer);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || validUntil != null) {
      map['valid_until'] = Variable<DateTime>(validUntil);
    }
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<DateTime>(verifiedAt);
    }
    if (!nullToAbsent || revokedAt != null) {
      map['revoked_at'] = Variable<DateTime>(revokedAt);
    }
    return map;
  }

  StaffCredentialsCompanion toCompanion(bool nullToAbsent) {
    return StaffCredentialsCompanion(
      id: Value(id),
      staffId: Value(staffId),
      kind: Value(kind),
      identifier: Value(identifier),
      issuer: issuer == null && nullToAbsent
          ? const Value.absent()
          : Value(issuer),
      recordedAt: Value(recordedAt),
      validUntil: validUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(validUntil),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
      revokedAt: revokedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(revokedAt),
    );
  }

  factory StaffCredentialRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StaffCredentialRow(
      id: serializer.fromJson<String>(json['id']),
      staffId: serializer.fromJson<String>(json['staffId']),
      kind: $StaffCredentialsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      identifier: serializer.fromJson<String>(json['identifier']),
      issuer: serializer.fromJson<String?>(json['issuer']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      validUntil: serializer.fromJson<DateTime?>(json['validUntil']),
      verifiedAt: serializer.fromJson<DateTime?>(json['verifiedAt']),
      revokedAt: serializer.fromJson<DateTime?>(json['revokedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'staffId': serializer.toJson<String>(staffId),
      'kind': serializer.toJson<String>(
        $StaffCredentialsTable.$converterkind.toJson(kind),
      ),
      'identifier': serializer.toJson<String>(identifier),
      'issuer': serializer.toJson<String?>(issuer),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'validUntil': serializer.toJson<DateTime?>(validUntil),
      'verifiedAt': serializer.toJson<DateTime?>(verifiedAt),
      'revokedAt': serializer.toJson<DateTime?>(revokedAt),
    };
  }

  StaffCredentialRow copyWith({
    String? id,
    String? staffId,
    CredentialKind? kind,
    String? identifier,
    Value<String?> issuer = const Value.absent(),
    DateTime? recordedAt,
    Value<DateTime?> validUntil = const Value.absent(),
    Value<DateTime?> verifiedAt = const Value.absent(),
    Value<DateTime?> revokedAt = const Value.absent(),
  }) => StaffCredentialRow(
    id: id ?? this.id,
    staffId: staffId ?? this.staffId,
    kind: kind ?? this.kind,
    identifier: identifier ?? this.identifier,
    issuer: issuer.present ? issuer.value : this.issuer,
    recordedAt: recordedAt ?? this.recordedAt,
    validUntil: validUntil.present ? validUntil.value : this.validUntil,
    verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
    revokedAt: revokedAt.present ? revokedAt.value : this.revokedAt,
  );
  StaffCredentialRow copyWithCompanion(StaffCredentialsCompanion data) {
    return StaffCredentialRow(
      id: data.id.present ? data.id.value : this.id,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      kind: data.kind.present ? data.kind.value : this.kind,
      identifier: data.identifier.present
          ? data.identifier.value
          : this.identifier,
      issuer: data.issuer.present ? data.issuer.value : this.issuer,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      validUntil: data.validUntil.present
          ? data.validUntil.value
          : this.validUntil,
      verifiedAt: data.verifiedAt.present
          ? data.verifiedAt.value
          : this.verifiedAt,
      revokedAt: data.revokedAt.present ? data.revokedAt.value : this.revokedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StaffCredentialRow(')
          ..write('id: $id, ')
          ..write('staffId: $staffId, ')
          ..write('kind: $kind, ')
          ..write('identifier: $identifier, ')
          ..write('issuer: $issuer, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('validUntil: $validUntil, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('revokedAt: $revokedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    staffId,
    kind,
    identifier,
    issuer,
    recordedAt,
    validUntil,
    verifiedAt,
    revokedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaffCredentialRow &&
          other.id == this.id &&
          other.staffId == this.staffId &&
          other.kind == this.kind &&
          other.identifier == this.identifier &&
          other.issuer == this.issuer &&
          other.recordedAt == this.recordedAt &&
          other.validUntil == this.validUntil &&
          other.verifiedAt == this.verifiedAt &&
          other.revokedAt == this.revokedAt);
}

class StaffCredentialsCompanion extends UpdateCompanion<StaffCredentialRow> {
  final Value<String> id;
  final Value<String> staffId;
  final Value<CredentialKind> kind;
  final Value<String> identifier;
  final Value<String?> issuer;
  final Value<DateTime> recordedAt;
  final Value<DateTime?> validUntil;
  final Value<DateTime?> verifiedAt;
  final Value<DateTime?> revokedAt;
  final Value<int> rowid;
  const StaffCredentialsCompanion({
    this.id = const Value.absent(),
    this.staffId = const Value.absent(),
    this.kind = const Value.absent(),
    this.identifier = const Value.absent(),
    this.issuer = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.validUntil = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StaffCredentialsCompanion.insert({
    required String id,
    required String staffId,
    required CredentialKind kind,
    required String identifier,
    this.issuer = const Value.absent(),
    required DateTime recordedAt,
    this.validUntil = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       staffId = Value(staffId),
       kind = Value(kind),
       identifier = Value(identifier),
       recordedAt = Value(recordedAt);
  static Insertable<StaffCredentialRow> custom({
    Expression<String>? id,
    Expression<String>? staffId,
    Expression<String>? kind,
    Expression<String>? identifier,
    Expression<String>? issuer,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? validUntil,
    Expression<DateTime>? verifiedAt,
    Expression<DateTime>? revokedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (staffId != null) 'staff_id': staffId,
      if (kind != null) 'kind': kind,
      if (identifier != null) 'identifier': identifier,
      if (issuer != null) 'issuer': issuer,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (validUntil != null) 'valid_until': validUntil,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (revokedAt != null) 'revoked_at': revokedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StaffCredentialsCompanion copyWith({
    Value<String>? id,
    Value<String>? staffId,
    Value<CredentialKind>? kind,
    Value<String>? identifier,
    Value<String?>? issuer,
    Value<DateTime>? recordedAt,
    Value<DateTime?>? validUntil,
    Value<DateTime?>? verifiedAt,
    Value<DateTime?>? revokedAt,
    Value<int>? rowid,
  }) {
    return StaffCredentialsCompanion(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      kind: kind ?? this.kind,
      identifier: identifier ?? this.identifier,
      issuer: issuer ?? this.issuer,
      recordedAt: recordedAt ?? this.recordedAt,
      validUntil: validUntil ?? this.validUntil,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      revokedAt: revokedAt ?? this.revokedAt,
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
    if (kind.present) {
      map['kind'] = Variable<String>(
        $StaffCredentialsTable.$converterkind.toSql(kind.value),
      );
    }
    if (identifier.present) {
      map['identifier'] = Variable<String>(identifier.value);
    }
    if (issuer.present) {
      map['issuer'] = Variable<String>(issuer.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (validUntil.present) {
      map['valid_until'] = Variable<DateTime>(validUntil.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<DateTime>(verifiedAt.value);
    }
    if (revokedAt.present) {
      map['revoked_at'] = Variable<DateTime>(revokedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StaffCredentialsCompanion(')
          ..write('id: $id, ')
          ..write('staffId: $staffId, ')
          ..write('kind: $kind, ')
          ..write('identifier: $identifier, ')
          ..write('issuer: $issuer, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('validUntil: $validUntil, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('revokedAt: $revokedAt, ')
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

class $AvailabilityExceptionsTable extends AvailabilityExceptions
    with TableInfo<$AvailabilityExceptionsTable, AvailabilityExceptionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AvailabilityExceptionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  @override
  late final GeneratedColumn<DateTime> startsAt = GeneratedColumn<DateTime>(
    'starts_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endsAtMeta = const VerificationMeta('endsAt');
  @override
  late final GeneratedColumn<DateTime> endsAt = GeneratedColumn<DateTime>(
    'ends_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    staffId,
    startsAt,
    endsAt,
    reason,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'availability_exceptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<AvailabilityExceptionRow> instance, {
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
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startsAtMeta);
    }
    if (data.containsKey('ends_at')) {
      context.handle(
        _endsAtMeta,
        endsAt.isAcceptableOrUnknown(data['ends_at']!, _endsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endsAtMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AvailabilityExceptionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AvailabilityExceptionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      staffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staff_id'],
      )!,
      startsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}starts_at'],
      )!,
      endsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ends_at'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $AvailabilityExceptionsTable createAlias(String alias) {
    return $AvailabilityExceptionsTable(attachedDatabase, alias);
  }
}

class AvailabilityExceptionRow extends DataClass
    implements Insertable<AvailabilityExceptionRow> {
  final String id;
  final String staffId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? reason;
  final int version;
  const AvailabilityExceptionRow({
    required this.id,
    required this.staffId,
    required this.startsAt,
    required this.endsAt,
    this.reason,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['staff_id'] = Variable<String>(staffId);
    map['starts_at'] = Variable<DateTime>(startsAt);
    map['ends_at'] = Variable<DateTime>(endsAt);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['version'] = Variable<int>(version);
    return map;
  }

  AvailabilityExceptionsCompanion toCompanion(bool nullToAbsent) {
    return AvailabilityExceptionsCompanion(
      id: Value(id),
      staffId: Value(staffId),
      startsAt: Value(startsAt),
      endsAt: Value(endsAt),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      version: Value(version),
    );
  }

  factory AvailabilityExceptionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AvailabilityExceptionRow(
      id: serializer.fromJson<String>(json['id']),
      staffId: serializer.fromJson<String>(json['staffId']),
      startsAt: serializer.fromJson<DateTime>(json['startsAt']),
      endsAt: serializer.fromJson<DateTime>(json['endsAt']),
      reason: serializer.fromJson<String?>(json['reason']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'staffId': serializer.toJson<String>(staffId),
      'startsAt': serializer.toJson<DateTime>(startsAt),
      'endsAt': serializer.toJson<DateTime>(endsAt),
      'reason': serializer.toJson<String?>(reason),
      'version': serializer.toJson<int>(version),
    };
  }

  AvailabilityExceptionRow copyWith({
    String? id,
    String? staffId,
    DateTime? startsAt,
    DateTime? endsAt,
    Value<String?> reason = const Value.absent(),
    int? version,
  }) => AvailabilityExceptionRow(
    id: id ?? this.id,
    staffId: staffId ?? this.staffId,
    startsAt: startsAt ?? this.startsAt,
    endsAt: endsAt ?? this.endsAt,
    reason: reason.present ? reason.value : this.reason,
    version: version ?? this.version,
  );
  AvailabilityExceptionRow copyWithCompanion(
    AvailabilityExceptionsCompanion data,
  ) {
    return AvailabilityExceptionRow(
      id: data.id.present ? data.id.value : this.id,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      endsAt: data.endsAt.present ? data.endsAt.value : this.endsAt,
      reason: data.reason.present ? data.reason.value : this.reason,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AvailabilityExceptionRow(')
          ..write('id: $id, ')
          ..write('staffId: $staffId, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('reason: $reason, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, staffId, startsAt, endsAt, reason, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AvailabilityExceptionRow &&
          other.id == this.id &&
          other.staffId == this.staffId &&
          other.startsAt == this.startsAt &&
          other.endsAt == this.endsAt &&
          other.reason == this.reason &&
          other.version == this.version);
}

class AvailabilityExceptionsCompanion
    extends UpdateCompanion<AvailabilityExceptionRow> {
  final Value<String> id;
  final Value<String> staffId;
  final Value<DateTime> startsAt;
  final Value<DateTime> endsAt;
  final Value<String?> reason;
  final Value<int> version;
  final Value<int> rowid;
  const AvailabilityExceptionsCompanion({
    this.id = const Value.absent(),
    this.staffId = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.reason = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AvailabilityExceptionsCompanion.insert({
    required String id,
    required String staffId,
    required DateTime startsAt,
    required DateTime endsAt,
    this.reason = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       staffId = Value(staffId),
       startsAt = Value(startsAt),
       endsAt = Value(endsAt);
  static Insertable<AvailabilityExceptionRow> custom({
    Expression<String>? id,
    Expression<String>? staffId,
    Expression<DateTime>? startsAt,
    Expression<DateTime>? endsAt,
    Expression<String>? reason,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (staffId != null) 'staff_id': staffId,
      if (startsAt != null) 'starts_at': startsAt,
      if (endsAt != null) 'ends_at': endsAt,
      if (reason != null) 'reason': reason,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AvailabilityExceptionsCompanion copyWith({
    Value<String>? id,
    Value<String>? staffId,
    Value<DateTime>? startsAt,
    Value<DateTime>? endsAt,
    Value<String?>? reason,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return AvailabilityExceptionsCompanion(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      reason: reason ?? this.reason,
      version: version ?? this.version,
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
    if (startsAt.present) {
      map['starts_at'] = Variable<DateTime>(startsAt.value);
    }
    if (endsAt.present) {
      map['ends_at'] = Variable<DateTime>(endsAt.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AvailabilityExceptionsCompanion(')
          ..write('id: $id, ')
          ..write('staffId: $staffId, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('reason: $reason, ')
          ..write('version: $version, ')
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
  static const VerificationMeta _calledInAtMeta = const VerificationMeta(
    'calledInAt',
  );
  @override
  late final GeneratedColumn<DateTime> calledInAt = GeneratedColumn<DateTime>(
    'called_in_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
  static const VerificationMeta _outcomeNoteMeta = const VerificationMeta(
    'outcomeNote',
  );
  @override
  late final GeneratedColumn<String> outcomeNote = GeneratedColumn<String>(
    'outcome_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ticketTagMeta = const VerificationMeta(
    'ticketTag',
  );
  @override
  late final GeneratedColumn<String> ticketTag = GeneratedColumn<String>(
    'ticket_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roomNumberMeta = const VerificationMeta(
    'roomNumber',
  );
  @override
  late final GeneratedColumn<String> roomNumber = GeneratedColumn<String>(
    'room_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookedForNameMeta = const VerificationMeta(
    'bookedForName',
  );
  @override
  late final GeneratedColumn<String> bookedForName = GeneratedColumn<String>(
    'booked_for_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookedByAccountIdMeta = const VerificationMeta(
    'bookedByAccountId',
  );
  @override
  late final GeneratedColumn<String> bookedByAccountId =
      GeneratedColumn<String>(
        'booked_by_account_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
    calledInAt,
    checkedInAt,
    outcomeNote,
    ticketTag,
    roomNumber,
    bookedForName,
    bookedByAccountId,
    version,
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
    if (data.containsKey('called_in_at')) {
      context.handle(
        _calledInAtMeta,
        calledInAt.isAcceptableOrUnknown(
          data['called_in_at']!,
          _calledInAtMeta,
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
    if (data.containsKey('outcome_note')) {
      context.handle(
        _outcomeNoteMeta,
        outcomeNote.isAcceptableOrUnknown(
          data['outcome_note']!,
          _outcomeNoteMeta,
        ),
      );
    }
    if (data.containsKey('ticket_tag')) {
      context.handle(
        _ticketTagMeta,
        ticketTag.isAcceptableOrUnknown(data['ticket_tag']!, _ticketTagMeta),
      );
    }
    if (data.containsKey('room_number')) {
      context.handle(
        _roomNumberMeta,
        roomNumber.isAcceptableOrUnknown(data['room_number']!, _roomNumberMeta),
      );
    }
    if (data.containsKey('booked_for_name')) {
      context.handle(
        _bookedForNameMeta,
        bookedForName.isAcceptableOrUnknown(
          data['booked_for_name']!,
          _bookedForNameMeta,
        ),
      );
    }
    if (data.containsKey('booked_by_account_id')) {
      context.handle(
        _bookedByAccountIdMeta,
        bookedByAccountId.isAcceptableOrUnknown(
          data['booked_by_account_id']!,
          _bookedByAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
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
      calledInAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}called_in_at'],
      ),
      checkedInAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}checked_in_at'],
      ),
      outcomeNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome_note'],
      ),
      ticketTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ticket_tag'],
      ),
      roomNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_number'],
      ),
      bookedForName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booked_for_name'],
      ),
      bookedByAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booked_by_account_id'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
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

  /// When the doctor pressed "Call patient" on the schedule ticket.
  final DateTime? calledInAt;

  /// When the doctor pressed "Patient arrived" — the visit moves to
  /// `inProgress` and the consultation page opens.
  final DateTime? checkedInAt;

  /// The doctor's closing summary, written at "Complete consultation".
  final String? outcomeNote;

  /// `[Hour letter A-X]-[facility-wide ticket number for that hour today]`,
  /// assigned once at booking time (redesign v2 patient dashboard spec).
  final String? ticketTag;

  /// `[Department letter]-[doctor's sequence within that department]`,
  /// assigned once at booking time (redesign v2 patient dashboard spec).
  final String? roomNumber;

  /// The linked family member this visit is for, when the account holder booked
  /// on someone else's behalf. Null = the account holder's own visit.
  final String? bookedForName;

  /// The signed-in account that made the booking. Differs from [patientId]
  /// when a guardian or proxy booked for someone else. Null on rows from
  /// before this was tracked.
  final String? bookedByAccountId;

  /// Optimistic-concurrency version, bumped on every update by a database
  /// trigger (schema v19) so no write path can forget. A write naming a
  /// stale version is refused with a conflict.
  final int version;
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
    this.calledInAt,
    this.checkedInAt,
    this.outcomeNote,
    this.ticketTag,
    this.roomNumber,
    this.bookedForName,
    this.bookedByAccountId,
    required this.version,
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
    if (!nullToAbsent || calledInAt != null) {
      map['called_in_at'] = Variable<DateTime>(calledInAt);
    }
    if (!nullToAbsent || checkedInAt != null) {
      map['checked_in_at'] = Variable<DateTime>(checkedInAt);
    }
    if (!nullToAbsent || outcomeNote != null) {
      map['outcome_note'] = Variable<String>(outcomeNote);
    }
    if (!nullToAbsent || ticketTag != null) {
      map['ticket_tag'] = Variable<String>(ticketTag);
    }
    if (!nullToAbsent || roomNumber != null) {
      map['room_number'] = Variable<String>(roomNumber);
    }
    if (!nullToAbsent || bookedForName != null) {
      map['booked_for_name'] = Variable<String>(bookedForName);
    }
    if (!nullToAbsent || bookedByAccountId != null) {
      map['booked_by_account_id'] = Variable<String>(bookedByAccountId);
    }
    map['version'] = Variable<int>(version);
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
      calledInAt: calledInAt == null && nullToAbsent
          ? const Value.absent()
          : Value(calledInAt),
      checkedInAt: checkedInAt == null && nullToAbsent
          ? const Value.absent()
          : Value(checkedInAt),
      outcomeNote: outcomeNote == null && nullToAbsent
          ? const Value.absent()
          : Value(outcomeNote),
      ticketTag: ticketTag == null && nullToAbsent
          ? const Value.absent()
          : Value(ticketTag),
      roomNumber: roomNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(roomNumber),
      bookedForName: bookedForName == null && nullToAbsent
          ? const Value.absent()
          : Value(bookedForName),
      bookedByAccountId: bookedByAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(bookedByAccountId),
      version: Value(version),
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
      calledInAt: serializer.fromJson<DateTime?>(json['calledInAt']),
      checkedInAt: serializer.fromJson<DateTime?>(json['checkedInAt']),
      outcomeNote: serializer.fromJson<String?>(json['outcomeNote']),
      ticketTag: serializer.fromJson<String?>(json['ticketTag']),
      roomNumber: serializer.fromJson<String?>(json['roomNumber']),
      bookedForName: serializer.fromJson<String?>(json['bookedForName']),
      bookedByAccountId: serializer.fromJson<String?>(
        json['bookedByAccountId'],
      ),
      version: serializer.fromJson<int>(json['version']),
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
      'calledInAt': serializer.toJson<DateTime?>(calledInAt),
      'checkedInAt': serializer.toJson<DateTime?>(checkedInAt),
      'outcomeNote': serializer.toJson<String?>(outcomeNote),
      'ticketTag': serializer.toJson<String?>(ticketTag),
      'roomNumber': serializer.toJson<String?>(roomNumber),
      'bookedForName': serializer.toJson<String?>(bookedForName),
      'bookedByAccountId': serializer.toJson<String?>(bookedByAccountId),
      'version': serializer.toJson<int>(version),
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
    Value<DateTime?> calledInAt = const Value.absent(),
    Value<DateTime?> checkedInAt = const Value.absent(),
    Value<String?> outcomeNote = const Value.absent(),
    Value<String?> ticketTag = const Value.absent(),
    Value<String?> roomNumber = const Value.absent(),
    Value<String?> bookedForName = const Value.absent(),
    Value<String?> bookedByAccountId = const Value.absent(),
    int? version,
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
    calledInAt: calledInAt.present ? calledInAt.value : this.calledInAt,
    checkedInAt: checkedInAt.present ? checkedInAt.value : this.checkedInAt,
    outcomeNote: outcomeNote.present ? outcomeNote.value : this.outcomeNote,
    ticketTag: ticketTag.present ? ticketTag.value : this.ticketTag,
    roomNumber: roomNumber.present ? roomNumber.value : this.roomNumber,
    bookedForName: bookedForName.present
        ? bookedForName.value
        : this.bookedForName,
    bookedByAccountId: bookedByAccountId.present
        ? bookedByAccountId.value
        : this.bookedByAccountId,
    version: version ?? this.version,
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
      calledInAt: data.calledInAt.present
          ? data.calledInAt.value
          : this.calledInAt,
      checkedInAt: data.checkedInAt.present
          ? data.checkedInAt.value
          : this.checkedInAt,
      outcomeNote: data.outcomeNote.present
          ? data.outcomeNote.value
          : this.outcomeNote,
      ticketTag: data.ticketTag.present ? data.ticketTag.value : this.ticketTag,
      roomNumber: data.roomNumber.present
          ? data.roomNumber.value
          : this.roomNumber,
      bookedForName: data.bookedForName.present
          ? data.bookedForName.value
          : this.bookedForName,
      bookedByAccountId: data.bookedByAccountId.present
          ? data.bookedByAccountId.value
          : this.bookedByAccountId,
      version: data.version.present ? data.version.value : this.version,
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
          ..write('calledInAt: $calledInAt, ')
          ..write('checkedInAt: $checkedInAt, ')
          ..write('outcomeNote: $outcomeNote, ')
          ..write('ticketTag: $ticketTag, ')
          ..write('roomNumber: $roomNumber, ')
          ..write('bookedForName: $bookedForName, ')
          ..write('bookedByAccountId: $bookedByAccountId, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
    calledInAt,
    checkedInAt,
    outcomeNote,
    ticketTag,
    roomNumber,
    bookedForName,
    bookedByAccountId,
    version,
  ]);
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
          other.calledInAt == this.calledInAt &&
          other.checkedInAt == this.checkedInAt &&
          other.outcomeNote == this.outcomeNote &&
          other.ticketTag == this.ticketTag &&
          other.roomNumber == this.roomNumber &&
          other.bookedForName == this.bookedForName &&
          other.bookedByAccountId == this.bookedByAccountId &&
          other.version == this.version);
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
  final Value<DateTime?> calledInAt;
  final Value<DateTime?> checkedInAt;
  final Value<String?> outcomeNote;
  final Value<String?> ticketTag;
  final Value<String?> roomNumber;
  final Value<String?> bookedForName;
  final Value<String?> bookedByAccountId;
  final Value<int> version;
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
    this.calledInAt = const Value.absent(),
    this.checkedInAt = const Value.absent(),
    this.outcomeNote = const Value.absent(),
    this.ticketTag = const Value.absent(),
    this.roomNumber = const Value.absent(),
    this.bookedForName = const Value.absent(),
    this.bookedByAccountId = const Value.absent(),
    this.version = const Value.absent(),
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
    this.calledInAt = const Value.absent(),
    this.checkedInAt = const Value.absent(),
    this.outcomeNote = const Value.absent(),
    this.ticketTag = const Value.absent(),
    this.roomNumber = const Value.absent(),
    this.bookedForName = const Value.absent(),
    this.bookedByAccountId = const Value.absent(),
    this.version = const Value.absent(),
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
    Expression<DateTime>? calledInAt,
    Expression<DateTime>? checkedInAt,
    Expression<String>? outcomeNote,
    Expression<String>? ticketTag,
    Expression<String>? roomNumber,
    Expression<String>? bookedForName,
    Expression<String>? bookedByAccountId,
    Expression<int>? version,
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
      if (calledInAt != null) 'called_in_at': calledInAt,
      if (checkedInAt != null) 'checked_in_at': checkedInAt,
      if (outcomeNote != null) 'outcome_note': outcomeNote,
      if (ticketTag != null) 'ticket_tag': ticketTag,
      if (roomNumber != null) 'room_number': roomNumber,
      if (bookedForName != null) 'booked_for_name': bookedForName,
      if (bookedByAccountId != null) 'booked_by_account_id': bookedByAccountId,
      if (version != null) 'version': version,
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
    Value<DateTime?>? calledInAt,
    Value<DateTime?>? checkedInAt,
    Value<String?>? outcomeNote,
    Value<String?>? ticketTag,
    Value<String?>? roomNumber,
    Value<String?>? bookedForName,
    Value<String?>? bookedByAccountId,
    Value<int>? version,
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
      calledInAt: calledInAt ?? this.calledInAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      outcomeNote: outcomeNote ?? this.outcomeNote,
      ticketTag: ticketTag ?? this.ticketTag,
      roomNumber: roomNumber ?? this.roomNumber,
      bookedForName: bookedForName ?? this.bookedForName,
      bookedByAccountId: bookedByAccountId ?? this.bookedByAccountId,
      version: version ?? this.version,
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
    if (calledInAt.present) {
      map['called_in_at'] = Variable<DateTime>(calledInAt.value);
    }
    if (checkedInAt.present) {
      map['checked_in_at'] = Variable<DateTime>(checkedInAt.value);
    }
    if (outcomeNote.present) {
      map['outcome_note'] = Variable<String>(outcomeNote.value);
    }
    if (ticketTag.present) {
      map['ticket_tag'] = Variable<String>(ticketTag.value);
    }
    if (roomNumber.present) {
      map['room_number'] = Variable<String>(roomNumber.value);
    }
    if (bookedForName.present) {
      map['booked_for_name'] = Variable<String>(bookedForName.value);
    }
    if (bookedByAccountId.present) {
      map['booked_by_account_id'] = Variable<String>(bookedByAccountId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
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
          ..write('calledInAt: $calledInAt, ')
          ..write('checkedInAt: $checkedInAt, ')
          ..write('outcomeNote: $outcomeNote, ')
          ..write('ticketTag: $ticketTag, ')
          ..write('roomNumber: $roomNumber, ')
          ..write('bookedForName: $bookedForName, ')
          ..write('bookedByAccountId: $bookedByAccountId, ')
          ..write('version: $version, ')
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
  @override
  late final GeneratedColumnWithTypeConverter<ReminderDeliveryStatus, String>
  deliveryStatus =
      GeneratedColumn<String>(
        'delivery_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('queued'),
      ).withConverter<ReminderDeliveryStatus>(
        $RemindersTable.$converterdeliveryStatus,
      );
  static const VerificationMeta _deliveryAttemptsMeta = const VerificationMeta(
    'deliveryAttempts',
  );
  @override
  late final GeneratedColumn<int> deliveryAttempts = GeneratedColumn<int>(
    'delivery_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
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
    deliveryStatus,
    deliveryAttempts,
    lastError,
    nextAttemptAt,
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
    if (data.containsKey('delivery_attempts')) {
      context.handle(
        _deliveryAttemptsMeta,
        deliveryAttempts.isAcceptableOrUnknown(
          data['delivery_attempts']!,
          _deliveryAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
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
      deliveryStatus: $RemindersTable.$converterdeliveryStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}delivery_status'],
        )!,
      ),
      deliveryAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delivery_attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
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
  static JsonTypeConverter2<ReminderDeliveryStatus, String, String>
  $converterdeliveryStatus = const EnumNameConverter<ReminderDeliveryStatus>(
    ReminderDeliveryStatus.values,
  );
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final String id;
  final String appointmentId;
  final DateTime scheduledFor;
  final ReminderChannel channel;
  final ReminderKind kind;
  final ReminderDeliveryStatus deliveryStatus;
  final int deliveryAttempts;
  final String? lastError;

  /// Earliest retry after a transient delivery failure (schema v24). Null
  /// means "as soon as it is due".
  final DateTime? nextAttemptAt;
  final DateTime? sentAt;
  final bool acknowledged;
  const ReminderRow({
    required this.id,
    required this.appointmentId,
    required this.scheduledFor,
    required this.channel,
    required this.kind,
    required this.deliveryStatus,
    required this.deliveryAttempts,
    this.lastError,
    this.nextAttemptAt,
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
    {
      map['delivery_status'] = Variable<String>(
        $RemindersTable.$converterdeliveryStatus.toSql(deliveryStatus),
      );
    }
    map['delivery_attempts'] = Variable<int>(deliveryAttempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
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
      deliveryStatus: Value(deliveryStatus),
      deliveryAttempts: Value(deliveryAttempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
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
      deliveryStatus: $RemindersTable.$converterdeliveryStatus.fromJson(
        serializer.fromJson<String>(json['deliveryStatus']),
      ),
      deliveryAttempts: serializer.fromJson<int>(json['deliveryAttempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
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
      'deliveryStatus': serializer.toJson<String>(
        $RemindersTable.$converterdeliveryStatus.toJson(deliveryStatus),
      ),
      'deliveryAttempts': serializer.toJson<int>(deliveryAttempts),
      'lastError': serializer.toJson<String?>(lastError),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
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
    ReminderDeliveryStatus? deliveryStatus,
    int? deliveryAttempts,
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<DateTime?> sentAt = const Value.absent(),
    bool? acknowledged,
  }) => ReminderRow(
    id: id ?? this.id,
    appointmentId: appointmentId ?? this.appointmentId,
    scheduledFor: scheduledFor ?? this.scheduledFor,
    channel: channel ?? this.channel,
    kind: kind ?? this.kind,
    deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    deliveryAttempts: deliveryAttempts ?? this.deliveryAttempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
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
      deliveryStatus: data.deliveryStatus.present
          ? data.deliveryStatus.value
          : this.deliveryStatus,
      deliveryAttempts: data.deliveryAttempts.present
          ? data.deliveryAttempts.value
          : this.deliveryAttempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
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
          ..write('deliveryStatus: $deliveryStatus, ')
          ..write('deliveryAttempts: $deliveryAttempts, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
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
    deliveryStatus,
    deliveryAttempts,
    lastError,
    nextAttemptAt,
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
          other.deliveryStatus == this.deliveryStatus &&
          other.deliveryAttempts == this.deliveryAttempts &&
          other.lastError == this.lastError &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.sentAt == this.sentAt &&
          other.acknowledged == this.acknowledged);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<String> id;
  final Value<String> appointmentId;
  final Value<DateTime> scheduledFor;
  final Value<ReminderChannel> channel;
  final Value<ReminderKind> kind;
  final Value<ReminderDeliveryStatus> deliveryStatus;
  final Value<int> deliveryAttempts;
  final Value<String?> lastError;
  final Value<DateTime?> nextAttemptAt;
  final Value<DateTime?> sentAt;
  final Value<bool> acknowledged;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.appointmentId = const Value.absent(),
    this.scheduledFor = const Value.absent(),
    this.channel = const Value.absent(),
    this.kind = const Value.absent(),
    this.deliveryStatus = const Value.absent(),
    this.deliveryAttempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
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
    this.deliveryStatus = const Value.absent(),
    this.deliveryAttempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
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
    Expression<String>? deliveryStatus,
    Expression<int>? deliveryAttempts,
    Expression<String>? lastError,
    Expression<DateTime>? nextAttemptAt,
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
      if (deliveryStatus != null) 'delivery_status': deliveryStatus,
      if (deliveryAttempts != null) 'delivery_attempts': deliveryAttempts,
      if (lastError != null) 'last_error': lastError,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
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
    Value<ReminderDeliveryStatus>? deliveryStatus,
    Value<int>? deliveryAttempts,
    Value<String?>? lastError,
    Value<DateTime?>? nextAttemptAt,
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
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      deliveryAttempts: deliveryAttempts ?? this.deliveryAttempts,
      lastError: lastError ?? this.lastError,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
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
    if (deliveryStatus.present) {
      map['delivery_status'] = Variable<String>(
        $RemindersTable.$converterdeliveryStatus.toSql(deliveryStatus.value),
      );
    }
    if (deliveryAttempts.present) {
      map['delivery_attempts'] = Variable<int>(deliveryAttempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
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
          ..write('deliveryStatus: $deliveryStatus, ')
          ..write('deliveryAttempts: $deliveryAttempts, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
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
  static const VerificationMeta _appointmentIdMeta = const VerificationMeta(
    'appointmentId',
  );
  @override
  late final GeneratedColumn<String> appointmentId = GeneratedColumn<String>(
    'appointment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES appointments (id) ON DELETE SET NULL',
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
  @override
  late final GeneratedColumnWithTypeConverter<ReferralUrgency?, String>
  referralUrgency =
      GeneratedColumn<String>(
        'referral_urgency',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ReferralUrgency?>(
        $MedicalRecordsTable.$converterreferralUrgencyn,
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
  static const VerificationMeta _uploadedByPatientMeta = const VerificationMeta(
    'uploadedByPatient',
  );
  @override
  late final GeneratedColumn<bool> uploadedByPatient = GeneratedColumn<bool>(
    'uploaded_by_patient',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("uploaded_by_patient" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdByAccountIdMeta =
      const VerificationMeta('createdByAccountId');
  @override
  late final GeneratedColumn<String> createdByAccountId =
      GeneratedColumn<String>(
        'created_by_account_id',
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
  late final GeneratedColumnWithTypeConverter<ImportReviewStatus, String>
  reviewStatus =
      GeneratedColumn<String>(
        'review_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('notRequired'),
      ).withConverter<ImportReviewStatus>(
        $MedicalRecordsTable.$converterreviewStatus,
      );
  static const VerificationMeta _reviewedByStaffIdMeta = const VerificationMeta(
    'reviewedByStaffId',
  );
  @override
  late final GeneratedColumn<String> reviewedByStaffId =
      GeneratedColumn<String>(
        'reviewed_by_staff_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES users (id)',
        ),
      );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewNoteMeta = const VerificationMeta(
    'reviewNote',
  );
  @override
  late final GeneratedColumn<String> reviewNote = GeneratedColumn<String>(
    'review_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    authorStaffId,
    appointmentId,
    recordType,
    title,
    body,
    occurredAt,
    sourceFacility,
    referralUrgency,
    attachmentPath,
    extractedText,
    uploadedByPatient,
    createdByAccountId,
    createdAt,
    reviewStatus,
    reviewedByStaffId,
    reviewedAt,
    reviewNote,
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
    if (data.containsKey('appointment_id')) {
      context.handle(
        _appointmentIdMeta,
        appointmentId.isAcceptableOrUnknown(
          data['appointment_id']!,
          _appointmentIdMeta,
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
    if (data.containsKey('uploaded_by_patient')) {
      context.handle(
        _uploadedByPatientMeta,
        uploadedByPatient.isAcceptableOrUnknown(
          data['uploaded_by_patient']!,
          _uploadedByPatientMeta,
        ),
      );
    }
    if (data.containsKey('created_by_account_id')) {
      context.handle(
        _createdByAccountIdMeta,
        createdByAccountId.isAcceptableOrUnknown(
          data['created_by_account_id']!,
          _createdByAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('reviewed_by_staff_id')) {
      context.handle(
        _reviewedByStaffIdMeta,
        reviewedByStaffId.isAcceptableOrUnknown(
          data['reviewed_by_staff_id']!,
          _reviewedByStaffIdMeta,
        ),
      );
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    }
    if (data.containsKey('review_note')) {
      context.handle(
        _reviewNoteMeta,
        reviewNote.isAcceptableOrUnknown(data['review_note']!, _reviewNoteMeta),
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
      appointmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appointment_id'],
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
      referralUrgency: $MedicalRecordsTable.$converterreferralUrgencyn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}referral_urgency'],
        ),
      ),
      attachmentPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_path'],
      ),
      extractedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_text'],
      ),
      uploadedByPatient: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}uploaded_by_patient'],
      )!,
      createdByAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_account_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      reviewStatus: $MedicalRecordsTable.$converterreviewStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}review_status'],
        )!,
      ),
      reviewedByStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reviewed_by_staff_id'],
      ),
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      ),
      reviewNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_note'],
      ),
    );
  }

  @override
  $MedicalRecordsTable createAlias(String alias) {
    return $MedicalRecordsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RecordType, String, String> $converterrecordType =
      const EnumNameConverter<RecordType>(RecordType.values);
  static JsonTypeConverter2<ReferralUrgency, String, String>
  $converterreferralUrgency = const EnumNameConverter<ReferralUrgency>(
    ReferralUrgency.values,
  );
  static JsonTypeConverter2<ReferralUrgency?, String?, String?>
  $converterreferralUrgencyn = JsonTypeConverter2.asNullable(
    $converterreferralUrgency,
  );
  static JsonTypeConverter2<ImportReviewStatus, String, String>
  $converterreviewStatus = const EnumNameConverter<ImportReviewStatus>(
    ImportReviewStatus.values,
  );
}

class MedicalRecordRow extends DataClass
    implements Insertable<MedicalRecordRow> {
  final String id;
  final String patientId;

  /// Null for patient-imported records (P2-12).
  final String? authorStaffId;

  /// The visit this record was produced in, if any (a consultation note, a
  /// prescription record). Kept if the appointment is later removed.
  final String? appointmentId;
  final RecordType recordType;
  final String title;
  final String? body;
  final DateTime occurredAt;
  final String? sourceFacility;

  /// For a referral: how soon the patient should be seen. Stored by name.
  final ReferralUrgency? referralUrgency;

  /// Local path to an imported file (PDF, image), copied into app storage.
  final String? attachmentPath;

  /// Text pulled out of [attachmentPath] by the PDF extractor (P2-11), fed to
  /// the AI context builder (P3-02).
  final String? extractedText;

  /// True when the patient imported this themselves. Such a record has not
  /// been reviewed by a clinician and must never read as a clinic result.
  final bool uploadedByPatient;

  /// The signed-in account that created the record (a clinician, the
  /// patient, or a proxy uploading for them). Null on older rows.
  final String? createdByAccountId;
  final DateTime createdAt;

  /// Whether a clinician has reviewed a patient import. Clinic-authored
  /// records are `notRequired`. Stored by name.
  final ImportReviewStatus reviewStatus;
  final String? reviewedByStaffId;
  final DateTime? reviewedAt;
  final String? reviewNote;
  const MedicalRecordRow({
    required this.id,
    required this.patientId,
    this.authorStaffId,
    this.appointmentId,
    required this.recordType,
    required this.title,
    this.body,
    required this.occurredAt,
    this.sourceFacility,
    this.referralUrgency,
    this.attachmentPath,
    this.extractedText,
    required this.uploadedByPatient,
    this.createdByAccountId,
    required this.createdAt,
    required this.reviewStatus,
    this.reviewedByStaffId,
    this.reviewedAt,
    this.reviewNote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    if (!nullToAbsent || authorStaffId != null) {
      map['author_staff_id'] = Variable<String>(authorStaffId);
    }
    if (!nullToAbsent || appointmentId != null) {
      map['appointment_id'] = Variable<String>(appointmentId);
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
    if (!nullToAbsent || referralUrgency != null) {
      map['referral_urgency'] = Variable<String>(
        $MedicalRecordsTable.$converterreferralUrgencyn.toSql(referralUrgency),
      );
    }
    if (!nullToAbsent || attachmentPath != null) {
      map['attachment_path'] = Variable<String>(attachmentPath);
    }
    if (!nullToAbsent || extractedText != null) {
      map['extracted_text'] = Variable<String>(extractedText);
    }
    map['uploaded_by_patient'] = Variable<bool>(uploadedByPatient);
    if (!nullToAbsent || createdByAccountId != null) {
      map['created_by_account_id'] = Variable<String>(createdByAccountId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    {
      map['review_status'] = Variable<String>(
        $MedicalRecordsTable.$converterreviewStatus.toSql(reviewStatus),
      );
    }
    if (!nullToAbsent || reviewedByStaffId != null) {
      map['reviewed_by_staff_id'] = Variable<String>(reviewedByStaffId);
    }
    if (!nullToAbsent || reviewedAt != null) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    }
    if (!nullToAbsent || reviewNote != null) {
      map['review_note'] = Variable<String>(reviewNote);
    }
    return map;
  }

  MedicalRecordsCompanion toCompanion(bool nullToAbsent) {
    return MedicalRecordsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      authorStaffId: authorStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(authorStaffId),
      appointmentId: appointmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(appointmentId),
      recordType: Value(recordType),
      title: Value(title),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      occurredAt: Value(occurredAt),
      sourceFacility: sourceFacility == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceFacility),
      referralUrgency: referralUrgency == null && nullToAbsent
          ? const Value.absent()
          : Value(referralUrgency),
      attachmentPath: attachmentPath == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentPath),
      extractedText: extractedText == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedText),
      uploadedByPatient: Value(uploadedByPatient),
      createdByAccountId: createdByAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByAccountId),
      createdAt: Value(createdAt),
      reviewStatus: Value(reviewStatus),
      reviewedByStaffId: reviewedByStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedByStaffId),
      reviewedAt: reviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedAt),
      reviewNote: reviewNote == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewNote),
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
      appointmentId: serializer.fromJson<String?>(json['appointmentId']),
      recordType: $MedicalRecordsTable.$converterrecordType.fromJson(
        serializer.fromJson<String>(json['recordType']),
      ),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String?>(json['body']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      sourceFacility: serializer.fromJson<String?>(json['sourceFacility']),
      referralUrgency: $MedicalRecordsTable.$converterreferralUrgencyn.fromJson(
        serializer.fromJson<String?>(json['referralUrgency']),
      ),
      attachmentPath: serializer.fromJson<String?>(json['attachmentPath']),
      extractedText: serializer.fromJson<String?>(json['extractedText']),
      uploadedByPatient: serializer.fromJson<bool>(json['uploadedByPatient']),
      createdByAccountId: serializer.fromJson<String?>(
        json['createdByAccountId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      reviewStatus: $MedicalRecordsTable.$converterreviewStatus.fromJson(
        serializer.fromJson<String>(json['reviewStatus']),
      ),
      reviewedByStaffId: serializer.fromJson<String?>(
        json['reviewedByStaffId'],
      ),
      reviewedAt: serializer.fromJson<DateTime?>(json['reviewedAt']),
      reviewNote: serializer.fromJson<String?>(json['reviewNote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'authorStaffId': serializer.toJson<String?>(authorStaffId),
      'appointmentId': serializer.toJson<String?>(appointmentId),
      'recordType': serializer.toJson<String>(
        $MedicalRecordsTable.$converterrecordType.toJson(recordType),
      ),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String?>(body),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'sourceFacility': serializer.toJson<String?>(sourceFacility),
      'referralUrgency': serializer.toJson<String?>(
        $MedicalRecordsTable.$converterreferralUrgencyn.toJson(referralUrgency),
      ),
      'attachmentPath': serializer.toJson<String?>(attachmentPath),
      'extractedText': serializer.toJson<String?>(extractedText),
      'uploadedByPatient': serializer.toJson<bool>(uploadedByPatient),
      'createdByAccountId': serializer.toJson<String?>(createdByAccountId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'reviewStatus': serializer.toJson<String>(
        $MedicalRecordsTable.$converterreviewStatus.toJson(reviewStatus),
      ),
      'reviewedByStaffId': serializer.toJson<String?>(reviewedByStaffId),
      'reviewedAt': serializer.toJson<DateTime?>(reviewedAt),
      'reviewNote': serializer.toJson<String?>(reviewNote),
    };
  }

  MedicalRecordRow copyWith({
    String? id,
    String? patientId,
    Value<String?> authorStaffId = const Value.absent(),
    Value<String?> appointmentId = const Value.absent(),
    RecordType? recordType,
    String? title,
    Value<String?> body = const Value.absent(),
    DateTime? occurredAt,
    Value<String?> sourceFacility = const Value.absent(),
    Value<ReferralUrgency?> referralUrgency = const Value.absent(),
    Value<String?> attachmentPath = const Value.absent(),
    Value<String?> extractedText = const Value.absent(),
    bool? uploadedByPatient,
    Value<String?> createdByAccountId = const Value.absent(),
    DateTime? createdAt,
    ImportReviewStatus? reviewStatus,
    Value<String?> reviewedByStaffId = const Value.absent(),
    Value<DateTime?> reviewedAt = const Value.absent(),
    Value<String?> reviewNote = const Value.absent(),
  }) => MedicalRecordRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    authorStaffId: authorStaffId.present
        ? authorStaffId.value
        : this.authorStaffId,
    appointmentId: appointmentId.present
        ? appointmentId.value
        : this.appointmentId,
    recordType: recordType ?? this.recordType,
    title: title ?? this.title,
    body: body.present ? body.value : this.body,
    occurredAt: occurredAt ?? this.occurredAt,
    sourceFacility: sourceFacility.present
        ? sourceFacility.value
        : this.sourceFacility,
    referralUrgency: referralUrgency.present
        ? referralUrgency.value
        : this.referralUrgency,
    attachmentPath: attachmentPath.present
        ? attachmentPath.value
        : this.attachmentPath,
    extractedText: extractedText.present
        ? extractedText.value
        : this.extractedText,
    uploadedByPatient: uploadedByPatient ?? this.uploadedByPatient,
    createdByAccountId: createdByAccountId.present
        ? createdByAccountId.value
        : this.createdByAccountId,
    createdAt: createdAt ?? this.createdAt,
    reviewStatus: reviewStatus ?? this.reviewStatus,
    reviewedByStaffId: reviewedByStaffId.present
        ? reviewedByStaffId.value
        : this.reviewedByStaffId,
    reviewedAt: reviewedAt.present ? reviewedAt.value : this.reviewedAt,
    reviewNote: reviewNote.present ? reviewNote.value : this.reviewNote,
  );
  MedicalRecordRow copyWithCompanion(MedicalRecordsCompanion data) {
    return MedicalRecordRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      authorStaffId: data.authorStaffId.present
          ? data.authorStaffId.value
          : this.authorStaffId,
      appointmentId: data.appointmentId.present
          ? data.appointmentId.value
          : this.appointmentId,
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
      referralUrgency: data.referralUrgency.present
          ? data.referralUrgency.value
          : this.referralUrgency,
      attachmentPath: data.attachmentPath.present
          ? data.attachmentPath.value
          : this.attachmentPath,
      extractedText: data.extractedText.present
          ? data.extractedText.value
          : this.extractedText,
      uploadedByPatient: data.uploadedByPatient.present
          ? data.uploadedByPatient.value
          : this.uploadedByPatient,
      createdByAccountId: data.createdByAccountId.present
          ? data.createdByAccountId.value
          : this.createdByAccountId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      reviewStatus: data.reviewStatus.present
          ? data.reviewStatus.value
          : this.reviewStatus,
      reviewedByStaffId: data.reviewedByStaffId.present
          ? data.reviewedByStaffId.value
          : this.reviewedByStaffId,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      reviewNote: data.reviewNote.present
          ? data.reviewNote.value
          : this.reviewNote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicalRecordRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('authorStaffId: $authorStaffId, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('recordType: $recordType, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('sourceFacility: $sourceFacility, ')
          ..write('referralUrgency: $referralUrgency, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('extractedText: $extractedText, ')
          ..write('uploadedByPatient: $uploadedByPatient, ')
          ..write('createdByAccountId: $createdByAccountId, ')
          ..write('createdAt: $createdAt, ')
          ..write('reviewStatus: $reviewStatus, ')
          ..write('reviewedByStaffId: $reviewedByStaffId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('reviewNote: $reviewNote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    authorStaffId,
    appointmentId,
    recordType,
    title,
    body,
    occurredAt,
    sourceFacility,
    referralUrgency,
    attachmentPath,
    extractedText,
    uploadedByPatient,
    createdByAccountId,
    createdAt,
    reviewStatus,
    reviewedByStaffId,
    reviewedAt,
    reviewNote,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicalRecordRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.authorStaffId == this.authorStaffId &&
          other.appointmentId == this.appointmentId &&
          other.recordType == this.recordType &&
          other.title == this.title &&
          other.body == this.body &&
          other.occurredAt == this.occurredAt &&
          other.sourceFacility == this.sourceFacility &&
          other.referralUrgency == this.referralUrgency &&
          other.attachmentPath == this.attachmentPath &&
          other.extractedText == this.extractedText &&
          other.uploadedByPatient == this.uploadedByPatient &&
          other.createdByAccountId == this.createdByAccountId &&
          other.createdAt == this.createdAt &&
          other.reviewStatus == this.reviewStatus &&
          other.reviewedByStaffId == this.reviewedByStaffId &&
          other.reviewedAt == this.reviewedAt &&
          other.reviewNote == this.reviewNote);
}

class MedicalRecordsCompanion extends UpdateCompanion<MedicalRecordRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String?> authorStaffId;
  final Value<String?> appointmentId;
  final Value<RecordType> recordType;
  final Value<String> title;
  final Value<String?> body;
  final Value<DateTime> occurredAt;
  final Value<String?> sourceFacility;
  final Value<ReferralUrgency?> referralUrgency;
  final Value<String?> attachmentPath;
  final Value<String?> extractedText;
  final Value<bool> uploadedByPatient;
  final Value<String?> createdByAccountId;
  final Value<DateTime> createdAt;
  final Value<ImportReviewStatus> reviewStatus;
  final Value<String?> reviewedByStaffId;
  final Value<DateTime?> reviewedAt;
  final Value<String?> reviewNote;
  final Value<int> rowid;
  const MedicalRecordsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.authorStaffId = const Value.absent(),
    this.appointmentId = const Value.absent(),
    this.recordType = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.sourceFacility = const Value.absent(),
    this.referralUrgency = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.extractedText = const Value.absent(),
    this.uploadedByPatient = const Value.absent(),
    this.createdByAccountId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.reviewStatus = const Value.absent(),
    this.reviewedByStaffId = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.reviewNote = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicalRecordsCompanion.insert({
    required String id,
    required String patientId,
    this.authorStaffId = const Value.absent(),
    this.appointmentId = const Value.absent(),
    required RecordType recordType,
    required String title,
    this.body = const Value.absent(),
    required DateTime occurredAt,
    this.sourceFacility = const Value.absent(),
    this.referralUrgency = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.extractedText = const Value.absent(),
    this.uploadedByPatient = const Value.absent(),
    this.createdByAccountId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.reviewStatus = const Value.absent(),
    this.reviewedByStaffId = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.reviewNote = const Value.absent(),
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
    Expression<String>? appointmentId,
    Expression<String>? recordType,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? occurredAt,
    Expression<String>? sourceFacility,
    Expression<String>? referralUrgency,
    Expression<String>? attachmentPath,
    Expression<String>? extractedText,
    Expression<bool>? uploadedByPatient,
    Expression<String>? createdByAccountId,
    Expression<DateTime>? createdAt,
    Expression<String>? reviewStatus,
    Expression<String>? reviewedByStaffId,
    Expression<DateTime>? reviewedAt,
    Expression<String>? reviewNote,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (authorStaffId != null) 'author_staff_id': authorStaffId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (recordType != null) 'record_type': recordType,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (sourceFacility != null) 'source_facility': sourceFacility,
      if (referralUrgency != null) 'referral_urgency': referralUrgency,
      if (attachmentPath != null) 'attachment_path': attachmentPath,
      if (extractedText != null) 'extracted_text': extractedText,
      if (uploadedByPatient != null) 'uploaded_by_patient': uploadedByPatient,
      if (createdByAccountId != null)
        'created_by_account_id': createdByAccountId,
      if (createdAt != null) 'created_at': createdAt,
      if (reviewStatus != null) 'review_status': reviewStatus,
      if (reviewedByStaffId != null) 'reviewed_by_staff_id': reviewedByStaffId,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (reviewNote != null) 'review_note': reviewNote,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicalRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String?>? authorStaffId,
    Value<String?>? appointmentId,
    Value<RecordType>? recordType,
    Value<String>? title,
    Value<String?>? body,
    Value<DateTime>? occurredAt,
    Value<String?>? sourceFacility,
    Value<ReferralUrgency?>? referralUrgency,
    Value<String?>? attachmentPath,
    Value<String?>? extractedText,
    Value<bool>? uploadedByPatient,
    Value<String?>? createdByAccountId,
    Value<DateTime>? createdAt,
    Value<ImportReviewStatus>? reviewStatus,
    Value<String?>? reviewedByStaffId,
    Value<DateTime?>? reviewedAt,
    Value<String?>? reviewNote,
    Value<int>? rowid,
  }) {
    return MedicalRecordsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      authorStaffId: authorStaffId ?? this.authorStaffId,
      appointmentId: appointmentId ?? this.appointmentId,
      recordType: recordType ?? this.recordType,
      title: title ?? this.title,
      body: body ?? this.body,
      occurredAt: occurredAt ?? this.occurredAt,
      sourceFacility: sourceFacility ?? this.sourceFacility,
      referralUrgency: referralUrgency ?? this.referralUrgency,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      extractedText: extractedText ?? this.extractedText,
      uploadedByPatient: uploadedByPatient ?? this.uploadedByPatient,
      createdByAccountId: createdByAccountId ?? this.createdByAccountId,
      createdAt: createdAt ?? this.createdAt,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      reviewedByStaffId: reviewedByStaffId ?? this.reviewedByStaffId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNote: reviewNote ?? this.reviewNote,
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
    if (appointmentId.present) {
      map['appointment_id'] = Variable<String>(appointmentId.value);
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
    if (referralUrgency.present) {
      map['referral_urgency'] = Variable<String>(
        $MedicalRecordsTable.$converterreferralUrgencyn.toSql(
          referralUrgency.value,
        ),
      );
    }
    if (attachmentPath.present) {
      map['attachment_path'] = Variable<String>(attachmentPath.value);
    }
    if (extractedText.present) {
      map['extracted_text'] = Variable<String>(extractedText.value);
    }
    if (uploadedByPatient.present) {
      map['uploaded_by_patient'] = Variable<bool>(uploadedByPatient.value);
    }
    if (createdByAccountId.present) {
      map['created_by_account_id'] = Variable<String>(createdByAccountId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (reviewStatus.present) {
      map['review_status'] = Variable<String>(
        $MedicalRecordsTable.$converterreviewStatus.toSql(reviewStatus.value),
      );
    }
    if (reviewedByStaffId.present) {
      map['reviewed_by_staff_id'] = Variable<String>(reviewedByStaffId.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (reviewNote.present) {
      map['review_note'] = Variable<String>(reviewNote.value);
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
          ..write('appointmentId: $appointmentId, ')
          ..write('recordType: $recordType, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('sourceFacility: $sourceFacility, ')
          ..write('referralUrgency: $referralUrgency, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('extractedText: $extractedText, ')
          ..write('uploadedByPatient: $uploadedByPatient, ')
          ..write('createdByAccountId: $createdByAccountId, ')
          ..write('createdAt: $createdAt, ')
          ..write('reviewStatus: $reviewStatus, ')
          ..write('reviewedByStaffId: $reviewedByStaffId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('reviewNote: $reviewNote, ')
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
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _provenanceMeta = const VerificationMeta(
    'provenance',
  );
  @override
  late final GeneratedColumn<String> provenance = GeneratedColumn<String>(
    'provenance',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<VerificationStatus, String>
  verificationStatus =
      GeneratedColumn<String>(
        'verification_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('unverified'),
      ).withConverter<VerificationStatus>(
        $LabValuesTable.$converterverificationStatus,
      );
  static const VerificationMeta _verifiedByStaffIdMeta = const VerificationMeta(
    'verifiedByStaffId',
  );
  @override
  late final GeneratedColumn<String> verifiedByStaffId =
      GeneratedColumn<String>(
        'verified_by_staff_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES users (id) ON DELETE SET NULL',
        ),
      );
  static const VerificationMeta _verifiedAtMeta = const VerificationMeta(
    'verifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> verifiedAt = GeneratedColumn<DateTime>(
    'verified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
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
    source,
    provenance,
    verificationStatus,
    verifiedByStaffId,
    verifiedAt,
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
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('provenance')) {
      context.handle(
        _provenanceMeta,
        provenance.isAcceptableOrUnknown(data['provenance']!, _provenanceMeta),
      );
    }
    if (data.containsKey('verified_by_staff_id')) {
      context.handle(
        _verifiedByStaffIdMeta,
        verifiedByStaffId.isAcceptableOrUnknown(
          data['verified_by_staff_id']!,
          _verifiedByStaffIdMeta,
        ),
      );
    }
    if (data.containsKey('verified_at')) {
      context.handle(
        _verifiedAtMeta,
        verifiedAt.isAcceptableOrUnknown(data['verified_at']!, _verifiedAtMeta),
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
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      provenance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance'],
      ),
      verificationStatus: $LabValuesTable.$converterverificationStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}verification_status'],
        )!,
      ),
      verifiedByStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verified_by_staff_id'],
      ),
      verifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}verified_at'],
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
  static JsonTypeConverter2<VerificationStatus, String, String>
  $converterverificationStatus = const EnumNameConverter<VerificationStatus>(
    VerificationStatus.values,
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
  final String? source;
  final String? provenance;
  final VerificationStatus verificationStatus;
  final String? verifiedByStaffId;
  final DateTime? verifiedAt;
  const LabValueRow({
    required this.id,
    required this.recordId,
    required this.analyte,
    required this.value,
    this.unit,
    this.refLow,
    this.refHigh,
    required this.abnormalFlag,
    this.source,
    this.provenance,
    required this.verificationStatus,
    this.verifiedByStaffId,
    this.verifiedAt,
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
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || provenance != null) {
      map['provenance'] = Variable<String>(provenance);
    }
    {
      map['verification_status'] = Variable<String>(
        $LabValuesTable.$converterverificationStatus.toSql(verificationStatus),
      );
    }
    if (!nullToAbsent || verifiedByStaffId != null) {
      map['verified_by_staff_id'] = Variable<String>(verifiedByStaffId);
    }
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<DateTime>(verifiedAt);
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
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      provenance: provenance == null && nullToAbsent
          ? const Value.absent()
          : Value(provenance),
      verificationStatus: Value(verificationStatus),
      verifiedByStaffId: verifiedByStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedByStaffId),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
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
      source: serializer.fromJson<String?>(json['source']),
      provenance: serializer.fromJson<String?>(json['provenance']),
      verificationStatus: $LabValuesTable.$converterverificationStatus.fromJson(
        serializer.fromJson<String>(json['verificationStatus']),
      ),
      verifiedByStaffId: serializer.fromJson<String?>(
        json['verifiedByStaffId'],
      ),
      verifiedAt: serializer.fromJson<DateTime?>(json['verifiedAt']),
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
      'source': serializer.toJson<String?>(source),
      'provenance': serializer.toJson<String?>(provenance),
      'verificationStatus': serializer.toJson<String>(
        $LabValuesTable.$converterverificationStatus.toJson(verificationStatus),
      ),
      'verifiedByStaffId': serializer.toJson<String?>(verifiedByStaffId),
      'verifiedAt': serializer.toJson<DateTime?>(verifiedAt),
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
    Value<String?> source = const Value.absent(),
    Value<String?> provenance = const Value.absent(),
    VerificationStatus? verificationStatus,
    Value<String?> verifiedByStaffId = const Value.absent(),
    Value<DateTime?> verifiedAt = const Value.absent(),
  }) => LabValueRow(
    id: id ?? this.id,
    recordId: recordId ?? this.recordId,
    analyte: analyte ?? this.analyte,
    value: value ?? this.value,
    unit: unit.present ? unit.value : this.unit,
    refLow: refLow.present ? refLow.value : this.refLow,
    refHigh: refHigh.present ? refHigh.value : this.refHigh,
    abnormalFlag: abnormalFlag ?? this.abnormalFlag,
    source: source.present ? source.value : this.source,
    provenance: provenance.present ? provenance.value : this.provenance,
    verificationStatus: verificationStatus ?? this.verificationStatus,
    verifiedByStaffId: verifiedByStaffId.present
        ? verifiedByStaffId.value
        : this.verifiedByStaffId,
    verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
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
      source: data.source.present ? data.source.value : this.source,
      provenance: data.provenance.present
          ? data.provenance.value
          : this.provenance,
      verificationStatus: data.verificationStatus.present
          ? data.verificationStatus.value
          : this.verificationStatus,
      verifiedByStaffId: data.verifiedByStaffId.present
          ? data.verifiedByStaffId.value
          : this.verifiedByStaffId,
      verifiedAt: data.verifiedAt.present
          ? data.verifiedAt.value
          : this.verifiedAt,
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
          ..write('abnormalFlag: $abnormalFlag, ')
          ..write('source: $source, ')
          ..write('provenance: $provenance, ')
          ..write('verificationStatus: $verificationStatus, ')
          ..write('verifiedByStaffId: $verifiedByStaffId, ')
          ..write('verifiedAt: $verifiedAt')
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
    source,
    provenance,
    verificationStatus,
    verifiedByStaffId,
    verifiedAt,
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
          other.abnormalFlag == this.abnormalFlag &&
          other.source == this.source &&
          other.provenance == this.provenance &&
          other.verificationStatus == this.verificationStatus &&
          other.verifiedByStaffId == this.verifiedByStaffId &&
          other.verifiedAt == this.verifiedAt);
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
  final Value<String?> source;
  final Value<String?> provenance;
  final Value<VerificationStatus> verificationStatus;
  final Value<String?> verifiedByStaffId;
  final Value<DateTime?> verifiedAt;
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
    this.source = const Value.absent(),
    this.provenance = const Value.absent(),
    this.verificationStatus = const Value.absent(),
    this.verifiedByStaffId = const Value.absent(),
    this.verifiedAt = const Value.absent(),
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
    this.source = const Value.absent(),
    this.provenance = const Value.absent(),
    this.verificationStatus = const Value.absent(),
    this.verifiedByStaffId = const Value.absent(),
    this.verifiedAt = const Value.absent(),
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
    Expression<String>? source,
    Expression<String>? provenance,
    Expression<String>? verificationStatus,
    Expression<String>? verifiedByStaffId,
    Expression<DateTime>? verifiedAt,
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
      if (source != null) 'source': source,
      if (provenance != null) 'provenance': provenance,
      if (verificationStatus != null) 'verification_status': verificationStatus,
      if (verifiedByStaffId != null) 'verified_by_staff_id': verifiedByStaffId,
      if (verifiedAt != null) 'verified_at': verifiedAt,
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
    Value<String?>? source,
    Value<String?>? provenance,
    Value<VerificationStatus>? verificationStatus,
    Value<String?>? verifiedByStaffId,
    Value<DateTime?>? verifiedAt,
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
      source: source ?? this.source,
      provenance: provenance ?? this.provenance,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedByStaffId: verifiedByStaffId ?? this.verifiedByStaffId,
      verifiedAt: verifiedAt ?? this.verifiedAt,
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
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (provenance.present) {
      map['provenance'] = Variable<String>(provenance.value);
    }
    if (verificationStatus.present) {
      map['verification_status'] = Variable<String>(
        $LabValuesTable.$converterverificationStatus.toSql(
          verificationStatus.value,
        ),
      );
    }
    if (verifiedByStaffId.present) {
      map['verified_by_staff_id'] = Variable<String>(verifiedByStaffId.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<DateTime>(verifiedAt.value);
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
          ..write('source: $source, ')
          ..write('provenance: $provenance, ')
          ..write('verificationStatus: $verificationStatus, ')
          ..write('verifiedByStaffId: $verifiedByStaffId, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ResultReviewsTable extends ResultReviews
    with TableInfo<$ResultReviewsTable, ResultReviewRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResultReviewsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _ownerStaffIdMeta = const VerificationMeta(
    'ownerStaffId',
  );
  @override
  late final GeneratedColumn<String> ownerStaffId = GeneratedColumn<String>(
    'owner_staff_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _coverageStaffIdMeta = const VerificationMeta(
    'coverageStaffId',
  );
  @override
  late final GeneratedColumn<String> coverageStaffId = GeneratedColumn<String>(
    'coverage_staff_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WorkPriority, String> priority =
      GeneratedColumn<String>(
        'priority',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('routine'),
      ).withConverter<WorkPriority>($ResultReviewsTable.$converterpriority);
  @override
  late final GeneratedColumnWithTypeConverter<ResultReviewStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unassigned'),
  ).withConverter<ResultReviewStatus>($ResultReviewsTable.$converterstatus);
  static const VerificationMeta _escalationNoteMeta = const VerificationMeta(
    'escalationNote',
  );
  @override
  late final GeneratedColumn<String> escalationNote = GeneratedColumn<String>(
    'escalation_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedByStaffIdMeta = const VerificationMeta(
    'resolvedByStaffId',
  );
  @override
  late final GeneratedColumn<String> resolvedByStaffId =
      GeneratedColumn<String>(
        'resolved_by_staff_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES users (id) ON DELETE SET NULL',
        ),
      );
  static const VerificationMeta _resolutionNoteMeta = const VerificationMeta(
    'resolutionNote',
  );
  @override
  late final GeneratedColumn<String> resolutionNote = GeneratedColumn<String>(
    'resolution_note',
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordId,
    ownerStaffId,
    coverageStaffId,
    dueAt,
    priority,
    status,
    escalationNote,
    resolvedAt,
    resolvedByStaffId,
    resolutionNote,
    createdAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'result_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<ResultReviewRow> instance, {
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
    if (data.containsKey('owner_staff_id')) {
      context.handle(
        _ownerStaffIdMeta,
        ownerStaffId.isAcceptableOrUnknown(
          data['owner_staff_id']!,
          _ownerStaffIdMeta,
        ),
      );
    }
    if (data.containsKey('coverage_staff_id')) {
      context.handle(
        _coverageStaffIdMeta,
        coverageStaffId.isAcceptableOrUnknown(
          data['coverage_staff_id']!,
          _coverageStaffIdMeta,
        ),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('escalation_note')) {
      context.handle(
        _escalationNoteMeta,
        escalationNote.isAcceptableOrUnknown(
          data['escalation_note']!,
          _escalationNoteMeta,
        ),
      );
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    if (data.containsKey('resolved_by_staff_id')) {
      context.handle(
        _resolvedByStaffIdMeta,
        resolvedByStaffId.isAcceptableOrUnknown(
          data['resolved_by_staff_id']!,
          _resolvedByStaffIdMeta,
        ),
      );
    }
    if (data.containsKey('resolution_note')) {
      context.handle(
        _resolutionNoteMeta,
        resolutionNote.isAcceptableOrUnknown(
          data['resolution_note']!,
          _resolutionNoteMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ResultReviewRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResultReviewRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      ownerStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_staff_id'],
      ),
      coverageStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coverage_staff_id'],
      ),
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      )!,
      priority: $ResultReviewsTable.$converterpriority.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}priority'],
        )!,
      ),
      status: $ResultReviewsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      escalationNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}escalation_note'],
      ),
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
      resolvedByStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolved_by_staff_id'],
      ),
      resolutionNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution_note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $ResultReviewsTable createAlias(String alias) {
    return $ResultReviewsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WorkPriority, String, String> $converterpriority =
      const EnumNameConverter<WorkPriority>(WorkPriority.values);
  static JsonTypeConverter2<ResultReviewStatus, String, String>
  $converterstatus = const EnumNameConverter<ResultReviewStatus>(
    ResultReviewStatus.values,
  );
}

class ResultReviewRow extends DataClass implements Insertable<ResultReviewRow> {
  final String id;
  final String recordId;
  final String? ownerStaffId;
  final String? coverageStaffId;
  final DateTime dueAt;
  final WorkPriority priority;
  final ResultReviewStatus status;
  final String? escalationNote;
  final DateTime? resolvedAt;
  final String? resolvedByStaffId;
  final String? resolutionNote;
  final DateTime createdAt;
  final int version;
  const ResultReviewRow({
    required this.id,
    required this.recordId,
    this.ownerStaffId,
    this.coverageStaffId,
    required this.dueAt,
    required this.priority,
    required this.status,
    this.escalationNote,
    this.resolvedAt,
    this.resolvedByStaffId,
    this.resolutionNote,
    required this.createdAt,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['record_id'] = Variable<String>(recordId);
    if (!nullToAbsent || ownerStaffId != null) {
      map['owner_staff_id'] = Variable<String>(ownerStaffId);
    }
    if (!nullToAbsent || coverageStaffId != null) {
      map['coverage_staff_id'] = Variable<String>(coverageStaffId);
    }
    map['due_at'] = Variable<DateTime>(dueAt);
    {
      map['priority'] = Variable<String>(
        $ResultReviewsTable.$converterpriority.toSql(priority),
      );
    }
    {
      map['status'] = Variable<String>(
        $ResultReviewsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || escalationNote != null) {
      map['escalation_note'] = Variable<String>(escalationNote);
    }
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    if (!nullToAbsent || resolvedByStaffId != null) {
      map['resolved_by_staff_id'] = Variable<String>(resolvedByStaffId);
    }
    if (!nullToAbsent || resolutionNote != null) {
      map['resolution_note'] = Variable<String>(resolutionNote);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['version'] = Variable<int>(version);
    return map;
  }

  ResultReviewsCompanion toCompanion(bool nullToAbsent) {
    return ResultReviewsCompanion(
      id: Value(id),
      recordId: Value(recordId),
      ownerStaffId: ownerStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerStaffId),
      coverageStaffId: coverageStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverageStaffId),
      dueAt: Value(dueAt),
      priority: Value(priority),
      status: Value(status),
      escalationNote: escalationNote == null && nullToAbsent
          ? const Value.absent()
          : Value(escalationNote),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
      resolvedByStaffId: resolvedByStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedByStaffId),
      resolutionNote: resolutionNote == null && nullToAbsent
          ? const Value.absent()
          : Value(resolutionNote),
      createdAt: Value(createdAt),
      version: Value(version),
    );
  }

  factory ResultReviewRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ResultReviewRow(
      id: serializer.fromJson<String>(json['id']),
      recordId: serializer.fromJson<String>(json['recordId']),
      ownerStaffId: serializer.fromJson<String?>(json['ownerStaffId']),
      coverageStaffId: serializer.fromJson<String?>(json['coverageStaffId']),
      dueAt: serializer.fromJson<DateTime>(json['dueAt']),
      priority: $ResultReviewsTable.$converterpriority.fromJson(
        serializer.fromJson<String>(json['priority']),
      ),
      status: $ResultReviewsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      escalationNote: serializer.fromJson<String?>(json['escalationNote']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
      resolvedByStaffId: serializer.fromJson<String?>(
        json['resolvedByStaffId'],
      ),
      resolutionNote: serializer.fromJson<String?>(json['resolutionNote']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recordId': serializer.toJson<String>(recordId),
      'ownerStaffId': serializer.toJson<String?>(ownerStaffId),
      'coverageStaffId': serializer.toJson<String?>(coverageStaffId),
      'dueAt': serializer.toJson<DateTime>(dueAt),
      'priority': serializer.toJson<String>(
        $ResultReviewsTable.$converterpriority.toJson(priority),
      ),
      'status': serializer.toJson<String>(
        $ResultReviewsTable.$converterstatus.toJson(status),
      ),
      'escalationNote': serializer.toJson<String?>(escalationNote),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
      'resolvedByStaffId': serializer.toJson<String?>(resolvedByStaffId),
      'resolutionNote': serializer.toJson<String?>(resolutionNote),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'version': serializer.toJson<int>(version),
    };
  }

  ResultReviewRow copyWith({
    String? id,
    String? recordId,
    Value<String?> ownerStaffId = const Value.absent(),
    Value<String?> coverageStaffId = const Value.absent(),
    DateTime? dueAt,
    WorkPriority? priority,
    ResultReviewStatus? status,
    Value<String?> escalationNote = const Value.absent(),
    Value<DateTime?> resolvedAt = const Value.absent(),
    Value<String?> resolvedByStaffId = const Value.absent(),
    Value<String?> resolutionNote = const Value.absent(),
    DateTime? createdAt,
    int? version,
  }) => ResultReviewRow(
    id: id ?? this.id,
    recordId: recordId ?? this.recordId,
    ownerStaffId: ownerStaffId.present ? ownerStaffId.value : this.ownerStaffId,
    coverageStaffId: coverageStaffId.present
        ? coverageStaffId.value
        : this.coverageStaffId,
    dueAt: dueAt ?? this.dueAt,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    escalationNote: escalationNote.present
        ? escalationNote.value
        : this.escalationNote,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
    resolvedByStaffId: resolvedByStaffId.present
        ? resolvedByStaffId.value
        : this.resolvedByStaffId,
    resolutionNote: resolutionNote.present
        ? resolutionNote.value
        : this.resolutionNote,
    createdAt: createdAt ?? this.createdAt,
    version: version ?? this.version,
  );
  ResultReviewRow copyWithCompanion(ResultReviewsCompanion data) {
    return ResultReviewRow(
      id: data.id.present ? data.id.value : this.id,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      ownerStaffId: data.ownerStaffId.present
          ? data.ownerStaffId.value
          : this.ownerStaffId,
      coverageStaffId: data.coverageStaffId.present
          ? data.coverageStaffId.value
          : this.coverageStaffId,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      escalationNote: data.escalationNote.present
          ? data.escalationNote.value
          : this.escalationNote,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      resolvedByStaffId: data.resolvedByStaffId.present
          ? data.resolvedByStaffId.value
          : this.resolvedByStaffId,
      resolutionNote: data.resolutionNote.present
          ? data.resolutionNote.value
          : this.resolutionNote,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ResultReviewRow(')
          ..write('id: $id, ')
          ..write('recordId: $recordId, ')
          ..write('ownerStaffId: $ownerStaffId, ')
          ..write('coverageStaffId: $coverageStaffId, ')
          ..write('dueAt: $dueAt, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('escalationNote: $escalationNote, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('resolvedByStaffId: $resolvedByStaffId, ')
          ..write('resolutionNote: $resolutionNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recordId,
    ownerStaffId,
    coverageStaffId,
    dueAt,
    priority,
    status,
    escalationNote,
    resolvedAt,
    resolvedByStaffId,
    resolutionNote,
    createdAt,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResultReviewRow &&
          other.id == this.id &&
          other.recordId == this.recordId &&
          other.ownerStaffId == this.ownerStaffId &&
          other.coverageStaffId == this.coverageStaffId &&
          other.dueAt == this.dueAt &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.escalationNote == this.escalationNote &&
          other.resolvedAt == this.resolvedAt &&
          other.resolvedByStaffId == this.resolvedByStaffId &&
          other.resolutionNote == this.resolutionNote &&
          other.createdAt == this.createdAt &&
          other.version == this.version);
}

class ResultReviewsCompanion extends UpdateCompanion<ResultReviewRow> {
  final Value<String> id;
  final Value<String> recordId;
  final Value<String?> ownerStaffId;
  final Value<String?> coverageStaffId;
  final Value<DateTime> dueAt;
  final Value<WorkPriority> priority;
  final Value<ResultReviewStatus> status;
  final Value<String?> escalationNote;
  final Value<DateTime?> resolvedAt;
  final Value<String?> resolvedByStaffId;
  final Value<String?> resolutionNote;
  final Value<DateTime> createdAt;
  final Value<int> version;
  final Value<int> rowid;
  const ResultReviewsCompanion({
    this.id = const Value.absent(),
    this.recordId = const Value.absent(),
    this.ownerStaffId = const Value.absent(),
    this.coverageStaffId = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.escalationNote = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.resolvedByStaffId = const Value.absent(),
    this.resolutionNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResultReviewsCompanion.insert({
    required String id,
    required String recordId,
    this.ownerStaffId = const Value.absent(),
    this.coverageStaffId = const Value.absent(),
    required DateTime dueAt,
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.escalationNote = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.resolvedByStaffId = const Value.absent(),
    this.resolutionNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recordId = Value(recordId),
       dueAt = Value(dueAt);
  static Insertable<ResultReviewRow> custom({
    Expression<String>? id,
    Expression<String>? recordId,
    Expression<String>? ownerStaffId,
    Expression<String>? coverageStaffId,
    Expression<DateTime>? dueAt,
    Expression<String>? priority,
    Expression<String>? status,
    Expression<String>? escalationNote,
    Expression<DateTime>? resolvedAt,
    Expression<String>? resolvedByStaffId,
    Expression<String>? resolutionNote,
    Expression<DateTime>? createdAt,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordId != null) 'record_id': recordId,
      if (ownerStaffId != null) 'owner_staff_id': ownerStaffId,
      if (coverageStaffId != null) 'coverage_staff_id': coverageStaffId,
      if (dueAt != null) 'due_at': dueAt,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (escalationNote != null) 'escalation_note': escalationNote,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (resolvedByStaffId != null) 'resolved_by_staff_id': resolvedByStaffId,
      if (resolutionNote != null) 'resolution_note': resolutionNote,
      if (createdAt != null) 'created_at': createdAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResultReviewsCompanion copyWith({
    Value<String>? id,
    Value<String>? recordId,
    Value<String?>? ownerStaffId,
    Value<String?>? coverageStaffId,
    Value<DateTime>? dueAt,
    Value<WorkPriority>? priority,
    Value<ResultReviewStatus>? status,
    Value<String?>? escalationNote,
    Value<DateTime?>? resolvedAt,
    Value<String?>? resolvedByStaffId,
    Value<String?>? resolutionNote,
    Value<DateTime>? createdAt,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return ResultReviewsCompanion(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      ownerStaffId: ownerStaffId ?? this.ownerStaffId,
      coverageStaffId: coverageStaffId ?? this.coverageStaffId,
      dueAt: dueAt ?? this.dueAt,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      escalationNote: escalationNote ?? this.escalationNote,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedByStaffId: resolvedByStaffId ?? this.resolvedByStaffId,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      createdAt: createdAt ?? this.createdAt,
      version: version ?? this.version,
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
    if (ownerStaffId.present) {
      map['owner_staff_id'] = Variable<String>(ownerStaffId.value);
    }
    if (coverageStaffId.present) {
      map['coverage_staff_id'] = Variable<String>(coverageStaffId.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(
        $ResultReviewsTable.$converterpriority.toSql(priority.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ResultReviewsTable.$converterstatus.toSql(status.value),
      );
    }
    if (escalationNote.present) {
      map['escalation_note'] = Variable<String>(escalationNote.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (resolvedByStaffId.present) {
      map['resolved_by_staff_id'] = Variable<String>(resolvedByStaffId.value);
    }
    if (resolutionNote.present) {
      map['resolution_note'] = Variable<String>(resolutionNote.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResultReviewsCompanion(')
          ..write('id: $id, ')
          ..write('recordId: $recordId, ')
          ..write('ownerStaffId: $ownerStaffId, ')
          ..write('coverageStaffId: $coverageStaffId, ')
          ..write('dueAt: $dueAt, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('escalationNote: $escalationNote, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('resolvedByStaffId: $resolvedByStaffId, ')
          ..write('resolutionNote: $resolutionNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('version: $version, ')
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
  static const VerificationMeta _appointmentIdMeta = const VerificationMeta(
    'appointmentId',
  );
  @override
  late final GeneratedColumn<String> appointmentId = GeneratedColumn<String>(
    'appointment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES appointments (id) ON DELETE SET NULL',
    ),
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
    appointmentId,
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
    if (data.containsKey('appointment_id')) {
      context.handle(
        _appointmentIdMeta,
        appointmentId.isAcceptableOrUnknown(
          data['appointment_id']!,
          _appointmentIdMeta,
        ),
      );
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
      appointmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appointment_id'],
      ),
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
  final String? appointmentId;
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
    this.appointmentId,
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
    if (!nullToAbsent || appointmentId != null) {
      map['appointment_id'] = Variable<String>(appointmentId);
    }
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
      appointmentId: appointmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(appointmentId),
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
      appointmentId: serializer.fromJson<String?>(json['appointmentId']),
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
      'appointmentId': serializer.toJson<String?>(appointmentId),
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
    Value<String?> appointmentId = const Value.absent(),
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
    appointmentId: appointmentId.present
        ? appointmentId.value
        : this.appointmentId,
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
      appointmentId: data.appointmentId.present
          ? data.appointmentId.value
          : this.appointmentId,
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
          ..write('appointmentId: $appointmentId, ')
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
    appointmentId,
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
          other.appointmentId == this.appointmentId &&
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
  final Value<String?> appointmentId;
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
    this.appointmentId = const Value.absent(),
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
    this.appointmentId = const Value.absent(),
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
    Expression<String>? appointmentId,
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
      if (appointmentId != null) 'appointment_id': appointmentId,
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
    Value<String?>? appointmentId,
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
      appointmentId: appointmentId ?? this.appointmentId,
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
    if (appointmentId.present) {
      map['appointment_id'] = Variable<String>(appointmentId.value);
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
          ..write('appointmentId: $appointmentId, ')
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
  static const VerificationMeta _appointmentIdMeta = const VerificationMeta(
    'appointmentId',
  );
  @override
  late final GeneratedColumn<String> appointmentId = GeneratedColumn<String>(
    'appointment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES appointments (id) ON DELETE SET NULL',
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
    appointmentId,
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
    if (data.containsKey('appointment_id')) {
      context.handle(
        _appointmentIdMeta,
        appointmentId.isAcceptableOrUnknown(
          data['appointment_id']!,
          _appointmentIdMeta,
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
      appointmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appointment_id'],
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

  /// The visit it was prescribed in, if any.
  final String? appointmentId;
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
    this.appointmentId,
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
    if (!nullToAbsent || appointmentId != null) {
      map['appointment_id'] = Variable<String>(appointmentId);
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
      appointmentId: appointmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(appointmentId),
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
      appointmentId: serializer.fromJson<String?>(json['appointmentId']),
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
      'appointmentId': serializer.toJson<String?>(appointmentId),
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
    Value<String?> appointmentId = const Value.absent(),
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
    appointmentId: appointmentId.present
        ? appointmentId.value
        : this.appointmentId,
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
      appointmentId: data.appointmentId.present
          ? data.appointmentId.value
          : this.appointmentId,
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
          ..write('appointmentId: $appointmentId, ')
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
    appointmentId,
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
          other.appointmentId == this.appointmentId &&
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
  final Value<String?> appointmentId;
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
    this.appointmentId = const Value.absent(),
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
    this.appointmentId = const Value.absent(),
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
    Expression<String>? appointmentId,
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
      if (appointmentId != null) 'appointment_id': appointmentId,
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
    Value<String?>? appointmentId,
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
      appointmentId: appointmentId ?? this.appointmentId,
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
    if (appointmentId.present) {
      map['appointment_id'] = Variable<String>(appointmentId.value);
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
          ..write('appointmentId: $appointmentId, ')
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

class $EncounterDraftsTable extends EncounterDrafts
    with TableInfo<$EncounterDraftsTable, EncounterDraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EncounterDraftsTable(this.attachedDatabase, [this._alias]);
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
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _authorStaffIdMeta = const VerificationMeta(
    'authorStaffId',
  );
  @override
  late final GeneratedColumn<String> authorStaffId = GeneratedColumn<String>(
    'author_staff_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _medicationsJsonMeta = const VerificationMeta(
    'medicationsJson',
  );
  @override
  late final GeneratedColumn<String> medicationsJson = GeneratedColumn<String>(
    'medications_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _referralRequestedMeta = const VerificationMeta(
    'referralRequested',
  );
  @override
  late final GeneratedColumn<bool> referralRequested = GeneratedColumn<bool>(
    'referral_requested',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("referral_requested" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
    appointmentId,
    patientId,
    authorStaffId,
    note,
    medicationsJson,
    referralRequested,
    version,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'encounter_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<EncounterDraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    } else if (isInserting) {
      context.missing(_authorStaffIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('medications_json')) {
      context.handle(
        _medicationsJsonMeta,
        medicationsJson.isAcceptableOrUnknown(
          data['medications_json']!,
          _medicationsJsonMeta,
        ),
      );
    }
    if (data.containsKey('referral_requested')) {
      context.handle(
        _referralRequestedMeta,
        referralRequested.isAcceptableOrUnknown(
          data['referral_requested']!,
          _referralRequestedMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
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
  Set<GeneratedColumn> get $primaryKey => {appointmentId};
  @override
  EncounterDraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EncounterDraftRow(
      appointmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appointment_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      authorStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_staff_id'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      medicationsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medications_json'],
      )!,
      referralRequested: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}referral_requested'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EncounterDraftsTable createAlias(String alias) {
    return $EncounterDraftsTable(attachedDatabase, alias);
  }
}

class EncounterDraftRow extends DataClass
    implements Insertable<EncounterDraftRow> {
  final String appointmentId;
  final String patientId;
  final String authorStaffId;
  final String note;
  final String medicationsJson;
  final bool referralRequested;
  final int version;
  final DateTime updatedAt;
  const EncounterDraftRow({
    required this.appointmentId,
    required this.patientId,
    required this.authorStaffId,
    required this.note,
    required this.medicationsJson,
    required this.referralRequested,
    required this.version,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['appointment_id'] = Variable<String>(appointmentId);
    map['patient_id'] = Variable<String>(patientId);
    map['author_staff_id'] = Variable<String>(authorStaffId);
    map['note'] = Variable<String>(note);
    map['medications_json'] = Variable<String>(medicationsJson);
    map['referral_requested'] = Variable<bool>(referralRequested);
    map['version'] = Variable<int>(version);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EncounterDraftsCompanion toCompanion(bool nullToAbsent) {
    return EncounterDraftsCompanion(
      appointmentId: Value(appointmentId),
      patientId: Value(patientId),
      authorStaffId: Value(authorStaffId),
      note: Value(note),
      medicationsJson: Value(medicationsJson),
      referralRequested: Value(referralRequested),
      version: Value(version),
      updatedAt: Value(updatedAt),
    );
  }

  factory EncounterDraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EncounterDraftRow(
      appointmentId: serializer.fromJson<String>(json['appointmentId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      authorStaffId: serializer.fromJson<String>(json['authorStaffId']),
      note: serializer.fromJson<String>(json['note']),
      medicationsJson: serializer.fromJson<String>(json['medicationsJson']),
      referralRequested: serializer.fromJson<bool>(json['referralRequested']),
      version: serializer.fromJson<int>(json['version']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'appointmentId': serializer.toJson<String>(appointmentId),
      'patientId': serializer.toJson<String>(patientId),
      'authorStaffId': serializer.toJson<String>(authorStaffId),
      'note': serializer.toJson<String>(note),
      'medicationsJson': serializer.toJson<String>(medicationsJson),
      'referralRequested': serializer.toJson<bool>(referralRequested),
      'version': serializer.toJson<int>(version),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EncounterDraftRow copyWith({
    String? appointmentId,
    String? patientId,
    String? authorStaffId,
    String? note,
    String? medicationsJson,
    bool? referralRequested,
    int? version,
    DateTime? updatedAt,
  }) => EncounterDraftRow(
    appointmentId: appointmentId ?? this.appointmentId,
    patientId: patientId ?? this.patientId,
    authorStaffId: authorStaffId ?? this.authorStaffId,
    note: note ?? this.note,
    medicationsJson: medicationsJson ?? this.medicationsJson,
    referralRequested: referralRequested ?? this.referralRequested,
    version: version ?? this.version,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EncounterDraftRow copyWithCompanion(EncounterDraftsCompanion data) {
    return EncounterDraftRow(
      appointmentId: data.appointmentId.present
          ? data.appointmentId.value
          : this.appointmentId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      authorStaffId: data.authorStaffId.present
          ? data.authorStaffId.value
          : this.authorStaffId,
      note: data.note.present ? data.note.value : this.note,
      medicationsJson: data.medicationsJson.present
          ? data.medicationsJson.value
          : this.medicationsJson,
      referralRequested: data.referralRequested.present
          ? data.referralRequested.value
          : this.referralRequested,
      version: data.version.present ? data.version.value : this.version,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EncounterDraftRow(')
          ..write('appointmentId: $appointmentId, ')
          ..write('patientId: $patientId, ')
          ..write('authorStaffId: $authorStaffId, ')
          ..write('note: $note, ')
          ..write('medicationsJson: $medicationsJson, ')
          ..write('referralRequested: $referralRequested, ')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    appointmentId,
    patientId,
    authorStaffId,
    note,
    medicationsJson,
    referralRequested,
    version,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncounterDraftRow &&
          other.appointmentId == this.appointmentId &&
          other.patientId == this.patientId &&
          other.authorStaffId == this.authorStaffId &&
          other.note == this.note &&
          other.medicationsJson == this.medicationsJson &&
          other.referralRequested == this.referralRequested &&
          other.version == this.version &&
          other.updatedAt == this.updatedAt);
}

class EncounterDraftsCompanion extends UpdateCompanion<EncounterDraftRow> {
  final Value<String> appointmentId;
  final Value<String> patientId;
  final Value<String> authorStaffId;
  final Value<String> note;
  final Value<String> medicationsJson;
  final Value<bool> referralRequested;
  final Value<int> version;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EncounterDraftsCompanion({
    this.appointmentId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.authorStaffId = const Value.absent(),
    this.note = const Value.absent(),
    this.medicationsJson = const Value.absent(),
    this.referralRequested = const Value.absent(),
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EncounterDraftsCompanion.insert({
    required String appointmentId,
    required String patientId,
    required String authorStaffId,
    this.note = const Value.absent(),
    this.medicationsJson = const Value.absent(),
    this.referralRequested = const Value.absent(),
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : appointmentId = Value(appointmentId),
       patientId = Value(patientId),
       authorStaffId = Value(authorStaffId);
  static Insertable<EncounterDraftRow> custom({
    Expression<String>? appointmentId,
    Expression<String>? patientId,
    Expression<String>? authorStaffId,
    Expression<String>? note,
    Expression<String>? medicationsJson,
    Expression<bool>? referralRequested,
    Expression<int>? version,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (patientId != null) 'patient_id': patientId,
      if (authorStaffId != null) 'author_staff_id': authorStaffId,
      if (note != null) 'note': note,
      if (medicationsJson != null) 'medications_json': medicationsJson,
      if (referralRequested != null) 'referral_requested': referralRequested,
      if (version != null) 'version': version,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EncounterDraftsCompanion copyWith({
    Value<String>? appointmentId,
    Value<String>? patientId,
    Value<String>? authorStaffId,
    Value<String>? note,
    Value<String>? medicationsJson,
    Value<bool>? referralRequested,
    Value<int>? version,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EncounterDraftsCompanion(
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      authorStaffId: authorStaffId ?? this.authorStaffId,
      note: note ?? this.note,
      medicationsJson: medicationsJson ?? this.medicationsJson,
      referralRequested: referralRequested ?? this.referralRequested,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (appointmentId.present) {
      map['appointment_id'] = Variable<String>(appointmentId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (authorStaffId.present) {
      map['author_staff_id'] = Variable<String>(authorStaffId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (medicationsJson.present) {
      map['medications_json'] = Variable<String>(medicationsJson.value);
    }
    if (referralRequested.present) {
      map['referral_requested'] = Variable<bool>(referralRequested.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
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
    return (StringBuffer('EncounterDraftsCompanion(')
          ..write('appointmentId: $appointmentId, ')
          ..write('patientId: $patientId, ')
          ..write('authorStaffId: $authorStaffId, ')
          ..write('note: $note, ')
          ..write('medicationsJson: $medicationsJson, ')
          ..write('referralRequested: $referralRequested, ')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SignedNotesTable extends SignedNotes
    with TableInfo<$SignedNotesTable, SignedNoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignedNotesTable(this.attachedDatabase, [this._alias]);
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
      'UNIQUE REFERENCES appointments (id)',
    ),
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
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _authorStaffIdMeta = const VerificationMeta(
    'authorStaffId',
  );
  @override
  late final GeneratedColumn<String> authorStaffId = GeneratedColumn<String>(
    'author_staff_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signedAtMeta = const VerificationMeta(
    'signedAt',
  );
  @override
  late final GeneratedColumn<DateTime> signedAt = GeneratedColumn<DateTime>(
    'signed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    appointmentId,
    patientId,
    authorStaffId,
    body,
    signedAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signed_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignedNoteRow> instance, {
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
    } else if (isInserting) {
      context.missing(_authorStaffIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('signed_at')) {
      context.handle(
        _signedAtMeta,
        signedAt.isAcceptableOrUnknown(data['signed_at']!, _signedAtMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SignedNoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignedNoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      appointmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appointment_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      authorStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_staff_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      signedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}signed_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $SignedNotesTable createAlias(String alias) {
    return $SignedNotesTable(attachedDatabase, alias);
  }
}

class SignedNoteRow extends DataClass implements Insertable<SignedNoteRow> {
  final String id;
  final String appointmentId;
  final String patientId;
  final String authorStaffId;
  final String body;
  final DateTime signedAt;
  final int version;
  const SignedNoteRow({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.authorStaffId,
    required this.body,
    required this.signedAt,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['appointment_id'] = Variable<String>(appointmentId);
    map['patient_id'] = Variable<String>(patientId);
    map['author_staff_id'] = Variable<String>(authorStaffId);
    map['body'] = Variable<String>(body);
    map['signed_at'] = Variable<DateTime>(signedAt);
    map['version'] = Variable<int>(version);
    return map;
  }

  SignedNotesCompanion toCompanion(bool nullToAbsent) {
    return SignedNotesCompanion(
      id: Value(id),
      appointmentId: Value(appointmentId),
      patientId: Value(patientId),
      authorStaffId: Value(authorStaffId),
      body: Value(body),
      signedAt: Value(signedAt),
      version: Value(version),
    );
  }

  factory SignedNoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignedNoteRow(
      id: serializer.fromJson<String>(json['id']),
      appointmentId: serializer.fromJson<String>(json['appointmentId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      authorStaffId: serializer.fromJson<String>(json['authorStaffId']),
      body: serializer.fromJson<String>(json['body']),
      signedAt: serializer.fromJson<DateTime>(json['signedAt']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'appointmentId': serializer.toJson<String>(appointmentId),
      'patientId': serializer.toJson<String>(patientId),
      'authorStaffId': serializer.toJson<String>(authorStaffId),
      'body': serializer.toJson<String>(body),
      'signedAt': serializer.toJson<DateTime>(signedAt),
      'version': serializer.toJson<int>(version),
    };
  }

  SignedNoteRow copyWith({
    String? id,
    String? appointmentId,
    String? patientId,
    String? authorStaffId,
    String? body,
    DateTime? signedAt,
    int? version,
  }) => SignedNoteRow(
    id: id ?? this.id,
    appointmentId: appointmentId ?? this.appointmentId,
    patientId: patientId ?? this.patientId,
    authorStaffId: authorStaffId ?? this.authorStaffId,
    body: body ?? this.body,
    signedAt: signedAt ?? this.signedAt,
    version: version ?? this.version,
  );
  SignedNoteRow copyWithCompanion(SignedNotesCompanion data) {
    return SignedNoteRow(
      id: data.id.present ? data.id.value : this.id,
      appointmentId: data.appointmentId.present
          ? data.appointmentId.value
          : this.appointmentId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      authorStaffId: data.authorStaffId.present
          ? data.authorStaffId.value
          : this.authorStaffId,
      body: data.body.present ? data.body.value : this.body,
      signedAt: data.signedAt.present ? data.signedAt.value : this.signedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignedNoteRow(')
          ..write('id: $id, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('patientId: $patientId, ')
          ..write('authorStaffId: $authorStaffId, ')
          ..write('body: $body, ')
          ..write('signedAt: $signedAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    appointmentId,
    patientId,
    authorStaffId,
    body,
    signedAt,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignedNoteRow &&
          other.id == this.id &&
          other.appointmentId == this.appointmentId &&
          other.patientId == this.patientId &&
          other.authorStaffId == this.authorStaffId &&
          other.body == this.body &&
          other.signedAt == this.signedAt &&
          other.version == this.version);
}

class SignedNotesCompanion extends UpdateCompanion<SignedNoteRow> {
  final Value<String> id;
  final Value<String> appointmentId;
  final Value<String> patientId;
  final Value<String> authorStaffId;
  final Value<String> body;
  final Value<DateTime> signedAt;
  final Value<int> version;
  final Value<int> rowid;
  const SignedNotesCompanion({
    this.id = const Value.absent(),
    this.appointmentId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.authorStaffId = const Value.absent(),
    this.body = const Value.absent(),
    this.signedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SignedNotesCompanion.insert({
    required String id,
    required String appointmentId,
    required String patientId,
    required String authorStaffId,
    required String body,
    this.signedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       appointmentId = Value(appointmentId),
       patientId = Value(patientId),
       authorStaffId = Value(authorStaffId),
       body = Value(body);
  static Insertable<SignedNoteRow> custom({
    Expression<String>? id,
    Expression<String>? appointmentId,
    Expression<String>? patientId,
    Expression<String>? authorStaffId,
    Expression<String>? body,
    Expression<DateTime>? signedAt,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (patientId != null) 'patient_id': patientId,
      if (authorStaffId != null) 'author_staff_id': authorStaffId,
      if (body != null) 'body': body,
      if (signedAt != null) 'signed_at': signedAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SignedNotesCompanion copyWith({
    Value<String>? id,
    Value<String>? appointmentId,
    Value<String>? patientId,
    Value<String>? authorStaffId,
    Value<String>? body,
    Value<DateTime>? signedAt,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return SignedNotesCompanion(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      authorStaffId: authorStaffId ?? this.authorStaffId,
      body: body ?? this.body,
      signedAt: signedAt ?? this.signedAt,
      version: version ?? this.version,
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
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (authorStaffId.present) {
      map['author_staff_id'] = Variable<String>(authorStaffId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (signedAt.present) {
      map['signed_at'] = Variable<DateTime>(signedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignedNotesCompanion(')
          ..write('id: $id, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('patientId: $patientId, ')
          ..write('authorStaffId: $authorStaffId, ')
          ..write('body: $body, ')
          ..write('signedAt: $signedAt, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SignedNoteAmendmentsTable extends SignedNoteAmendments
    with TableInfo<$SignedNoteAmendmentsTable, SignedNoteAmendmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignedNoteAmendmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signedNoteIdMeta = const VerificationMeta(
    'signedNoteId',
  );
  @override
  late final GeneratedColumn<String> signedNoteId = GeneratedColumn<String>(
    'signed_note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES signed_notes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _authorStaffIdMeta = const VerificationMeta(
    'authorStaffId',
  );
  @override
  late final GeneratedColumn<String> authorStaffId = GeneratedColumn<String>(
    'author_staff_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amendedAtMeta = const VerificationMeta(
    'amendedAt',
  );
  @override
  late final GeneratedColumn<DateTime> amendedAt = GeneratedColumn<DateTime>(
    'amended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    signedNoteId,
    authorStaffId,
    body,
    amendedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signed_note_amendments';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignedNoteAmendmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('signed_note_id')) {
      context.handle(
        _signedNoteIdMeta,
        signedNoteId.isAcceptableOrUnknown(
          data['signed_note_id']!,
          _signedNoteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_signedNoteIdMeta);
    }
    if (data.containsKey('author_staff_id')) {
      context.handle(
        _authorStaffIdMeta,
        authorStaffId.isAcceptableOrUnknown(
          data['author_staff_id']!,
          _authorStaffIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authorStaffIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('amended_at')) {
      context.handle(
        _amendedAtMeta,
        amendedAt.isAcceptableOrUnknown(data['amended_at']!, _amendedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SignedNoteAmendmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignedNoteAmendmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      signedNoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signed_note_id'],
      )!,
      authorStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_staff_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      amendedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}amended_at'],
      )!,
    );
  }

  @override
  $SignedNoteAmendmentsTable createAlias(String alias) {
    return $SignedNoteAmendmentsTable(attachedDatabase, alias);
  }
}

class SignedNoteAmendmentRow extends DataClass
    implements Insertable<SignedNoteAmendmentRow> {
  final String id;
  final String signedNoteId;
  final String authorStaffId;
  final String body;
  final DateTime amendedAt;
  const SignedNoteAmendmentRow({
    required this.id,
    required this.signedNoteId,
    required this.authorStaffId,
    required this.body,
    required this.amendedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['signed_note_id'] = Variable<String>(signedNoteId);
    map['author_staff_id'] = Variable<String>(authorStaffId);
    map['body'] = Variable<String>(body);
    map['amended_at'] = Variable<DateTime>(amendedAt);
    return map;
  }

  SignedNoteAmendmentsCompanion toCompanion(bool nullToAbsent) {
    return SignedNoteAmendmentsCompanion(
      id: Value(id),
      signedNoteId: Value(signedNoteId),
      authorStaffId: Value(authorStaffId),
      body: Value(body),
      amendedAt: Value(amendedAt),
    );
  }

  factory SignedNoteAmendmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignedNoteAmendmentRow(
      id: serializer.fromJson<String>(json['id']),
      signedNoteId: serializer.fromJson<String>(json['signedNoteId']),
      authorStaffId: serializer.fromJson<String>(json['authorStaffId']),
      body: serializer.fromJson<String>(json['body']),
      amendedAt: serializer.fromJson<DateTime>(json['amendedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'signedNoteId': serializer.toJson<String>(signedNoteId),
      'authorStaffId': serializer.toJson<String>(authorStaffId),
      'body': serializer.toJson<String>(body),
      'amendedAt': serializer.toJson<DateTime>(amendedAt),
    };
  }

  SignedNoteAmendmentRow copyWith({
    String? id,
    String? signedNoteId,
    String? authorStaffId,
    String? body,
    DateTime? amendedAt,
  }) => SignedNoteAmendmentRow(
    id: id ?? this.id,
    signedNoteId: signedNoteId ?? this.signedNoteId,
    authorStaffId: authorStaffId ?? this.authorStaffId,
    body: body ?? this.body,
    amendedAt: amendedAt ?? this.amendedAt,
  );
  SignedNoteAmendmentRow copyWithCompanion(SignedNoteAmendmentsCompanion data) {
    return SignedNoteAmendmentRow(
      id: data.id.present ? data.id.value : this.id,
      signedNoteId: data.signedNoteId.present
          ? data.signedNoteId.value
          : this.signedNoteId,
      authorStaffId: data.authorStaffId.present
          ? data.authorStaffId.value
          : this.authorStaffId,
      body: data.body.present ? data.body.value : this.body,
      amendedAt: data.amendedAt.present ? data.amendedAt.value : this.amendedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignedNoteAmendmentRow(')
          ..write('id: $id, ')
          ..write('signedNoteId: $signedNoteId, ')
          ..write('authorStaffId: $authorStaffId, ')
          ..write('body: $body, ')
          ..write('amendedAt: $amendedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, signedNoteId, authorStaffId, body, amendedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignedNoteAmendmentRow &&
          other.id == this.id &&
          other.signedNoteId == this.signedNoteId &&
          other.authorStaffId == this.authorStaffId &&
          other.body == this.body &&
          other.amendedAt == this.amendedAt);
}

class SignedNoteAmendmentsCompanion
    extends UpdateCompanion<SignedNoteAmendmentRow> {
  final Value<String> id;
  final Value<String> signedNoteId;
  final Value<String> authorStaffId;
  final Value<String> body;
  final Value<DateTime> amendedAt;
  final Value<int> rowid;
  const SignedNoteAmendmentsCompanion({
    this.id = const Value.absent(),
    this.signedNoteId = const Value.absent(),
    this.authorStaffId = const Value.absent(),
    this.body = const Value.absent(),
    this.amendedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SignedNoteAmendmentsCompanion.insert({
    required String id,
    required String signedNoteId,
    required String authorStaffId,
    required String body,
    this.amendedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       signedNoteId = Value(signedNoteId),
       authorStaffId = Value(authorStaffId),
       body = Value(body);
  static Insertable<SignedNoteAmendmentRow> custom({
    Expression<String>? id,
    Expression<String>? signedNoteId,
    Expression<String>? authorStaffId,
    Expression<String>? body,
    Expression<DateTime>? amendedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (signedNoteId != null) 'signed_note_id': signedNoteId,
      if (authorStaffId != null) 'author_staff_id': authorStaffId,
      if (body != null) 'body': body,
      if (amendedAt != null) 'amended_at': amendedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SignedNoteAmendmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? signedNoteId,
    Value<String>? authorStaffId,
    Value<String>? body,
    Value<DateTime>? amendedAt,
    Value<int>? rowid,
  }) {
    return SignedNoteAmendmentsCompanion(
      id: id ?? this.id,
      signedNoteId: signedNoteId ?? this.signedNoteId,
      authorStaffId: authorStaffId ?? this.authorStaffId,
      body: body ?? this.body,
      amendedAt: amendedAt ?? this.amendedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (signedNoteId.present) {
      map['signed_note_id'] = Variable<String>(signedNoteId.value);
    }
    if (authorStaffId.present) {
      map['author_staff_id'] = Variable<String>(authorStaffId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (amendedAt.present) {
      map['amended_at'] = Variable<DateTime>(amendedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignedNoteAmendmentsCompanion(')
          ..write('id: $id, ')
          ..write('signedNoteId: $signedNoteId, ')
          ..write('authorStaffId: $authorStaffId, ')
          ..write('body: $body, ')
          ..write('amendedAt: $amendedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentFilesTable extends DocumentFiles
    with TableInfo<$DocumentFilesTable, DocumentFileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentFilesTable(this.attachedDatabase, [this._alias]);
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
      'UNIQUE REFERENCES medical_records (id) ON DELETE CASCADE',
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
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storedAtMeta = const VerificationMeta(
    'storedAt',
  );
  @override
  late final GeneratedColumn<DateTime> storedAt = GeneratedColumn<DateTime>(
    'stored_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordId,
    fileName,
    mimeType,
    sizeBytes,
    sha256,
    bytes,
    storedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentFileRow> instance, {
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
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('stored_at')) {
      context.handle(
        _storedAtMeta,
        storedAt.isAcceptableOrUnknown(data['stored_at']!, _storedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_storedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DocumentFileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentFileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}bytes'],
      )!,
      storedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}stored_at'],
      )!,
    );
  }

  @override
  $DocumentFilesTable createAlias(String alias) {
    return $DocumentFilesTable(attachedDatabase, alias);
  }
}

class DocumentFileRow extends DataClass implements Insertable<DocumentFileRow> {
  final String id;
  final String recordId;
  final String fileName;
  final String mimeType;
  final int sizeBytes;

  /// Hex SHA-256 of [bytes] — proves the file shown is the one imported.
  final String sha256;
  final Uint8List bytes;
  final DateTime storedAt;
  const DocumentFileRow({
    required this.id,
    required this.recordId,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.sha256,
    required this.bytes,
    required this.storedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['record_id'] = Variable<String>(recordId);
    map['file_name'] = Variable<String>(fileName);
    map['mime_type'] = Variable<String>(mimeType);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['sha256'] = Variable<String>(sha256);
    map['bytes'] = Variable<Uint8List>(bytes);
    map['stored_at'] = Variable<DateTime>(storedAt);
    return map;
  }

  DocumentFilesCompanion toCompanion(bool nullToAbsent) {
    return DocumentFilesCompanion(
      id: Value(id),
      recordId: Value(recordId),
      fileName: Value(fileName),
      mimeType: Value(mimeType),
      sizeBytes: Value(sizeBytes),
      sha256: Value(sha256),
      bytes: Value(bytes),
      storedAt: Value(storedAt),
    );
  }

  factory DocumentFileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentFileRow(
      id: serializer.fromJson<String>(json['id']),
      recordId: serializer.fromJson<String>(json['recordId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      sha256: serializer.fromJson<String>(json['sha256']),
      bytes: serializer.fromJson<Uint8List>(json['bytes']),
      storedAt: serializer.fromJson<DateTime>(json['storedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recordId': serializer.toJson<String>(recordId),
      'fileName': serializer.toJson<String>(fileName),
      'mimeType': serializer.toJson<String>(mimeType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'sha256': serializer.toJson<String>(sha256),
      'bytes': serializer.toJson<Uint8List>(bytes),
      'storedAt': serializer.toJson<DateTime>(storedAt),
    };
  }

  DocumentFileRow copyWith({
    String? id,
    String? recordId,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    String? sha256,
    Uint8List? bytes,
    DateTime? storedAt,
  }) => DocumentFileRow(
    id: id ?? this.id,
    recordId: recordId ?? this.recordId,
    fileName: fileName ?? this.fileName,
    mimeType: mimeType ?? this.mimeType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    sha256: sha256 ?? this.sha256,
    bytes: bytes ?? this.bytes,
    storedAt: storedAt ?? this.storedAt,
  );
  DocumentFileRow copyWithCompanion(DocumentFilesCompanion data) {
    return DocumentFileRow(
      id: data.id.present ? data.id.value : this.id,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      storedAt: data.storedAt.present ? data.storedAt.value : this.storedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentFileRow(')
          ..write('id: $id, ')
          ..write('recordId: $recordId, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('bytes: $bytes, ')
          ..write('storedAt: $storedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recordId,
    fileName,
    mimeType,
    sizeBytes,
    sha256,
    $driftBlobEquality.hash(bytes),
    storedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentFileRow &&
          other.id == this.id &&
          other.recordId == this.recordId &&
          other.fileName == this.fileName &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.sha256 == this.sha256 &&
          $driftBlobEquality.equals(other.bytes, this.bytes) &&
          other.storedAt == this.storedAt);
}

class DocumentFilesCompanion extends UpdateCompanion<DocumentFileRow> {
  final Value<String> id;
  final Value<String> recordId;
  final Value<String> fileName;
  final Value<String> mimeType;
  final Value<int> sizeBytes;
  final Value<String> sha256;
  final Value<Uint8List> bytes;
  final Value<DateTime> storedAt;
  final Value<int> rowid;
  const DocumentFilesCompanion({
    this.id = const Value.absent(),
    this.recordId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.bytes = const Value.absent(),
    this.storedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentFilesCompanion.insert({
    required String id,
    required String recordId,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required String sha256,
    required Uint8List bytes,
    required DateTime storedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recordId = Value(recordId),
       fileName = Value(fileName),
       mimeType = Value(mimeType),
       sizeBytes = Value(sizeBytes),
       sha256 = Value(sha256),
       bytes = Value(bytes),
       storedAt = Value(storedAt);
  static Insertable<DocumentFileRow> custom({
    Expression<String>? id,
    Expression<String>? recordId,
    Expression<String>? fileName,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<String>? sha256,
    Expression<Uint8List>? bytes,
    Expression<DateTime>? storedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordId != null) 'record_id': recordId,
      if (fileName != null) 'file_name': fileName,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (sha256 != null) 'sha256': sha256,
      if (bytes != null) 'bytes': bytes,
      if (storedAt != null) 'stored_at': storedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentFilesCompanion copyWith({
    Value<String>? id,
    Value<String>? recordId,
    Value<String>? fileName,
    Value<String>? mimeType,
    Value<int>? sizeBytes,
    Value<String>? sha256,
    Value<Uint8List>? bytes,
    Value<DateTime>? storedAt,
    Value<int>? rowid,
  }) {
    return DocumentFilesCompanion(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      sha256: sha256 ?? this.sha256,
      bytes: bytes ?? this.bytes,
      storedAt: storedAt ?? this.storedAt,
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
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    if (storedAt.present) {
      map['stored_at'] = Variable<DateTime>(storedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentFilesCompanion(')
          ..write('id: $id, ')
          ..write('recordId: $recordId, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('bytes: $bytes, ')
          ..write('storedAt: $storedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentVerificationsTable extends DocumentVerifications
    with TableInfo<$DocumentVerificationsTable, DocumentVerificationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentVerificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentTypeMeta = const VerificationMeta(
    'documentType',
  );
  @override
  late final GeneratedColumn<String> documentType = GeneratedColumn<String>(
    'document_type',
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
  static const VerificationMeta _issuerMeta = const VerificationMeta('issuer');
  @override
  late final GeneratedColumn<String> issuer = GeneratedColumn<String>(
    'issuer',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issuedAtMeta = const VerificationMeta(
    'issuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> issuedAt = GeneratedColumn<DateTime>(
    'issued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    code,
    documentType,
    entityId,
    patientId,
    issuer,
    summary,
    issuedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_verifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentVerificationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('document_type')) {
      context.handle(
        _documentTypeMeta,
        documentType.isAcceptableOrUnknown(
          data['document_type']!,
          _documentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_documentTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('issuer')) {
      context.handle(
        _issuerMeta,
        issuer.isAcceptableOrUnknown(data['issuer']!, _issuerMeta),
      );
    } else if (isInserting) {
      context.missing(_issuerMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('issued_at')) {
      context.handle(
        _issuedAtMeta,
        issuedAt.isAcceptableOrUnknown(data['issued_at']!, _issuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_issuedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {documentType, entityId},
  ];
  @override
  DocumentVerificationRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentVerificationRow(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      documentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      issuer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issuer'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      issuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}issued_at'],
      )!,
    );
  }

  @override
  $DocumentVerificationsTable createAlias(String alias) {
    return $DocumentVerificationsTable(attachedDatabase, alias);
  }
}

class DocumentVerificationRow extends DataClass
    implements Insertable<DocumentVerificationRow> {
  /// Short code printed (and QR-encoded) on the document.
  final String code;

  /// `ExportDocument` name.
  final String documentType;
  final String entityId;
  final String patientId;

  /// The issuer as printed (clinician name).
  final String issuer;

  /// What the genuine document states, one fact per line.
  final String summary;
  final DateTime issuedAt;
  const DocumentVerificationRow({
    required this.code,
    required this.documentType,
    required this.entityId,
    required this.patientId,
    required this.issuer,
    required this.summary,
    required this.issuedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['document_type'] = Variable<String>(documentType);
    map['entity_id'] = Variable<String>(entityId);
    map['patient_id'] = Variable<String>(patientId);
    map['issuer'] = Variable<String>(issuer);
    map['summary'] = Variable<String>(summary);
    map['issued_at'] = Variable<DateTime>(issuedAt);
    return map;
  }

  DocumentVerificationsCompanion toCompanion(bool nullToAbsent) {
    return DocumentVerificationsCompanion(
      code: Value(code),
      documentType: Value(documentType),
      entityId: Value(entityId),
      patientId: Value(patientId),
      issuer: Value(issuer),
      summary: Value(summary),
      issuedAt: Value(issuedAt),
    );
  }

  factory DocumentVerificationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentVerificationRow(
      code: serializer.fromJson<String>(json['code']),
      documentType: serializer.fromJson<String>(json['documentType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      issuer: serializer.fromJson<String>(json['issuer']),
      summary: serializer.fromJson<String>(json['summary']),
      issuedAt: serializer.fromJson<DateTime>(json['issuedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'documentType': serializer.toJson<String>(documentType),
      'entityId': serializer.toJson<String>(entityId),
      'patientId': serializer.toJson<String>(patientId),
      'issuer': serializer.toJson<String>(issuer),
      'summary': serializer.toJson<String>(summary),
      'issuedAt': serializer.toJson<DateTime>(issuedAt),
    };
  }

  DocumentVerificationRow copyWith({
    String? code,
    String? documentType,
    String? entityId,
    String? patientId,
    String? issuer,
    String? summary,
    DateTime? issuedAt,
  }) => DocumentVerificationRow(
    code: code ?? this.code,
    documentType: documentType ?? this.documentType,
    entityId: entityId ?? this.entityId,
    patientId: patientId ?? this.patientId,
    issuer: issuer ?? this.issuer,
    summary: summary ?? this.summary,
    issuedAt: issuedAt ?? this.issuedAt,
  );
  DocumentVerificationRow copyWithCompanion(
    DocumentVerificationsCompanion data,
  ) {
    return DocumentVerificationRow(
      code: data.code.present ? data.code.value : this.code,
      documentType: data.documentType.present
          ? data.documentType.value
          : this.documentType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      issuer: data.issuer.present ? data.issuer.value : this.issuer,
      summary: data.summary.present ? data.summary.value : this.summary,
      issuedAt: data.issuedAt.present ? data.issuedAt.value : this.issuedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentVerificationRow(')
          ..write('code: $code, ')
          ..write('documentType: $documentType, ')
          ..write('entityId: $entityId, ')
          ..write('patientId: $patientId, ')
          ..write('issuer: $issuer, ')
          ..write('summary: $summary, ')
          ..write('issuedAt: $issuedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    code,
    documentType,
    entityId,
    patientId,
    issuer,
    summary,
    issuedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentVerificationRow &&
          other.code == this.code &&
          other.documentType == this.documentType &&
          other.entityId == this.entityId &&
          other.patientId == this.patientId &&
          other.issuer == this.issuer &&
          other.summary == this.summary &&
          other.issuedAt == this.issuedAt);
}

class DocumentVerificationsCompanion
    extends UpdateCompanion<DocumentVerificationRow> {
  final Value<String> code;
  final Value<String> documentType;
  final Value<String> entityId;
  final Value<String> patientId;
  final Value<String> issuer;
  final Value<String> summary;
  final Value<DateTime> issuedAt;
  final Value<int> rowid;
  const DocumentVerificationsCompanion({
    this.code = const Value.absent(),
    this.documentType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.issuer = const Value.absent(),
    this.summary = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentVerificationsCompanion.insert({
    required String code,
    required String documentType,
    required String entityId,
    required String patientId,
    required String issuer,
    required String summary,
    required DateTime issuedAt,
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       documentType = Value(documentType),
       entityId = Value(entityId),
       patientId = Value(patientId),
       issuer = Value(issuer),
       summary = Value(summary),
       issuedAt = Value(issuedAt);
  static Insertable<DocumentVerificationRow> custom({
    Expression<String>? code,
    Expression<String>? documentType,
    Expression<String>? entityId,
    Expression<String>? patientId,
    Expression<String>? issuer,
    Expression<String>? summary,
    Expression<DateTime>? issuedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (documentType != null) 'document_type': documentType,
      if (entityId != null) 'entity_id': entityId,
      if (patientId != null) 'patient_id': patientId,
      if (issuer != null) 'issuer': issuer,
      if (summary != null) 'summary': summary,
      if (issuedAt != null) 'issued_at': issuedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentVerificationsCompanion copyWith({
    Value<String>? code,
    Value<String>? documentType,
    Value<String>? entityId,
    Value<String>? patientId,
    Value<String>? issuer,
    Value<String>? summary,
    Value<DateTime>? issuedAt,
    Value<int>? rowid,
  }) {
    return DocumentVerificationsCompanion(
      code: code ?? this.code,
      documentType: documentType ?? this.documentType,
      entityId: entityId ?? this.entityId,
      patientId: patientId ?? this.patientId,
      issuer: issuer ?? this.issuer,
      summary: summary ?? this.summary,
      issuedAt: issuedAt ?? this.issuedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (documentType.present) {
      map['document_type'] = Variable<String>(documentType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (issuer.present) {
      map['issuer'] = Variable<String>(issuer.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (issuedAt.present) {
      map['issued_at'] = Variable<DateTime>(issuedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentVerificationsCompanion(')
          ..write('code: $code, ')
          ..write('documentType: $documentType, ')
          ..write('entityId: $entityId, ')
          ..write('patientId: $patientId, ')
          ..write('issuer: $issuer, ')
          ..write('summary: $summary, ')
          ..write('issuedAt: $issuedAt, ')
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
  late final GeneratedColumnWithTypeConverter<WorkPriority, String> priority =
      GeneratedColumn<String>(
        'priority',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('routine'),
      ).withConverter<WorkPriority>($StaffTasksTable.$converterpriority);
  static const VerificationMeta _coverageStaffIdMeta = const VerificationMeta(
    'coverageStaffId',
  );
  @override
  late final GeneratedColumn<String> coverageStaffId = GeneratedColumn<String>(
    'coverage_staff_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _escalatedAtMeta = const VerificationMeta(
    'escalatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> escalatedAt = GeneratedColumn<DateTime>(
    'escalated_at',
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    staffId,
    patientId,
    title,
    kind,
    dueAt,
    priority,
    coverageStaffId,
    escalatedAt,
    status,
    ruleScore,
    aiPriorityScore,
    aiRationale,
    createdAt,
    version,
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
    if (data.containsKey('coverage_staff_id')) {
      context.handle(
        _coverageStaffIdMeta,
        coverageStaffId.isAcceptableOrUnknown(
          data['coverage_staff_id']!,
          _coverageStaffIdMeta,
        ),
      );
    }
    if (data.containsKey('escalated_at')) {
      context.handle(
        _escalatedAtMeta,
        escalatedAt.isAcceptableOrUnknown(
          data['escalated_at']!,
          _escalatedAtMeta,
        ),
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
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
      priority: $StaffTasksTable.$converterpriority.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}priority'],
        )!,
      ),
      coverageStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coverage_staff_id'],
      ),
      escalatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}escalated_at'],
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
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $StaffTasksTable createAlias(String alias) {
    return $StaffTasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskKind, String, String> $converterkind =
      const EnumNameConverter<TaskKind>(TaskKind.values);
  static JsonTypeConverter2<WorkPriority, String, String> $converterpriority =
      const EnumNameConverter<WorkPriority>(WorkPriority.values);
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
  final WorkPriority priority;
  final String? coverageStaffId;
  final DateTime? escalatedAt;
  final TaskStatus status;

  /// Deterministic rule score (P5-03) — always present.
  final double ruleScore;

  /// LLM priority + rationale (P5-10) — null when AI is off.
  final double? aiPriorityScore;
  final String? aiRationale;
  final DateTime createdAt;

  /// Optimistic-concurrency version (trigger-bumped, schema v19).
  final int version;
  const StaffTaskRow({
    required this.id,
    required this.staffId,
    this.patientId,
    required this.title,
    required this.kind,
    this.dueAt,
    required this.priority,
    this.coverageStaffId,
    this.escalatedAt,
    required this.status,
    required this.ruleScore,
    this.aiPriorityScore,
    this.aiRationale,
    required this.createdAt,
    required this.version,
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
      map['priority'] = Variable<String>(
        $StaffTasksTable.$converterpriority.toSql(priority),
      );
    }
    if (!nullToAbsent || coverageStaffId != null) {
      map['coverage_staff_id'] = Variable<String>(coverageStaffId);
    }
    if (!nullToAbsent || escalatedAt != null) {
      map['escalated_at'] = Variable<DateTime>(escalatedAt);
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
    map['version'] = Variable<int>(version);
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
      priority: Value(priority),
      coverageStaffId: coverageStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverageStaffId),
      escalatedAt: escalatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(escalatedAt),
      status: Value(status),
      ruleScore: Value(ruleScore),
      aiPriorityScore: aiPriorityScore == null && nullToAbsent
          ? const Value.absent()
          : Value(aiPriorityScore),
      aiRationale: aiRationale == null && nullToAbsent
          ? const Value.absent()
          : Value(aiRationale),
      createdAt: Value(createdAt),
      version: Value(version),
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
      priority: $StaffTasksTable.$converterpriority.fromJson(
        serializer.fromJson<String>(json['priority']),
      ),
      coverageStaffId: serializer.fromJson<String?>(json['coverageStaffId']),
      escalatedAt: serializer.fromJson<DateTime?>(json['escalatedAt']),
      status: $StaffTasksTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      ruleScore: serializer.fromJson<double>(json['ruleScore']),
      aiPriorityScore: serializer.fromJson<double?>(json['aiPriorityScore']),
      aiRationale: serializer.fromJson<String?>(json['aiRationale']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      version: serializer.fromJson<int>(json['version']),
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
      'priority': serializer.toJson<String>(
        $StaffTasksTable.$converterpriority.toJson(priority),
      ),
      'coverageStaffId': serializer.toJson<String?>(coverageStaffId),
      'escalatedAt': serializer.toJson<DateTime?>(escalatedAt),
      'status': serializer.toJson<String>(
        $StaffTasksTable.$converterstatus.toJson(status),
      ),
      'ruleScore': serializer.toJson<double>(ruleScore),
      'aiPriorityScore': serializer.toJson<double?>(aiPriorityScore),
      'aiRationale': serializer.toJson<String?>(aiRationale),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'version': serializer.toJson<int>(version),
    };
  }

  StaffTaskRow copyWith({
    String? id,
    String? staffId,
    Value<String?> patientId = const Value.absent(),
    String? title,
    TaskKind? kind,
    Value<DateTime?> dueAt = const Value.absent(),
    WorkPriority? priority,
    Value<String?> coverageStaffId = const Value.absent(),
    Value<DateTime?> escalatedAt = const Value.absent(),
    TaskStatus? status,
    double? ruleScore,
    Value<double?> aiPriorityScore = const Value.absent(),
    Value<String?> aiRationale = const Value.absent(),
    DateTime? createdAt,
    int? version,
  }) => StaffTaskRow(
    id: id ?? this.id,
    staffId: staffId ?? this.staffId,
    patientId: patientId.present ? patientId.value : this.patientId,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    priority: priority ?? this.priority,
    coverageStaffId: coverageStaffId.present
        ? coverageStaffId.value
        : this.coverageStaffId,
    escalatedAt: escalatedAt.present ? escalatedAt.value : this.escalatedAt,
    status: status ?? this.status,
    ruleScore: ruleScore ?? this.ruleScore,
    aiPriorityScore: aiPriorityScore.present
        ? aiPriorityScore.value
        : this.aiPriorityScore,
    aiRationale: aiRationale.present ? aiRationale.value : this.aiRationale,
    createdAt: createdAt ?? this.createdAt,
    version: version ?? this.version,
  );
  StaffTaskRow copyWithCompanion(StaffTasksCompanion data) {
    return StaffTaskRow(
      id: data.id.present ? data.id.value : this.id,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      title: data.title.present ? data.title.value : this.title,
      kind: data.kind.present ? data.kind.value : this.kind,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      priority: data.priority.present ? data.priority.value : this.priority,
      coverageStaffId: data.coverageStaffId.present
          ? data.coverageStaffId.value
          : this.coverageStaffId,
      escalatedAt: data.escalatedAt.present
          ? data.escalatedAt.value
          : this.escalatedAt,
      status: data.status.present ? data.status.value : this.status,
      ruleScore: data.ruleScore.present ? data.ruleScore.value : this.ruleScore,
      aiPriorityScore: data.aiPriorityScore.present
          ? data.aiPriorityScore.value
          : this.aiPriorityScore,
      aiRationale: data.aiRationale.present
          ? data.aiRationale.value
          : this.aiRationale,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      version: data.version.present ? data.version.value : this.version,
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
          ..write('priority: $priority, ')
          ..write('coverageStaffId: $coverageStaffId, ')
          ..write('escalatedAt: $escalatedAt, ')
          ..write('status: $status, ')
          ..write('ruleScore: $ruleScore, ')
          ..write('aiPriorityScore: $aiPriorityScore, ')
          ..write('aiRationale: $aiRationale, ')
          ..write('createdAt: $createdAt, ')
          ..write('version: $version')
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
    priority,
    coverageStaffId,
    escalatedAt,
    status,
    ruleScore,
    aiPriorityScore,
    aiRationale,
    createdAt,
    version,
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
          other.priority == this.priority &&
          other.coverageStaffId == this.coverageStaffId &&
          other.escalatedAt == this.escalatedAt &&
          other.status == this.status &&
          other.ruleScore == this.ruleScore &&
          other.aiPriorityScore == this.aiPriorityScore &&
          other.aiRationale == this.aiRationale &&
          other.createdAt == this.createdAt &&
          other.version == this.version);
}

class StaffTasksCompanion extends UpdateCompanion<StaffTaskRow> {
  final Value<String> id;
  final Value<String> staffId;
  final Value<String?> patientId;
  final Value<String> title;
  final Value<TaskKind> kind;
  final Value<DateTime?> dueAt;
  final Value<WorkPriority> priority;
  final Value<String?> coverageStaffId;
  final Value<DateTime?> escalatedAt;
  final Value<TaskStatus> status;
  final Value<double> ruleScore;
  final Value<double?> aiPriorityScore;
  final Value<String?> aiRationale;
  final Value<DateTime> createdAt;
  final Value<int> version;
  final Value<int> rowid;
  const StaffTasksCompanion({
    this.id = const Value.absent(),
    this.staffId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.title = const Value.absent(),
    this.kind = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.coverageStaffId = const Value.absent(),
    this.escalatedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.ruleScore = const Value.absent(),
    this.aiPriorityScore = const Value.absent(),
    this.aiRationale = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StaffTasksCompanion.insert({
    required String id,
    required String staffId,
    this.patientId = const Value.absent(),
    required String title,
    required TaskKind kind,
    this.dueAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.coverageStaffId = const Value.absent(),
    this.escalatedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.ruleScore = const Value.absent(),
    this.aiPriorityScore = const Value.absent(),
    this.aiRationale = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.version = const Value.absent(),
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
    Expression<String>? priority,
    Expression<String>? coverageStaffId,
    Expression<DateTime>? escalatedAt,
    Expression<String>? status,
    Expression<double>? ruleScore,
    Expression<double>? aiPriorityScore,
    Expression<String>? aiRationale,
    Expression<DateTime>? createdAt,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (staffId != null) 'staff_id': staffId,
      if (patientId != null) 'patient_id': patientId,
      if (title != null) 'title': title,
      if (kind != null) 'kind': kind,
      if (dueAt != null) 'due_at': dueAt,
      if (priority != null) 'priority': priority,
      if (coverageStaffId != null) 'coverage_staff_id': coverageStaffId,
      if (escalatedAt != null) 'escalated_at': escalatedAt,
      if (status != null) 'status': status,
      if (ruleScore != null) 'rule_score': ruleScore,
      if (aiPriorityScore != null) 'ai_priority_score': aiPriorityScore,
      if (aiRationale != null) 'ai_rationale': aiRationale,
      if (createdAt != null) 'created_at': createdAt,
      if (version != null) 'version': version,
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
    Value<WorkPriority>? priority,
    Value<String?>? coverageStaffId,
    Value<DateTime?>? escalatedAt,
    Value<TaskStatus>? status,
    Value<double>? ruleScore,
    Value<double?>? aiPriorityScore,
    Value<String?>? aiRationale,
    Value<DateTime>? createdAt,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return StaffTasksCompanion(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      dueAt: dueAt ?? this.dueAt,
      priority: priority ?? this.priority,
      coverageStaffId: coverageStaffId ?? this.coverageStaffId,
      escalatedAt: escalatedAt ?? this.escalatedAt,
      status: status ?? this.status,
      ruleScore: ruleScore ?? this.ruleScore,
      aiPriorityScore: aiPriorityScore ?? this.aiPriorityScore,
      aiRationale: aiRationale ?? this.aiRationale,
      createdAt: createdAt ?? this.createdAt,
      version: version ?? this.version,
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
    if (priority.present) {
      map['priority'] = Variable<String>(
        $StaffTasksTable.$converterpriority.toSql(priority.value),
      );
    }
    if (coverageStaffId.present) {
      map['coverage_staff_id'] = Variable<String>(coverageStaffId.value);
    }
    if (escalatedAt.present) {
      map['escalated_at'] = Variable<DateTime>(escalatedAt.value);
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
    if (version.present) {
      map['version'] = Variable<int>(version.value);
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
          ..write('priority: $priority, ')
          ..write('coverageStaffId: $coverageStaffId, ')
          ..write('escalatedAt: $escalatedAt, ')
          ..write('status: $status, ')
          ..write('ruleScore: $ruleScore, ')
          ..write('aiPriorityScore: $aiPriorityScore, ')
          ..write('aiRationale: $aiRationale, ')
          ..write('createdAt: $createdAt, ')
          ..write('version: $version, ')
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

class $InvoicesTable extends Invoices
    with TableInfo<$InvoicesTable, InvoiceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoicesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _appointmentIdMeta = const VerificationMeta(
    'appointmentId',
  );
  @override
  late final GeneratedColumn<String> appointmentId = GeneratedColumn<String>(
    'appointment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES appointments (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxRateMeta = const VerificationMeta(
    'taxRate',
  );
  @override
  late final GeneratedColumn<double> taxRate = GeneratedColumn<double>(
    'tax_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _taxAmountMeta = const VerificationMeta(
    'taxAmount',
  );
  @override
  late final GeneratedColumn<double> taxAmount = GeneratedColumn<double>(
    'tax_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<InvoiceStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<InvoiceStatus>($InvoicesTable.$converterstatus);
  static const VerificationMeta _issuedAtMeta = const VerificationMeta(
    'issuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> issuedAt = GeneratedColumn<DateTime>(
    'issued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
    'paid_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _paidByAccountIdMeta = const VerificationMeta(
    'paidByAccountId',
  );
  @override
  late final GeneratedColumn<String> paidByAccountId = GeneratedColumn<String>(
    'paid_by_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    appointmentId,
    subtotal,
    taxRate,
    taxAmount,
    totalAmount,
    status,
    issuedAt,
    dueDate,
    paidAt,
    paymentMethod,
    notes,
    paidByAccountId,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoices';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvoiceRow> instance, {
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
    if (data.containsKey('appointment_id')) {
      context.handle(
        _appointmentIdMeta,
        appointmentId.isAcceptableOrUnknown(
          data['appointment_id']!,
          _appointmentIdMeta,
        ),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    }
    if (data.containsKey('tax_rate')) {
      context.handle(
        _taxRateMeta,
        taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta),
      );
    }
    if (data.containsKey('tax_amount')) {
      context.handle(
        _taxAmountMeta,
        taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('issued_at')) {
      context.handle(
        _issuedAtMeta,
        issuedAt.isAcceptableOrUnknown(data['issued_at']!, _issuedAtMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('paid_at')) {
      context.handle(
        _paidAtMeta,
        paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('paid_by_account_id')) {
      context.handle(
        _paidByAccountIdMeta,
        paidByAccountId.isAcceptableOrUnknown(
          data['paid_by_account_id']!,
          _paidByAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      appointmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appointment_id'],
      ),
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      taxRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax_rate'],
      )!,
      taxAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax_amount'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      status: $InvoicesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      issuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}issued_at'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      paidAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_at'],
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      paidByAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paid_by_account_id'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $InvoicesTable createAlias(String alias) {
    return $InvoicesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<InvoiceStatus, String, String> $converterstatus =
      const EnumNameConverter<InvoiceStatus>(InvoiceStatus.values);
}

class InvoiceRow extends DataClass implements Insertable<InvoiceRow> {
  final String id;
  final String patientId;

  /// The visit this bill covers, if it came from one. Kept when the
  /// appointment is deleted so the financial record survives.
  final String? appointmentId;
  final double subtotal;

  /// Percent, e.g. `10` for 10%.
  final double taxRate;
  final double taxAmount;
  final double totalAmount;
  final InvoiceStatus status;
  final DateTime issuedAt;
  final DateTime? dueDate;
  final DateTime? paidAt;

  /// Masked descriptor only — the full card number is never stored.
  final String? paymentMethod;
  final String? notes;

  /// The signed-in account that paid (the patient or a proxy).
  final String? paidByAccountId;

  /// Optimistic-concurrency version (trigger-bumped, schema v19).
  final int version;
  const InvoiceRow({
    required this.id,
    required this.patientId,
    this.appointmentId,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.totalAmount,
    required this.status,
    required this.issuedAt,
    this.dueDate,
    this.paidAt,
    this.paymentMethod,
    this.notes,
    this.paidByAccountId,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    if (!nullToAbsent || appointmentId != null) {
      map['appointment_id'] = Variable<String>(appointmentId);
    }
    map['subtotal'] = Variable<double>(subtotal);
    map['tax_rate'] = Variable<double>(taxRate);
    map['tax_amount'] = Variable<double>(taxAmount);
    map['total_amount'] = Variable<double>(totalAmount);
    {
      map['status'] = Variable<String>(
        $InvoicesTable.$converterstatus.toSql(status),
      );
    }
    map['issued_at'] = Variable<DateTime>(issuedAt);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || paidAt != null) {
      map['paid_at'] = Variable<DateTime>(paidAt);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || paidByAccountId != null) {
      map['paid_by_account_id'] = Variable<String>(paidByAccountId);
    }
    map['version'] = Variable<int>(version);
    return map;
  }

  InvoicesCompanion toCompanion(bool nullToAbsent) {
    return InvoicesCompanion(
      id: Value(id),
      patientId: Value(patientId),
      appointmentId: appointmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(appointmentId),
      subtotal: Value(subtotal),
      taxRate: Value(taxRate),
      taxAmount: Value(taxAmount),
      totalAmount: Value(totalAmount),
      status: Value(status),
      issuedAt: Value(issuedAt),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      paidAt: paidAt == null && nullToAbsent
          ? const Value.absent()
          : Value(paidAt),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      paidByAccountId: paidByAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(paidByAccountId),
      version: Value(version),
    );
  }

  factory InvoiceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceRow(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      appointmentId: serializer.fromJson<String?>(json['appointmentId']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      taxRate: serializer.fromJson<double>(json['taxRate']),
      taxAmount: serializer.fromJson<double>(json['taxAmount']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      status: $InvoicesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      issuedAt: serializer.fromJson<DateTime>(json['issuedAt']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      paidAt: serializer.fromJson<DateTime?>(json['paidAt']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      notes: serializer.fromJson<String?>(json['notes']),
      paidByAccountId: serializer.fromJson<String?>(json['paidByAccountId']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'appointmentId': serializer.toJson<String?>(appointmentId),
      'subtotal': serializer.toJson<double>(subtotal),
      'taxRate': serializer.toJson<double>(taxRate),
      'taxAmount': serializer.toJson<double>(taxAmount),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'status': serializer.toJson<String>(
        $InvoicesTable.$converterstatus.toJson(status),
      ),
      'issuedAt': serializer.toJson<DateTime>(issuedAt),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'paidAt': serializer.toJson<DateTime?>(paidAt),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'notes': serializer.toJson<String?>(notes),
      'paidByAccountId': serializer.toJson<String?>(paidByAccountId),
      'version': serializer.toJson<int>(version),
    };
  }

  InvoiceRow copyWith({
    String? id,
    String? patientId,
    Value<String?> appointmentId = const Value.absent(),
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? totalAmount,
    InvoiceStatus? status,
    DateTime? issuedAt,
    Value<DateTime?> dueDate = const Value.absent(),
    Value<DateTime?> paidAt = const Value.absent(),
    Value<String?> paymentMethod = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> paidByAccountId = const Value.absent(),
    int? version,
  }) => InvoiceRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    appointmentId: appointmentId.present
        ? appointmentId.value
        : this.appointmentId,
    subtotal: subtotal ?? this.subtotal,
    taxRate: taxRate ?? this.taxRate,
    taxAmount: taxAmount ?? this.taxAmount,
    totalAmount: totalAmount ?? this.totalAmount,
    status: status ?? this.status,
    issuedAt: issuedAt ?? this.issuedAt,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    paidAt: paidAt.present ? paidAt.value : this.paidAt,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    notes: notes.present ? notes.value : this.notes,
    paidByAccountId: paidByAccountId.present
        ? paidByAccountId.value
        : this.paidByAccountId,
    version: version ?? this.version,
  );
  InvoiceRow copyWithCompanion(InvoicesCompanion data) {
    return InvoiceRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      appointmentId: data.appointmentId.present
          ? data.appointmentId.value
          : this.appointmentId,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      status: data.status.present ? data.status.value : this.status,
      issuedAt: data.issuedAt.present ? data.issuedAt.value : this.issuedAt,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      notes: data.notes.present ? data.notes.value : this.notes,
      paidByAccountId: data.paidByAccountId.present
          ? data.paidByAccountId.value
          : this.paidByAccountId,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('subtotal: $subtotal, ')
          ..write('taxRate: $taxRate, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('status: $status, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('dueDate: $dueDate, ')
          ..write('paidAt: $paidAt, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('notes: $notes, ')
          ..write('paidByAccountId: $paidByAccountId, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    appointmentId,
    subtotal,
    taxRate,
    taxAmount,
    totalAmount,
    status,
    issuedAt,
    dueDate,
    paidAt,
    paymentMethod,
    notes,
    paidByAccountId,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.appointmentId == this.appointmentId &&
          other.subtotal == this.subtotal &&
          other.taxRate == this.taxRate &&
          other.taxAmount == this.taxAmount &&
          other.totalAmount == this.totalAmount &&
          other.status == this.status &&
          other.issuedAt == this.issuedAt &&
          other.dueDate == this.dueDate &&
          other.paidAt == this.paidAt &&
          other.paymentMethod == this.paymentMethod &&
          other.notes == this.notes &&
          other.paidByAccountId == this.paidByAccountId &&
          other.version == this.version);
}

class InvoicesCompanion extends UpdateCompanion<InvoiceRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String?> appointmentId;
  final Value<double> subtotal;
  final Value<double> taxRate;
  final Value<double> taxAmount;
  final Value<double> totalAmount;
  final Value<InvoiceStatus> status;
  final Value<DateTime> issuedAt;
  final Value<DateTime?> dueDate;
  final Value<DateTime?> paidAt;
  final Value<String?> paymentMethod;
  final Value<String?> notes;
  final Value<String?> paidByAccountId;
  final Value<int> version;
  final Value<int> rowid;
  const InvoicesCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.appointmentId = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.status = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.notes = const Value.absent(),
    this.paidByAccountId = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoicesCompanion.insert({
    required String id,
    required String patientId,
    this.appointmentId = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.status = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.notes = const Value.absent(),
    this.paidByAccountId = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId);
  static Insertable<InvoiceRow> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? appointmentId,
    Expression<double>? subtotal,
    Expression<double>? taxRate,
    Expression<double>? taxAmount,
    Expression<double>? totalAmount,
    Expression<String>? status,
    Expression<DateTime>? issuedAt,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? paidAt,
    Expression<String>? paymentMethod,
    Expression<String>? notes,
    Expression<String>? paidByAccountId,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (subtotal != null) 'subtotal': subtotal,
      if (taxRate != null) 'tax_rate': taxRate,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (status != null) 'status': status,
      if (issuedAt != null) 'issued_at': issuedAt,
      if (dueDate != null) 'due_date': dueDate,
      if (paidAt != null) 'paid_at': paidAt,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (notes != null) 'notes': notes,
      if (paidByAccountId != null) 'paid_by_account_id': paidByAccountId,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoicesCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String?>? appointmentId,
    Value<double>? subtotal,
    Value<double>? taxRate,
    Value<double>? taxAmount,
    Value<double>? totalAmount,
    Value<InvoiceStatus>? status,
    Value<DateTime>? issuedAt,
    Value<DateTime?>? dueDate,
    Value<DateTime?>? paidAt,
    Value<String?>? paymentMethod,
    Value<String?>? notes,
    Value<String?>? paidByAccountId,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return InvoicesCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      appointmentId: appointmentId ?? this.appointmentId,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      issuedAt: issuedAt ?? this.issuedAt,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      paidByAccountId: paidByAccountId ?? this.paidByAccountId,
      version: version ?? this.version,
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
    if (appointmentId.present) {
      map['appointment_id'] = Variable<String>(appointmentId.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<double>(taxRate.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<double>(taxAmount.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $InvoicesTable.$converterstatus.toSql(status.value),
      );
    }
    if (issuedAt.present) {
      map['issued_at'] = Variable<DateTime>(issuedAt.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (paidByAccountId.present) {
      map['paid_by_account_id'] = Variable<String>(paidByAccountId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoicesCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('subtotal: $subtotal, ')
          ..write('taxRate: $taxRate, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('status: $status, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('dueDate: $dueDate, ')
          ..write('paidAt: $paidAt, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('notes: $notes, ')
          ..write('paidByAccountId: $paidByAccountId, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentMethodsTable extends PaymentMethods
    with TableInfo<$PaymentMethodsTable, PaymentMethodRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentMethodsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _last4Meta = const VerificationMeta('last4');
  @override
  late final GeneratedColumn<String> last4 = GeneratedColumn<String>(
    'last4',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 4,
      maxTextLength: 4,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiryMonthMeta = const VerificationMeta(
    'expiryMonth',
  );
  @override
  late final GeneratedColumn<int> expiryMonth = GeneratedColumn<int>(
    'expiry_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiryYearMeta = const VerificationMeta(
    'expiryYear',
  );
  @override
  late final GeneratedColumn<int> expiryYear = GeneratedColumn<int>(
    'expiry_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _holderNameMeta = const VerificationMeta(
    'holderName',
  );
  @override
  late final GeneratedColumn<String> holderName = GeneratedColumn<String>(
    'holder_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    brand,
    last4,
    expiryMonth,
    expiryYear,
    holderName,
    addedAt,
    isDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payment_methods';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentMethodRow> instance, {
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
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    } else if (isInserting) {
      context.missing(_brandMeta);
    }
    if (data.containsKey('last4')) {
      context.handle(
        _last4Meta,
        last4.isAcceptableOrUnknown(data['last4']!, _last4Meta),
      );
    } else if (isInserting) {
      context.missing(_last4Meta);
    }
    if (data.containsKey('expiry_month')) {
      context.handle(
        _expiryMonthMeta,
        expiryMonth.isAcceptableOrUnknown(
          data['expiry_month']!,
          _expiryMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expiryMonthMeta);
    }
    if (data.containsKey('expiry_year')) {
      context.handle(
        _expiryYearMeta,
        expiryYear.isAcceptableOrUnknown(data['expiry_year']!, _expiryYearMeta),
      );
    } else if (isInserting) {
      context.missing(_expiryYearMeta);
    }
    if (data.containsKey('holder_name')) {
      context.handle(
        _holderNameMeta,
        holderName.isAcceptableOrUnknown(data['holder_name']!, _holderNameMeta),
      );
    } else if (isInserting) {
      context.missing(_holderNameMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentMethodRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentMethodRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      last4: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last4'],
      )!,
      expiryMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expiry_month'],
      )!,
      expiryYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expiry_year'],
      )!,
      holderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}holder_name'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  $PaymentMethodsTable createAlias(String alias) {
    return $PaymentMethodsTable(attachedDatabase, alias);
  }
}

class PaymentMethodRow extends DataClass
    implements Insertable<PaymentMethodRow> {
  final String id;
  final String patientId;
  final String brand;
  final String last4;
  final int expiryMonth;
  final int expiryYear;
  final String holderName;
  final DateTime addedAt;
  final bool isDefault;
  const PaymentMethodRow({
    required this.id,
    required this.patientId,
    required this.brand,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    required this.holderName,
    required this.addedAt,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['brand'] = Variable<String>(brand);
    map['last4'] = Variable<String>(last4);
    map['expiry_month'] = Variable<int>(expiryMonth);
    map['expiry_year'] = Variable<int>(expiryYear);
    map['holder_name'] = Variable<String>(holderName);
    map['added_at'] = Variable<DateTime>(addedAt);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  PaymentMethodsCompanion toCompanion(bool nullToAbsent) {
    return PaymentMethodsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      brand: Value(brand),
      last4: Value(last4),
      expiryMonth: Value(expiryMonth),
      expiryYear: Value(expiryYear),
      holderName: Value(holderName),
      addedAt: Value(addedAt),
      isDefault: Value(isDefault),
    );
  }

  factory PaymentMethodRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentMethodRow(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      brand: serializer.fromJson<String>(json['brand']),
      last4: serializer.fromJson<String>(json['last4']),
      expiryMonth: serializer.fromJson<int>(json['expiryMonth']),
      expiryYear: serializer.fromJson<int>(json['expiryYear']),
      holderName: serializer.fromJson<String>(json['holderName']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'brand': serializer.toJson<String>(brand),
      'last4': serializer.toJson<String>(last4),
      'expiryMonth': serializer.toJson<int>(expiryMonth),
      'expiryYear': serializer.toJson<int>(expiryYear),
      'holderName': serializer.toJson<String>(holderName),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  PaymentMethodRow copyWith({
    String? id,
    String? patientId,
    String? brand,
    String? last4,
    int? expiryMonth,
    int? expiryYear,
    String? holderName,
    DateTime? addedAt,
    bool? isDefault,
  }) => PaymentMethodRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    brand: brand ?? this.brand,
    last4: last4 ?? this.last4,
    expiryMonth: expiryMonth ?? this.expiryMonth,
    expiryYear: expiryYear ?? this.expiryYear,
    holderName: holderName ?? this.holderName,
    addedAt: addedAt ?? this.addedAt,
    isDefault: isDefault ?? this.isDefault,
  );
  PaymentMethodRow copyWithCompanion(PaymentMethodsCompanion data) {
    return PaymentMethodRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      brand: data.brand.present ? data.brand.value : this.brand,
      last4: data.last4.present ? data.last4.value : this.last4,
      expiryMonth: data.expiryMonth.present
          ? data.expiryMonth.value
          : this.expiryMonth,
      expiryYear: data.expiryYear.present
          ? data.expiryYear.value
          : this.expiryYear,
      holderName: data.holderName.present
          ? data.holderName.value
          : this.holderName,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('brand: $brand, ')
          ..write('last4: $last4, ')
          ..write('expiryMonth: $expiryMonth, ')
          ..write('expiryYear: $expiryYear, ')
          ..write('holderName: $holderName, ')
          ..write('addedAt: $addedAt, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    brand,
    last4,
    expiryMonth,
    expiryYear,
    holderName,
    addedAt,
    isDefault,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentMethodRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.brand == this.brand &&
          other.last4 == this.last4 &&
          other.expiryMonth == this.expiryMonth &&
          other.expiryYear == this.expiryYear &&
          other.holderName == this.holderName &&
          other.addedAt == this.addedAt &&
          other.isDefault == this.isDefault);
}

class PaymentMethodsCompanion extends UpdateCompanion<PaymentMethodRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> brand;
  final Value<String> last4;
  final Value<int> expiryMonth;
  final Value<int> expiryYear;
  final Value<String> holderName;
  final Value<DateTime> addedAt;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const PaymentMethodsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.brand = const Value.absent(),
    this.last4 = const Value.absent(),
    this.expiryMonth = const Value.absent(),
    this.expiryYear = const Value.absent(),
    this.holderName = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentMethodsCompanion.insert({
    required String id,
    required String patientId,
    required String brand,
    required String last4,
    required int expiryMonth,
    required int expiryYear,
    required String holderName,
    this.addedAt = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       brand = Value(brand),
       last4 = Value(last4),
       expiryMonth = Value(expiryMonth),
       expiryYear = Value(expiryYear),
       holderName = Value(holderName);
  static Insertable<PaymentMethodRow> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? brand,
    Expression<String>? last4,
    Expression<int>? expiryMonth,
    Expression<int>? expiryYear,
    Expression<String>? holderName,
    Expression<DateTime>? addedAt,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (brand != null) 'brand': brand,
      if (last4 != null) 'last4': last4,
      if (expiryMonth != null) 'expiry_month': expiryMonth,
      if (expiryYear != null) 'expiry_year': expiryYear,
      if (holderName != null) 'holder_name': holderName,
      if (addedAt != null) 'added_at': addedAt,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentMethodsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String>? brand,
    Value<String>? last4,
    Value<int>? expiryMonth,
    Value<int>? expiryYear,
    Value<String>? holderName,
    Value<DateTime>? addedAt,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return PaymentMethodsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      brand: brand ?? this.brand,
      last4: last4 ?? this.last4,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      holderName: holderName ?? this.holderName,
      addedAt: addedAt ?? this.addedAt,
      isDefault: isDefault ?? this.isDefault,
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
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (last4.present) {
      map['last4'] = Variable<String>(last4.value);
    }
    if (expiryMonth.present) {
      map['expiry_month'] = Variable<int>(expiryMonth.value);
    }
    if (expiryYear.present) {
      map['expiry_year'] = Variable<int>(expiryYear.value);
    }
    if (holderName.present) {
      map['holder_name'] = Variable<String>(holderName.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('brand: $brand, ')
          ..write('last4: $last4, ')
          ..write('expiryMonth: $expiryMonth, ')
          ..write('expiryYear: $expiryYear, ')
          ..write('holderName: $holderName, ')
          ..write('addedAt: $addedAt, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WalletTransactionsTable extends WalletTransactions
    with TableInfo<$WalletTransactionsTable, WalletTransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalletTransactionsTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumnWithTypeConverter<WalletTransactionType, String>
  type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WalletTransactionType>(
        $WalletTransactionsTable.$convertertype,
      );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
    'invoice_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES invoices (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _actorAccountIdMeta = const VerificationMeta(
    'actorAccountId',
  );
  @override
  late final GeneratedColumn<String> actorAccountId = GeneratedColumn<String>(
    'actor_account_id',
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
    type,
    amount,
    method,
    invoiceId,
    actorAccountId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallet_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WalletTransactionRow> instance, {
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
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    }
    if (data.containsKey('actor_account_id')) {
      context.handle(
        _actorAccountIdMeta,
        actorAccountId.isAcceptableOrUnknown(
          data['actor_account_id']!,
          _actorAccountIdMeta,
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
  WalletTransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WalletTransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      type: $WalletTransactionsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      ),
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_id'],
      ),
      actorAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_account_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WalletTransactionsTable createAlias(String alias) {
    return $WalletTransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WalletTransactionType, String, String>
  $convertertype = const EnumNameConverter<WalletTransactionType>(
    WalletTransactionType.values,
  );
}

class WalletTransactionRow extends DataClass
    implements Insertable<WalletTransactionRow> {
  final String id;
  final String patientId;
  final WalletTransactionType type;

  /// Always positive — `type` gives the sign.
  final double amount;

  /// Masked card descriptor for a top-up, null for a redemption.
  final String? method;

  /// The invoice a redemption paid toward, null for a top-up.
  final String? invoiceId;

  /// The signed-in account that moved the money (the patient or a proxy).
  final String? actorAccountId;
  final DateTime createdAt;
  const WalletTransactionRow({
    required this.id,
    required this.patientId,
    required this.type,
    required this.amount,
    this.method,
    this.invoiceId,
    this.actorAccountId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    {
      map['type'] = Variable<String>(
        $WalletTransactionsTable.$convertertype.toSql(type),
      );
    }
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || method != null) {
      map['method'] = Variable<String>(method);
    }
    if (!nullToAbsent || invoiceId != null) {
      map['invoice_id'] = Variable<String>(invoiceId);
    }
    if (!nullToAbsent || actorAccountId != null) {
      map['actor_account_id'] = Variable<String>(actorAccountId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WalletTransactionsCompanion toCompanion(bool nullToAbsent) {
    return WalletTransactionsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      type: Value(type),
      amount: Value(amount),
      method: method == null && nullToAbsent
          ? const Value.absent()
          : Value(method),
      invoiceId: invoiceId == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceId),
      actorAccountId: actorAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorAccountId),
      createdAt: Value(createdAt),
    );
  }

  factory WalletTransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WalletTransactionRow(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      type: $WalletTransactionsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      amount: serializer.fromJson<double>(json['amount']),
      method: serializer.fromJson<String?>(json['method']),
      invoiceId: serializer.fromJson<String?>(json['invoiceId']),
      actorAccountId: serializer.fromJson<String?>(json['actorAccountId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'type': serializer.toJson<String>(
        $WalletTransactionsTable.$convertertype.toJson(type),
      ),
      'amount': serializer.toJson<double>(amount),
      'method': serializer.toJson<String?>(method),
      'invoiceId': serializer.toJson<String?>(invoiceId),
      'actorAccountId': serializer.toJson<String?>(actorAccountId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WalletTransactionRow copyWith({
    String? id,
    String? patientId,
    WalletTransactionType? type,
    double? amount,
    Value<String?> method = const Value.absent(),
    Value<String?> invoiceId = const Value.absent(),
    Value<String?> actorAccountId = const Value.absent(),
    DateTime? createdAt,
  }) => WalletTransactionRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    method: method.present ? method.value : this.method,
    invoiceId: invoiceId.present ? invoiceId.value : this.invoiceId,
    actorAccountId: actorAccountId.present
        ? actorAccountId.value
        : this.actorAccountId,
    createdAt: createdAt ?? this.createdAt,
  );
  WalletTransactionRow copyWithCompanion(WalletTransactionsCompanion data) {
    return WalletTransactionRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      method: data.method.present ? data.method.value : this.method,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      actorAccountId: data.actorAccountId.present
          ? data.actorAccountId.value
          : this.actorAccountId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WalletTransactionRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('actorAccountId: $actorAccountId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    type,
    amount,
    method,
    invoiceId,
    actorAccountId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalletTransactionRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.method == this.method &&
          other.invoiceId == this.invoiceId &&
          other.actorAccountId == this.actorAccountId &&
          other.createdAt == this.createdAt);
}

class WalletTransactionsCompanion
    extends UpdateCompanion<WalletTransactionRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<WalletTransactionType> type;
  final Value<double> amount;
  final Value<String?> method;
  final Value<String?> invoiceId;
  final Value<String?> actorAccountId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const WalletTransactionsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.method = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.actorAccountId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WalletTransactionsCompanion.insert({
    required String id,
    required String patientId,
    required WalletTransactionType type,
    required double amount,
    this.method = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.actorAccountId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       type = Value(type),
       amount = Value(amount);
  static Insertable<WalletTransactionRow> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? type,
    Expression<double>? amount,
    Expression<String>? method,
    Expression<String>? invoiceId,
    Expression<String>? actorAccountId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (method != null) 'method': method,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (actorAccountId != null) 'actor_account_id': actorAccountId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WalletTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<WalletTransactionType>? type,
    Value<double>? amount,
    Value<String?>? method,
    Value<String?>? invoiceId,
    Value<String?>? actorAccountId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return WalletTransactionsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      invoiceId: invoiceId ?? this.invoiceId,
      actorAccountId: actorAccountId ?? this.actorAccountId,
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
    if (type.present) {
      map['type'] = Variable<String>(
        $WalletTransactionsTable.$convertertype.toSql(type.value),
      );
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (actorAccountId.present) {
      map['actor_account_id'] = Variable<String>(actorAccountId.value);
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
    return (StringBuffer('WalletTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('actorAccountId: $actorAccountId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentTransactionsTable extends PaymentTransactions
    with TableInfo<$PaymentTransactionsTable, PaymentTransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentTransactionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
    'invoice_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES invoices (id) ON DELETE SET NULL',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PaymentKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PaymentKind>($PaymentTransactionsTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<PaymentMethodKind, String>
  method =
      GeneratedColumn<String>(
        'method',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PaymentMethodKind>(
        $PaymentTransactionsTable.$convertermethod,
      );
  @override
  late final GeneratedColumnWithTypeConverter<PaymentStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('initiated'),
      ).withConverter<PaymentStatus>(
        $PaymentTransactionsTable.$converterstatus,
      );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestReferenceMeta = const VerificationMeta(
    'requestReference',
  );
  @override
  late final GeneratedColumn<String> requestReference = GeneratedColumn<String>(
    'request_reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _providerReferenceMeta = const VerificationMeta(
    'providerReference',
  );
  @override
  late final GeneratedColumn<String> providerReference =
      GeneratedColumn<String>(
        'provider_reference',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _methodDescriptorMeta = const VerificationMeta(
    'methodDescriptor',
  );
  @override
  late final GeneratedColumn<String> methodDescriptor = GeneratedColumn<String>(
    'method_descriptor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refundOfIdMeta = const VerificationMeta(
    'refundOfId',
  );
  @override
  late final GeneratedColumn<String> refundOfId = GeneratedColumn<String>(
    'refund_of_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failureReasonMeta = const VerificationMeta(
    'failureReason',
  );
  @override
  late final GeneratedColumn<String> failureReason = GeneratedColumn<String>(
    'failure_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actorAccountIdMeta = const VerificationMeta(
    'actorAccountId',
  );
  @override
  late final GeneratedColumn<String> actorAccountId = GeneratedColumn<String>(
    'actor_account_id',
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
  static const VerificationMeta _settledAtMeta = const VerificationMeta(
    'settledAt',
  );
  @override
  late final GeneratedColumn<DateTime> settledAt = GeneratedColumn<DateTime>(
    'settled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reconciledAtMeta = const VerificationMeta(
    'reconciledAt',
  );
  @override
  late final GeneratedColumn<DateTime> reconciledAt = GeneratedColumn<DateTime>(
    'reconciled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    invoiceId,
    kind,
    method,
    status,
    amount,
    provider,
    requestReference,
    providerReference,
    methodDescriptor,
    refundOfId,
    reason,
    failureReason,
    actorAccountId,
    createdAt,
    updatedAt,
    settledAt,
    reconciledAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payment_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentTransactionRow> instance, {
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
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('request_reference')) {
      context.handle(
        _requestReferenceMeta,
        requestReference.isAcceptableOrUnknown(
          data['request_reference']!,
          _requestReferenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestReferenceMeta);
    }
    if (data.containsKey('provider_reference')) {
      context.handle(
        _providerReferenceMeta,
        providerReference.isAcceptableOrUnknown(
          data['provider_reference']!,
          _providerReferenceMeta,
        ),
      );
    }
    if (data.containsKey('method_descriptor')) {
      context.handle(
        _methodDescriptorMeta,
        methodDescriptor.isAcceptableOrUnknown(
          data['method_descriptor']!,
          _methodDescriptorMeta,
        ),
      );
    }
    if (data.containsKey('refund_of_id')) {
      context.handle(
        _refundOfIdMeta,
        refundOfId.isAcceptableOrUnknown(
          data['refund_of_id']!,
          _refundOfIdMeta,
        ),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('failure_reason')) {
      context.handle(
        _failureReasonMeta,
        failureReason.isAcceptableOrUnknown(
          data['failure_reason']!,
          _failureReasonMeta,
        ),
      );
    }
    if (data.containsKey('actor_account_id')) {
      context.handle(
        _actorAccountIdMeta,
        actorAccountId.isAcceptableOrUnknown(
          data['actor_account_id']!,
          _actorAccountIdMeta,
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
    if (data.containsKey('settled_at')) {
      context.handle(
        _settledAtMeta,
        settledAt.isAcceptableOrUnknown(data['settled_at']!, _settledAtMeta),
      );
    }
    if (data.containsKey('reconciled_at')) {
      context.handle(
        _reconciledAtMeta,
        reconciledAt.isAcceptableOrUnknown(
          data['reconciled_at']!,
          _reconciledAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentTransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentTransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_id'],
      ),
      kind: $PaymentTransactionsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      method: $PaymentTransactionsTable.$convertermethod.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}method'],
        )!,
      ),
      status: $PaymentTransactionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      requestReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_reference'],
      )!,
      providerReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_reference'],
      ),
      methodDescriptor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method_descriptor'],
      ),
      refundOfId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refund_of_id'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      failureReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_reason'],
      ),
      actorAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_account_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      settledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}settled_at'],
      ),
      reconciledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reconciled_at'],
      ),
    );
  }

  @override
  $PaymentTransactionsTable createAlias(String alias) {
    return $PaymentTransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PaymentKind, String, String> $converterkind =
      const EnumNameConverter<PaymentKind>(PaymentKind.values);
  static JsonTypeConverter2<PaymentMethodKind, String, String>
  $convertermethod = const EnumNameConverter<PaymentMethodKind>(
    PaymentMethodKind.values,
  );
  static JsonTypeConverter2<PaymentStatus, String, String> $converterstatus =
      const EnumNameConverter<PaymentStatus>(PaymentStatus.values);
}

class PaymentTransactionRow extends DataClass
    implements Insertable<PaymentTransactionRow> {
  final String id;
  final String patientId;

  /// The bill this pays or refunds; null for a wallet top-up.
  final String? invoiceId;
  final PaymentKind kind;
  final PaymentMethodKind method;
  final PaymentStatus status;

  /// Always positive, in BHD (three decimals).
  final double amount;

  /// Who processed it: `simulated-card`, `wallet`, `offline`.
  final String provider;

  /// Our reference for this attempt, sent to the provider as its idempotency
  /// key. Re-sending it can never charge twice.
  final String requestReference;

  /// The provider's own reference once it has one (charge/refund id, or the
  /// desk receipt number for an offline payment).
  final String? providerReference;

  /// Masked descriptor only ("Visa ····4242", "Wallet balance").
  final String? methodDescriptor;

  /// For a refund: the settled charge it returns money from.
  final String? refundOfId;

  /// Why a refund or offline payment was recorded (staff-entered).
  final String? reason;

  /// Decline or failure code — never card data.
  final String? failureReason;
  final String? actorAccountId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? settledAt;

  /// Last time reconciliation compared this row with the provider.
  final DateTime? reconciledAt;
  const PaymentTransactionRow({
    required this.id,
    required this.patientId,
    this.invoiceId,
    required this.kind,
    required this.method,
    required this.status,
    required this.amount,
    required this.provider,
    required this.requestReference,
    this.providerReference,
    this.methodDescriptor,
    this.refundOfId,
    this.reason,
    this.failureReason,
    this.actorAccountId,
    required this.createdAt,
    required this.updatedAt,
    this.settledAt,
    this.reconciledAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    if (!nullToAbsent || invoiceId != null) {
      map['invoice_id'] = Variable<String>(invoiceId);
    }
    {
      map['kind'] = Variable<String>(
        $PaymentTransactionsTable.$converterkind.toSql(kind),
      );
    }
    {
      map['method'] = Variable<String>(
        $PaymentTransactionsTable.$convertermethod.toSql(method),
      );
    }
    {
      map['status'] = Variable<String>(
        $PaymentTransactionsTable.$converterstatus.toSql(status),
      );
    }
    map['amount'] = Variable<double>(amount);
    map['provider'] = Variable<String>(provider);
    map['request_reference'] = Variable<String>(requestReference);
    if (!nullToAbsent || providerReference != null) {
      map['provider_reference'] = Variable<String>(providerReference);
    }
    if (!nullToAbsent || methodDescriptor != null) {
      map['method_descriptor'] = Variable<String>(methodDescriptor);
    }
    if (!nullToAbsent || refundOfId != null) {
      map['refund_of_id'] = Variable<String>(refundOfId);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    if (!nullToAbsent || failureReason != null) {
      map['failure_reason'] = Variable<String>(failureReason);
    }
    if (!nullToAbsent || actorAccountId != null) {
      map['actor_account_id'] = Variable<String>(actorAccountId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || settledAt != null) {
      map['settled_at'] = Variable<DateTime>(settledAt);
    }
    if (!nullToAbsent || reconciledAt != null) {
      map['reconciled_at'] = Variable<DateTime>(reconciledAt);
    }
    return map;
  }

  PaymentTransactionsCompanion toCompanion(bool nullToAbsent) {
    return PaymentTransactionsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      invoiceId: invoiceId == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceId),
      kind: Value(kind),
      method: Value(method),
      status: Value(status),
      amount: Value(amount),
      provider: Value(provider),
      requestReference: Value(requestReference),
      providerReference: providerReference == null && nullToAbsent
          ? const Value.absent()
          : Value(providerReference),
      methodDescriptor: methodDescriptor == null && nullToAbsent
          ? const Value.absent()
          : Value(methodDescriptor),
      refundOfId: refundOfId == null && nullToAbsent
          ? const Value.absent()
          : Value(refundOfId),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      failureReason: failureReason == null && nullToAbsent
          ? const Value.absent()
          : Value(failureReason),
      actorAccountId: actorAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorAccountId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      settledAt: settledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(settledAt),
      reconciledAt: reconciledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reconciledAt),
    );
  }

  factory PaymentTransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentTransactionRow(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      invoiceId: serializer.fromJson<String?>(json['invoiceId']),
      kind: $PaymentTransactionsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      method: $PaymentTransactionsTable.$convertermethod.fromJson(
        serializer.fromJson<String>(json['method']),
      ),
      status: $PaymentTransactionsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      amount: serializer.fromJson<double>(json['amount']),
      provider: serializer.fromJson<String>(json['provider']),
      requestReference: serializer.fromJson<String>(json['requestReference']),
      providerReference: serializer.fromJson<String?>(
        json['providerReference'],
      ),
      methodDescriptor: serializer.fromJson<String?>(json['methodDescriptor']),
      refundOfId: serializer.fromJson<String?>(json['refundOfId']),
      reason: serializer.fromJson<String?>(json['reason']),
      failureReason: serializer.fromJson<String?>(json['failureReason']),
      actorAccountId: serializer.fromJson<String?>(json['actorAccountId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      settledAt: serializer.fromJson<DateTime?>(json['settledAt']),
      reconciledAt: serializer.fromJson<DateTime?>(json['reconciledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'invoiceId': serializer.toJson<String?>(invoiceId),
      'kind': serializer.toJson<String>(
        $PaymentTransactionsTable.$converterkind.toJson(kind),
      ),
      'method': serializer.toJson<String>(
        $PaymentTransactionsTable.$convertermethod.toJson(method),
      ),
      'status': serializer.toJson<String>(
        $PaymentTransactionsTable.$converterstatus.toJson(status),
      ),
      'amount': serializer.toJson<double>(amount),
      'provider': serializer.toJson<String>(provider),
      'requestReference': serializer.toJson<String>(requestReference),
      'providerReference': serializer.toJson<String?>(providerReference),
      'methodDescriptor': serializer.toJson<String?>(methodDescriptor),
      'refundOfId': serializer.toJson<String?>(refundOfId),
      'reason': serializer.toJson<String?>(reason),
      'failureReason': serializer.toJson<String?>(failureReason),
      'actorAccountId': serializer.toJson<String?>(actorAccountId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'settledAt': serializer.toJson<DateTime?>(settledAt),
      'reconciledAt': serializer.toJson<DateTime?>(reconciledAt),
    };
  }

  PaymentTransactionRow copyWith({
    String? id,
    String? patientId,
    Value<String?> invoiceId = const Value.absent(),
    PaymentKind? kind,
    PaymentMethodKind? method,
    PaymentStatus? status,
    double? amount,
    String? provider,
    String? requestReference,
    Value<String?> providerReference = const Value.absent(),
    Value<String?> methodDescriptor = const Value.absent(),
    Value<String?> refundOfId = const Value.absent(),
    Value<String?> reason = const Value.absent(),
    Value<String?> failureReason = const Value.absent(),
    Value<String?> actorAccountId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> settledAt = const Value.absent(),
    Value<DateTime?> reconciledAt = const Value.absent(),
  }) => PaymentTransactionRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    invoiceId: invoiceId.present ? invoiceId.value : this.invoiceId,
    kind: kind ?? this.kind,
    method: method ?? this.method,
    status: status ?? this.status,
    amount: amount ?? this.amount,
    provider: provider ?? this.provider,
    requestReference: requestReference ?? this.requestReference,
    providerReference: providerReference.present
        ? providerReference.value
        : this.providerReference,
    methodDescriptor: methodDescriptor.present
        ? methodDescriptor.value
        : this.methodDescriptor,
    refundOfId: refundOfId.present ? refundOfId.value : this.refundOfId,
    reason: reason.present ? reason.value : this.reason,
    failureReason: failureReason.present
        ? failureReason.value
        : this.failureReason,
    actorAccountId: actorAccountId.present
        ? actorAccountId.value
        : this.actorAccountId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    settledAt: settledAt.present ? settledAt.value : this.settledAt,
    reconciledAt: reconciledAt.present ? reconciledAt.value : this.reconciledAt,
  );
  PaymentTransactionRow copyWithCompanion(PaymentTransactionsCompanion data) {
    return PaymentTransactionRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      kind: data.kind.present ? data.kind.value : this.kind,
      method: data.method.present ? data.method.value : this.method,
      status: data.status.present ? data.status.value : this.status,
      amount: data.amount.present ? data.amount.value : this.amount,
      provider: data.provider.present ? data.provider.value : this.provider,
      requestReference: data.requestReference.present
          ? data.requestReference.value
          : this.requestReference,
      providerReference: data.providerReference.present
          ? data.providerReference.value
          : this.providerReference,
      methodDescriptor: data.methodDescriptor.present
          ? data.methodDescriptor.value
          : this.methodDescriptor,
      refundOfId: data.refundOfId.present
          ? data.refundOfId.value
          : this.refundOfId,
      reason: data.reason.present ? data.reason.value : this.reason,
      failureReason: data.failureReason.present
          ? data.failureReason.value
          : this.failureReason,
      actorAccountId: data.actorAccountId.present
          ? data.actorAccountId.value
          : this.actorAccountId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      settledAt: data.settledAt.present ? data.settledAt.value : this.settledAt,
      reconciledAt: data.reconciledAt.present
          ? data.reconciledAt.value
          : this.reconciledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentTransactionRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('kind: $kind, ')
          ..write('method: $method, ')
          ..write('status: $status, ')
          ..write('amount: $amount, ')
          ..write('provider: $provider, ')
          ..write('requestReference: $requestReference, ')
          ..write('providerReference: $providerReference, ')
          ..write('methodDescriptor: $methodDescriptor, ')
          ..write('refundOfId: $refundOfId, ')
          ..write('reason: $reason, ')
          ..write('failureReason: $failureReason, ')
          ..write('actorAccountId: $actorAccountId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('settledAt: $settledAt, ')
          ..write('reconciledAt: $reconciledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    invoiceId,
    kind,
    method,
    status,
    amount,
    provider,
    requestReference,
    providerReference,
    methodDescriptor,
    refundOfId,
    reason,
    failureReason,
    actorAccountId,
    createdAt,
    updatedAt,
    settledAt,
    reconciledAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentTransactionRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.invoiceId == this.invoiceId &&
          other.kind == this.kind &&
          other.method == this.method &&
          other.status == this.status &&
          other.amount == this.amount &&
          other.provider == this.provider &&
          other.requestReference == this.requestReference &&
          other.providerReference == this.providerReference &&
          other.methodDescriptor == this.methodDescriptor &&
          other.refundOfId == this.refundOfId &&
          other.reason == this.reason &&
          other.failureReason == this.failureReason &&
          other.actorAccountId == this.actorAccountId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.settledAt == this.settledAt &&
          other.reconciledAt == this.reconciledAt);
}

class PaymentTransactionsCompanion
    extends UpdateCompanion<PaymentTransactionRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String?> invoiceId;
  final Value<PaymentKind> kind;
  final Value<PaymentMethodKind> method;
  final Value<PaymentStatus> status;
  final Value<double> amount;
  final Value<String> provider;
  final Value<String> requestReference;
  final Value<String?> providerReference;
  final Value<String?> methodDescriptor;
  final Value<String?> refundOfId;
  final Value<String?> reason;
  final Value<String?> failureReason;
  final Value<String?> actorAccountId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> settledAt;
  final Value<DateTime?> reconciledAt;
  final Value<int> rowid;
  const PaymentTransactionsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.kind = const Value.absent(),
    this.method = const Value.absent(),
    this.status = const Value.absent(),
    this.amount = const Value.absent(),
    this.provider = const Value.absent(),
    this.requestReference = const Value.absent(),
    this.providerReference = const Value.absent(),
    this.methodDescriptor = const Value.absent(),
    this.refundOfId = const Value.absent(),
    this.reason = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.actorAccountId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.settledAt = const Value.absent(),
    this.reconciledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentTransactionsCompanion.insert({
    required String id,
    required String patientId,
    this.invoiceId = const Value.absent(),
    required PaymentKind kind,
    required PaymentMethodKind method,
    this.status = const Value.absent(),
    required double amount,
    required String provider,
    required String requestReference,
    this.providerReference = const Value.absent(),
    this.methodDescriptor = const Value.absent(),
    this.refundOfId = const Value.absent(),
    this.reason = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.actorAccountId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.settledAt = const Value.absent(),
    this.reconciledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       kind = Value(kind),
       method = Value(method),
       amount = Value(amount),
       provider = Value(provider),
       requestReference = Value(requestReference),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PaymentTransactionRow> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? invoiceId,
    Expression<String>? kind,
    Expression<String>? method,
    Expression<String>? status,
    Expression<double>? amount,
    Expression<String>? provider,
    Expression<String>? requestReference,
    Expression<String>? providerReference,
    Expression<String>? methodDescriptor,
    Expression<String>? refundOfId,
    Expression<String>? reason,
    Expression<String>? failureReason,
    Expression<String>? actorAccountId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? settledAt,
    Expression<DateTime>? reconciledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (kind != null) 'kind': kind,
      if (method != null) 'method': method,
      if (status != null) 'status': status,
      if (amount != null) 'amount': amount,
      if (provider != null) 'provider': provider,
      if (requestReference != null) 'request_reference': requestReference,
      if (providerReference != null) 'provider_reference': providerReference,
      if (methodDescriptor != null) 'method_descriptor': methodDescriptor,
      if (refundOfId != null) 'refund_of_id': refundOfId,
      if (reason != null) 'reason': reason,
      if (failureReason != null) 'failure_reason': failureReason,
      if (actorAccountId != null) 'actor_account_id': actorAccountId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (settledAt != null) 'settled_at': settledAt,
      if (reconciledAt != null) 'reconciled_at': reconciledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String?>? invoiceId,
    Value<PaymentKind>? kind,
    Value<PaymentMethodKind>? method,
    Value<PaymentStatus>? status,
    Value<double>? amount,
    Value<String>? provider,
    Value<String>? requestReference,
    Value<String?>? providerReference,
    Value<String?>? methodDescriptor,
    Value<String?>? refundOfId,
    Value<String?>? reason,
    Value<String?>? failureReason,
    Value<String?>? actorAccountId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? settledAt,
    Value<DateTime?>? reconciledAt,
    Value<int>? rowid,
  }) {
    return PaymentTransactionsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      invoiceId: invoiceId ?? this.invoiceId,
      kind: kind ?? this.kind,
      method: method ?? this.method,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      provider: provider ?? this.provider,
      requestReference: requestReference ?? this.requestReference,
      providerReference: providerReference ?? this.providerReference,
      methodDescriptor: methodDescriptor ?? this.methodDescriptor,
      refundOfId: refundOfId ?? this.refundOfId,
      reason: reason ?? this.reason,
      failureReason: failureReason ?? this.failureReason,
      actorAccountId: actorAccountId ?? this.actorAccountId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settledAt: settledAt ?? this.settledAt,
      reconciledAt: reconciledAt ?? this.reconciledAt,
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
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $PaymentTransactionsTable.$converterkind.toSql(kind.value),
      );
    }
    if (method.present) {
      map['method'] = Variable<String>(
        $PaymentTransactionsTable.$convertermethod.toSql(method.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $PaymentTransactionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (requestReference.present) {
      map['request_reference'] = Variable<String>(requestReference.value);
    }
    if (providerReference.present) {
      map['provider_reference'] = Variable<String>(providerReference.value);
    }
    if (methodDescriptor.present) {
      map['method_descriptor'] = Variable<String>(methodDescriptor.value);
    }
    if (refundOfId.present) {
      map['refund_of_id'] = Variable<String>(refundOfId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (failureReason.present) {
      map['failure_reason'] = Variable<String>(failureReason.value);
    }
    if (actorAccountId.present) {
      map['actor_account_id'] = Variable<String>(actorAccountId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (settledAt.present) {
      map['settled_at'] = Variable<DateTime>(settledAt.value);
    }
    if (reconciledAt.present) {
      map['reconciled_at'] = Variable<DateTime>(reconciledAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('kind: $kind, ')
          ..write('method: $method, ')
          ..write('status: $status, ')
          ..write('amount: $amount, ')
          ..write('provider: $provider, ')
          ..write('requestReference: $requestReference, ')
          ..write('providerReference: $providerReference, ')
          ..write('methodDescriptor: $methodDescriptor, ')
          ..write('refundOfId: $refundOfId, ')
          ..write('reason: $reason, ')
          ..write('failureReason: $failureReason, ')
          ..write('actorAccountId: $actorAccountId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('settledAt: $settledAt, ')
          ..write('reconciledAt: $reconciledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SimulatedGatewayChargesTable extends SimulatedGatewayCharges
    with TableInfo<$SimulatedGatewayChargesTable, SimulatedGatewayChargeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SimulatedGatewayChargesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerReferenceMeta = const VerificationMeta(
    'providerReference',
  );
  @override
  late final GeneratedColumn<String> providerReference =
      GeneratedColumn<String>(
        'provider_reference',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountFilsMeta = const VerificationMeta(
    'amountFils',
  );
  @override
  late final GeneratedColumn<int> amountFils = GeneratedColumn<int>(
    'amount_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _declineCodeMeta = const VerificationMeta(
    'declineCode',
  );
  @override
  late final GeneratedColumn<String> declineCode = GeneratedColumn<String>(
    'decline_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentProviderReferenceMeta =
      const VerificationMeta('parentProviderReference');
  @override
  late final GeneratedColumn<String> parentProviderReference =
      GeneratedColumn<String>(
        'parent_provider_reference',
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
    reference,
    providerReference,
    operation,
    status,
    amountFils,
    declineCode,
    parentProviderReference,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'simulated_gateway_charges';
  @override
  VerificationContext validateIntegrity(
    Insertable<SimulatedGatewayChargeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    } else if (isInserting) {
      context.missing(_referenceMeta);
    }
    if (data.containsKey('provider_reference')) {
      context.handle(
        _providerReferenceMeta,
        providerReference.isAcceptableOrUnknown(
          data['provider_reference']!,
          _providerReferenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerReferenceMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('amount_fils')) {
      context.handle(
        _amountFilsMeta,
        amountFils.isAcceptableOrUnknown(data['amount_fils']!, _amountFilsMeta),
      );
    } else if (isInserting) {
      context.missing(_amountFilsMeta);
    }
    if (data.containsKey('decline_code')) {
      context.handle(
        _declineCodeMeta,
        declineCode.isAcceptableOrUnknown(
          data['decline_code']!,
          _declineCodeMeta,
        ),
      );
    }
    if (data.containsKey('parent_provider_reference')) {
      context.handle(
        _parentProviderReferenceMeta,
        parentProviderReference.isAcceptableOrUnknown(
          data['parent_provider_reference']!,
          _parentProviderReferenceMeta,
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
  Set<GeneratedColumn> get $primaryKey => {reference};
  @override
  SimulatedGatewayChargeRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SimulatedGatewayChargeRow(
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      providerReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_reference'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      amountFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_fils'],
      )!,
      declineCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decline_code'],
      ),
      parentProviderReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_provider_reference'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SimulatedGatewayChargesTable createAlias(String alias) {
    return $SimulatedGatewayChargesTable(attachedDatabase, alias);
  }
}

class SimulatedGatewayChargeRow extends DataClass
    implements Insertable<SimulatedGatewayChargeRow> {
  /// The app's request reference — the provider's idempotency key.
  final String reference;
  final String providerReference;

  /// `charge` or `refund`.
  final String operation;

  /// `captured`, `declined` or `refunded`.
  final String status;
  final int amountFils;
  final String? declineCode;

  /// For a refund: the provider reference of the charge it returns.
  final String? parentProviderReference;
  final DateTime createdAt;
  const SimulatedGatewayChargeRow({
    required this.reference,
    required this.providerReference,
    required this.operation,
    required this.status,
    required this.amountFils,
    this.declineCode,
    this.parentProviderReference,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['reference'] = Variable<String>(reference);
    map['provider_reference'] = Variable<String>(providerReference);
    map['operation'] = Variable<String>(operation);
    map['status'] = Variable<String>(status);
    map['amount_fils'] = Variable<int>(amountFils);
    if (!nullToAbsent || declineCode != null) {
      map['decline_code'] = Variable<String>(declineCode);
    }
    if (!nullToAbsent || parentProviderReference != null) {
      map['parent_provider_reference'] = Variable<String>(
        parentProviderReference,
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SimulatedGatewayChargesCompanion toCompanion(bool nullToAbsent) {
    return SimulatedGatewayChargesCompanion(
      reference: Value(reference),
      providerReference: Value(providerReference),
      operation: Value(operation),
      status: Value(status),
      amountFils: Value(amountFils),
      declineCode: declineCode == null && nullToAbsent
          ? const Value.absent()
          : Value(declineCode),
      parentProviderReference: parentProviderReference == null && nullToAbsent
          ? const Value.absent()
          : Value(parentProviderReference),
      createdAt: Value(createdAt),
    );
  }

  factory SimulatedGatewayChargeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SimulatedGatewayChargeRow(
      reference: serializer.fromJson<String>(json['reference']),
      providerReference: serializer.fromJson<String>(json['providerReference']),
      operation: serializer.fromJson<String>(json['operation']),
      status: serializer.fromJson<String>(json['status']),
      amountFils: serializer.fromJson<int>(json['amountFils']),
      declineCode: serializer.fromJson<String?>(json['declineCode']),
      parentProviderReference: serializer.fromJson<String?>(
        json['parentProviderReference'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'reference': serializer.toJson<String>(reference),
      'providerReference': serializer.toJson<String>(providerReference),
      'operation': serializer.toJson<String>(operation),
      'status': serializer.toJson<String>(status),
      'amountFils': serializer.toJson<int>(amountFils),
      'declineCode': serializer.toJson<String?>(declineCode),
      'parentProviderReference': serializer.toJson<String?>(
        parentProviderReference,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SimulatedGatewayChargeRow copyWith({
    String? reference,
    String? providerReference,
    String? operation,
    String? status,
    int? amountFils,
    Value<String?> declineCode = const Value.absent(),
    Value<String?> parentProviderReference = const Value.absent(),
    DateTime? createdAt,
  }) => SimulatedGatewayChargeRow(
    reference: reference ?? this.reference,
    providerReference: providerReference ?? this.providerReference,
    operation: operation ?? this.operation,
    status: status ?? this.status,
    amountFils: amountFils ?? this.amountFils,
    declineCode: declineCode.present ? declineCode.value : this.declineCode,
    parentProviderReference: parentProviderReference.present
        ? parentProviderReference.value
        : this.parentProviderReference,
    createdAt: createdAt ?? this.createdAt,
  );
  SimulatedGatewayChargeRow copyWithCompanion(
    SimulatedGatewayChargesCompanion data,
  ) {
    return SimulatedGatewayChargeRow(
      reference: data.reference.present ? data.reference.value : this.reference,
      providerReference: data.providerReference.present
          ? data.providerReference.value
          : this.providerReference,
      operation: data.operation.present ? data.operation.value : this.operation,
      status: data.status.present ? data.status.value : this.status,
      amountFils: data.amountFils.present
          ? data.amountFils.value
          : this.amountFils,
      declineCode: data.declineCode.present
          ? data.declineCode.value
          : this.declineCode,
      parentProviderReference: data.parentProviderReference.present
          ? data.parentProviderReference.value
          : this.parentProviderReference,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SimulatedGatewayChargeRow(')
          ..write('reference: $reference, ')
          ..write('providerReference: $providerReference, ')
          ..write('operation: $operation, ')
          ..write('status: $status, ')
          ..write('amountFils: $amountFils, ')
          ..write('declineCode: $declineCode, ')
          ..write('parentProviderReference: $parentProviderReference, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    reference,
    providerReference,
    operation,
    status,
    amountFils,
    declineCode,
    parentProviderReference,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SimulatedGatewayChargeRow &&
          other.reference == this.reference &&
          other.providerReference == this.providerReference &&
          other.operation == this.operation &&
          other.status == this.status &&
          other.amountFils == this.amountFils &&
          other.declineCode == this.declineCode &&
          other.parentProviderReference == this.parentProviderReference &&
          other.createdAt == this.createdAt);
}

class SimulatedGatewayChargesCompanion
    extends UpdateCompanion<SimulatedGatewayChargeRow> {
  final Value<String> reference;
  final Value<String> providerReference;
  final Value<String> operation;
  final Value<String> status;
  final Value<int> amountFils;
  final Value<String?> declineCode;
  final Value<String?> parentProviderReference;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SimulatedGatewayChargesCompanion({
    this.reference = const Value.absent(),
    this.providerReference = const Value.absent(),
    this.operation = const Value.absent(),
    this.status = const Value.absent(),
    this.amountFils = const Value.absent(),
    this.declineCode = const Value.absent(),
    this.parentProviderReference = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SimulatedGatewayChargesCompanion.insert({
    required String reference,
    required String providerReference,
    required String operation,
    required String status,
    required int amountFils,
    this.declineCode = const Value.absent(),
    this.parentProviderReference = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : reference = Value(reference),
       providerReference = Value(providerReference),
       operation = Value(operation),
       status = Value(status),
       amountFils = Value(amountFils),
       createdAt = Value(createdAt);
  static Insertable<SimulatedGatewayChargeRow> custom({
    Expression<String>? reference,
    Expression<String>? providerReference,
    Expression<String>? operation,
    Expression<String>? status,
    Expression<int>? amountFils,
    Expression<String>? declineCode,
    Expression<String>? parentProviderReference,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (reference != null) 'reference': reference,
      if (providerReference != null) 'provider_reference': providerReference,
      if (operation != null) 'operation': operation,
      if (status != null) 'status': status,
      if (amountFils != null) 'amount_fils': amountFils,
      if (declineCode != null) 'decline_code': declineCode,
      if (parentProviderReference != null)
        'parent_provider_reference': parentProviderReference,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SimulatedGatewayChargesCompanion copyWith({
    Value<String>? reference,
    Value<String>? providerReference,
    Value<String>? operation,
    Value<String>? status,
    Value<int>? amountFils,
    Value<String?>? declineCode,
    Value<String?>? parentProviderReference,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SimulatedGatewayChargesCompanion(
      reference: reference ?? this.reference,
      providerReference: providerReference ?? this.providerReference,
      operation: operation ?? this.operation,
      status: status ?? this.status,
      amountFils: amountFils ?? this.amountFils,
      declineCode: declineCode ?? this.declineCode,
      parentProviderReference:
          parentProviderReference ?? this.parentProviderReference,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (providerReference.present) {
      map['provider_reference'] = Variable<String>(providerReference.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (amountFils.present) {
      map['amount_fils'] = Variable<int>(amountFils.value);
    }
    if (declineCode.present) {
      map['decline_code'] = Variable<String>(declineCode.value);
    }
    if (parentProviderReference.present) {
      map['parent_provider_reference'] = Variable<String>(
        parentProviderReference.value,
      );
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
    return (StringBuffer('SimulatedGatewayChargesCompanion(')
          ..write('reference: $reference, ')
          ..write('providerReference: $providerReference, ')
          ..write('operation: $operation, ')
          ..write('status: $status, ')
          ..write('amountFils: $amountFils, ')
          ..write('declineCode: $declineCode, ')
          ..write('parentProviderReference: $parentProviderReference, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FamilyLinksTable extends FamilyLinks
    with TableInfo<$FamilyLinksTable, FamilyLinkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerPatientIdMeta = const VerificationMeta(
    'ownerPatientId',
  );
  @override
  late final GeneratedColumn<String> ownerPatientId = GeneratedColumn<String>(
    'owner_patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _viewerPatientIdMeta = const VerificationMeta(
    'viewerPatientId',
  );
  @override
  late final GeneratedColumn<String> viewerPatientId = GeneratedColumn<String>(
    'viewer_patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<FamilyLinkPermission, String>
  permission = GeneratedColumn<String>(
    'permission',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<FamilyLinkPermission>($FamilyLinksTable.$converterpermission);
  @override
  late final GeneratedColumnWithTypeConverter<FamilyLinkStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<FamilyLinkStatus>($FamilyLinksTable.$converterstatus);
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
  static const VerificationMeta _respondedAtMeta = const VerificationMeta(
    'respondedAt',
  );
  @override
  late final GeneratedColumn<DateTime> respondedAt = GeneratedColumn<DateTime>(
    'responded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerPatientId,
    viewerPatientId,
    permission,
    status,
    createdAt,
    respondedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyLinkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_patient_id')) {
      context.handle(
        _ownerPatientIdMeta,
        ownerPatientId.isAcceptableOrUnknown(
          data['owner_patient_id']!,
          _ownerPatientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerPatientIdMeta);
    }
    if (data.containsKey('viewer_patient_id')) {
      context.handle(
        _viewerPatientIdMeta,
        viewerPatientId.isAcceptableOrUnknown(
          data['viewer_patient_id']!,
          _viewerPatientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_viewerPatientIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('responded_at')) {
      context.handle(
        _respondedAtMeta,
        respondedAt.isAcceptableOrUnknown(
          data['responded_at']!,
          _respondedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyLinkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyLinkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerPatientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_patient_id'],
      )!,
      viewerPatientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}viewer_patient_id'],
      )!,
      permission: $FamilyLinksTable.$converterpermission.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}permission'],
        )!,
      ),
      status: $FamilyLinksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      respondedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}responded_at'],
      ),
    );
  }

  @override
  $FamilyLinksTable createAlias(String alias) {
    return $FamilyLinksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FamilyLinkPermission, String, String>
  $converterpermission = const EnumNameConverter<FamilyLinkPermission>(
    FamilyLinkPermission.values,
  );
  static JsonTypeConverter2<FamilyLinkStatus, String, String> $converterstatus =
      const EnumNameConverter<FamilyLinkStatus>(FamilyLinkStatus.values);
}

class FamilyLinkRow extends DataClass implements Insertable<FamilyLinkRow> {
  final String id;

  /// The account whose data is being shared.
  final String ownerPatientId;

  /// The account being granted access.
  final String viewerPatientId;
  final FamilyLinkPermission permission;
  final FamilyLinkStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  const FamilyLinkRow({
    required this.id,
    required this.ownerPatientId,
    required this.viewerPatientId,
    required this.permission,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_patient_id'] = Variable<String>(ownerPatientId);
    map['viewer_patient_id'] = Variable<String>(viewerPatientId);
    {
      map['permission'] = Variable<String>(
        $FamilyLinksTable.$converterpermission.toSql(permission),
      );
    }
    {
      map['status'] = Variable<String>(
        $FamilyLinksTable.$converterstatus.toSql(status),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || respondedAt != null) {
      map['responded_at'] = Variable<DateTime>(respondedAt);
    }
    return map;
  }

  FamilyLinksCompanion toCompanion(bool nullToAbsent) {
    return FamilyLinksCompanion(
      id: Value(id),
      ownerPatientId: Value(ownerPatientId),
      viewerPatientId: Value(viewerPatientId),
      permission: Value(permission),
      status: Value(status),
      createdAt: Value(createdAt),
      respondedAt: respondedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(respondedAt),
    );
  }

  factory FamilyLinkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyLinkRow(
      id: serializer.fromJson<String>(json['id']),
      ownerPatientId: serializer.fromJson<String>(json['ownerPatientId']),
      viewerPatientId: serializer.fromJson<String>(json['viewerPatientId']),
      permission: $FamilyLinksTable.$converterpermission.fromJson(
        serializer.fromJson<String>(json['permission']),
      ),
      status: $FamilyLinksTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      respondedAt: serializer.fromJson<DateTime?>(json['respondedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerPatientId': serializer.toJson<String>(ownerPatientId),
      'viewerPatientId': serializer.toJson<String>(viewerPatientId),
      'permission': serializer.toJson<String>(
        $FamilyLinksTable.$converterpermission.toJson(permission),
      ),
      'status': serializer.toJson<String>(
        $FamilyLinksTable.$converterstatus.toJson(status),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'respondedAt': serializer.toJson<DateTime?>(respondedAt),
    };
  }

  FamilyLinkRow copyWith({
    String? id,
    String? ownerPatientId,
    String? viewerPatientId,
    FamilyLinkPermission? permission,
    FamilyLinkStatus? status,
    DateTime? createdAt,
    Value<DateTime?> respondedAt = const Value.absent(),
  }) => FamilyLinkRow(
    id: id ?? this.id,
    ownerPatientId: ownerPatientId ?? this.ownerPatientId,
    viewerPatientId: viewerPatientId ?? this.viewerPatientId,
    permission: permission ?? this.permission,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    respondedAt: respondedAt.present ? respondedAt.value : this.respondedAt,
  );
  FamilyLinkRow copyWithCompanion(FamilyLinksCompanion data) {
    return FamilyLinkRow(
      id: data.id.present ? data.id.value : this.id,
      ownerPatientId: data.ownerPatientId.present
          ? data.ownerPatientId.value
          : this.ownerPatientId,
      viewerPatientId: data.viewerPatientId.present
          ? data.viewerPatientId.value
          : this.viewerPatientId,
      permission: data.permission.present
          ? data.permission.value
          : this.permission,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      respondedAt: data.respondedAt.present
          ? data.respondedAt.value
          : this.respondedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyLinkRow(')
          ..write('id: $id, ')
          ..write('ownerPatientId: $ownerPatientId, ')
          ..write('viewerPatientId: $viewerPatientId, ')
          ..write('permission: $permission, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('respondedAt: $respondedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerPatientId,
    viewerPatientId,
    permission,
    status,
    createdAt,
    respondedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyLinkRow &&
          other.id == this.id &&
          other.ownerPatientId == this.ownerPatientId &&
          other.viewerPatientId == this.viewerPatientId &&
          other.permission == this.permission &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.respondedAt == this.respondedAt);
}

class FamilyLinksCompanion extends UpdateCompanion<FamilyLinkRow> {
  final Value<String> id;
  final Value<String> ownerPatientId;
  final Value<String> viewerPatientId;
  final Value<FamilyLinkPermission> permission;
  final Value<FamilyLinkStatus> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> respondedAt;
  final Value<int> rowid;
  const FamilyLinksCompanion({
    this.id = const Value.absent(),
    this.ownerPatientId = const Value.absent(),
    this.viewerPatientId = const Value.absent(),
    this.permission = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.respondedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FamilyLinksCompanion.insert({
    required String id,
    required String ownerPatientId,
    required String viewerPatientId,
    required FamilyLinkPermission permission,
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.respondedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerPatientId = Value(ownerPatientId),
       viewerPatientId = Value(viewerPatientId),
       permission = Value(permission);
  static Insertable<FamilyLinkRow> custom({
    Expression<String>? id,
    Expression<String>? ownerPatientId,
    Expression<String>? viewerPatientId,
    Expression<String>? permission,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? respondedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerPatientId != null) 'owner_patient_id': ownerPatientId,
      if (viewerPatientId != null) 'viewer_patient_id': viewerPatientId,
      if (permission != null) 'permission': permission,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (respondedAt != null) 'responded_at': respondedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FamilyLinksCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerPatientId,
    Value<String>? viewerPatientId,
    Value<FamilyLinkPermission>? permission,
    Value<FamilyLinkStatus>? status,
    Value<DateTime>? createdAt,
    Value<DateTime?>? respondedAt,
    Value<int>? rowid,
  }) {
    return FamilyLinksCompanion(
      id: id ?? this.id,
      ownerPatientId: ownerPatientId ?? this.ownerPatientId,
      viewerPatientId: viewerPatientId ?? this.viewerPatientId,
      permission: permission ?? this.permission,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerPatientId.present) {
      map['owner_patient_id'] = Variable<String>(ownerPatientId.value);
    }
    if (viewerPatientId.present) {
      map['viewer_patient_id'] = Variable<String>(viewerPatientId.value);
    }
    if (permission.present) {
      map['permission'] = Variable<String>(
        $FamilyLinksTable.$converterpermission.toSql(permission.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $FamilyLinksTable.$converterstatus.toSql(status.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (respondedAt.present) {
      map['responded_at'] = Variable<DateTime>(respondedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyLinksCompanion(')
          ..write('id: $id, ')
          ..write('ownerPatientId: $ownerPatientId, ')
          ..write('viewerPatientId: $viewerPatientId, ')
          ..write('permission: $permission, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('respondedAt: $respondedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationsTable extends Notifications
    with TableInfo<$NotificationsTable, NotificationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipientIdMeta = const VerificationMeta(
    'recipientId',
  );
  @override
  late final GeneratedColumn<String> recipientId = GeneratedColumn<String>(
    'recipient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<NotificationCategory, String>
  category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<NotificationCategory>($NotificationsTable.$convertercategory);
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deepLinkMeta = const VerificationMeta(
    'deepLink',
  );
  @override
  late final GeneratedColumn<String> deepLink = GeneratedColumn<String>(
    'deep_link',
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
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
    'read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceEventIdMeta = const VerificationMeta(
    'sourceEventId',
  );
  @override
  late final GeneratedColumn<String> sourceEventId = GeneratedColumn<String>(
    'source_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recipientId,
    category,
    title,
    body,
    deepLink,
    createdAt,
    readAt,
    sourceEventId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipient_id')) {
      context.handle(
        _recipientIdMeta,
        recipientId.isAcceptableOrUnknown(
          data['recipient_id']!,
          _recipientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recipientIdMeta);
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
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('deep_link')) {
      context.handle(
        _deepLinkMeta,
        deepLink.isAcceptableOrUnknown(data['deep_link']!, _deepLinkMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    }
    if (data.containsKey('source_event_id')) {
      context.handle(
        _sourceEventIdMeta,
        sourceEventId.isAcceptableOrUnknown(
          data['source_event_id']!,
          _sourceEventIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recipientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_id'],
      )!,
      category: $NotificationsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      deepLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deep_link'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}read_at'],
      ),
      sourceEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_event_id'],
      ),
    );
  }

  @override
  $NotificationsTable createAlias(String alias) {
    return $NotificationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<NotificationCategory, String, String>
  $convertercategory = const EnumNameConverter<NotificationCategory>(
    NotificationCategory.values,
  );
}

class NotificationRow extends DataClass implements Insertable<NotificationRow> {
  final String id;
  final String recipientId;
  final NotificationCategory category;
  final String title;
  final String body;

  /// Optional in-app route to open when the notification is tapped
  /// (e.g. `/patient/appointments`). Null = detail view only.
  final String? deepLink;
  final DateTime createdAt;

  /// Null until the recipient opens it.
  final DateTime? readAt;

  /// The outbox event that delivered this row, when it came through the
  /// outbox. Unique (a partial index, schema v19), so a redelivered event can
  /// never notify twice.
  final String? sourceEventId;
  const NotificationRow({
    required this.id,
    required this.recipientId,
    required this.category,
    required this.title,
    required this.body,
    this.deepLink,
    required this.createdAt,
    this.readAt,
    this.sourceEventId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipient_id'] = Variable<String>(recipientId);
    {
      map['category'] = Variable<String>(
        $NotificationsTable.$convertercategory.toSql(category),
      );
    }
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || deepLink != null) {
      map['deep_link'] = Variable<String>(deepLink);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<DateTime>(readAt);
    }
    if (!nullToAbsent || sourceEventId != null) {
      map['source_event_id'] = Variable<String>(sourceEventId);
    }
    return map;
  }

  NotificationsCompanion toCompanion(bool nullToAbsent) {
    return NotificationsCompanion(
      id: Value(id),
      recipientId: Value(recipientId),
      category: Value(category),
      title: Value(title),
      body: Value(body),
      deepLink: deepLink == null && nullToAbsent
          ? const Value.absent()
          : Value(deepLink),
      createdAt: Value(createdAt),
      readAt: readAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readAt),
      sourceEventId: sourceEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceEventId),
    );
  }

  factory NotificationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationRow(
      id: serializer.fromJson<String>(json['id']),
      recipientId: serializer.fromJson<String>(json['recipientId']),
      category: $NotificationsTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      deepLink: serializer.fromJson<String?>(json['deepLink']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
      sourceEventId: serializer.fromJson<String?>(json['sourceEventId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipientId': serializer.toJson<String>(recipientId),
      'category': serializer.toJson<String>(
        $NotificationsTable.$convertercategory.toJson(category),
      ),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'deepLink': serializer.toJson<String?>(deepLink),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'readAt': serializer.toJson<DateTime?>(readAt),
      'sourceEventId': serializer.toJson<String?>(sourceEventId),
    };
  }

  NotificationRow copyWith({
    String? id,
    String? recipientId,
    NotificationCategory? category,
    String? title,
    String? body,
    Value<String?> deepLink = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> readAt = const Value.absent(),
    Value<String?> sourceEventId = const Value.absent(),
  }) => NotificationRow(
    id: id ?? this.id,
    recipientId: recipientId ?? this.recipientId,
    category: category ?? this.category,
    title: title ?? this.title,
    body: body ?? this.body,
    deepLink: deepLink.present ? deepLink.value : this.deepLink,
    createdAt: createdAt ?? this.createdAt,
    readAt: readAt.present ? readAt.value : this.readAt,
    sourceEventId: sourceEventId.present
        ? sourceEventId.value
        : this.sourceEventId,
  );
  NotificationRow copyWithCompanion(NotificationsCompanion data) {
    return NotificationRow(
      id: data.id.present ? data.id.value : this.id,
      recipientId: data.recipientId.present
          ? data.recipientId.value
          : this.recipientId,
      category: data.category.present ? data.category.value : this.category,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      deepLink: data.deepLink.present ? data.deepLink.value : this.deepLink,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      sourceEventId: data.sourceEventId.present
          ? data.sourceEventId.value
          : this.sourceEventId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationRow(')
          ..write('id: $id, ')
          ..write('recipientId: $recipientId, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('deepLink: $deepLink, ')
          ..write('createdAt: $createdAt, ')
          ..write('readAt: $readAt, ')
          ..write('sourceEventId: $sourceEventId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recipientId,
    category,
    title,
    body,
    deepLink,
    createdAt,
    readAt,
    sourceEventId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationRow &&
          other.id == this.id &&
          other.recipientId == this.recipientId &&
          other.category == this.category &&
          other.title == this.title &&
          other.body == this.body &&
          other.deepLink == this.deepLink &&
          other.createdAt == this.createdAt &&
          other.readAt == this.readAt &&
          other.sourceEventId == this.sourceEventId);
}

class NotificationsCompanion extends UpdateCompanion<NotificationRow> {
  final Value<String> id;
  final Value<String> recipientId;
  final Value<NotificationCategory> category;
  final Value<String> title;
  final Value<String> body;
  final Value<String?> deepLink;
  final Value<DateTime> createdAt;
  final Value<DateTime?> readAt;
  final Value<String?> sourceEventId;
  final Value<int> rowid;
  const NotificationsCompanion({
    this.id = const Value.absent(),
    this.recipientId = const Value.absent(),
    this.category = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.deepLink = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.sourceEventId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationsCompanion.insert({
    required String id,
    required String recipientId,
    required NotificationCategory category,
    required String title,
    required String body,
    this.deepLink = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.sourceEventId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recipientId = Value(recipientId),
       category = Value(category),
       title = Value(title),
       body = Value(body);
  static Insertable<NotificationRow> custom({
    Expression<String>? id,
    Expression<String>? recipientId,
    Expression<String>? category,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? deepLink,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? readAt,
    Expression<String>? sourceEventId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipientId != null) 'recipient_id': recipientId,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (deepLink != null) 'deep_link': deepLink,
      if (createdAt != null) 'created_at': createdAt,
      if (readAt != null) 'read_at': readAt,
      if (sourceEventId != null) 'source_event_id': sourceEventId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationsCompanion copyWith({
    Value<String>? id,
    Value<String>? recipientId,
    Value<NotificationCategory>? category,
    Value<String>? title,
    Value<String>? body,
    Value<String?>? deepLink,
    Value<DateTime>? createdAt,
    Value<DateTime?>? readAt,
    Value<String?>? sourceEventId,
    Value<int>? rowid,
  }) {
    return NotificationsCompanion(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      deepLink: deepLink ?? this.deepLink,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      sourceEventId: sourceEventId ?? this.sourceEventId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipientId.present) {
      map['recipient_id'] = Variable<String>(recipientId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $NotificationsTable.$convertercategory.toSql(category.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (deepLink.present) {
      map['deep_link'] = Variable<String>(deepLink.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    if (sourceEventId.present) {
      map['source_event_id'] = Variable<String>(sourceEventId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsCompanion(')
          ..write('id: $id, ')
          ..write('recipientId: $recipientId, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('deepLink: $deepLink, ')
          ..write('createdAt: $createdAt, ')
          ..write('readAt: $readAt, ')
          ..write('sourceEventId: $sourceEventId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SickLeaveCertificatesTable extends SickLeaveCertificates
    with TableInfo<$SickLeaveCertificatesTable, SickLeaveRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SickLeaveCertificatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _issuedByStaffIdMeta = const VerificationMeta(
    'issuedByStaffId',
  );
  @override
  late final GeneratedColumn<String> issuedByStaffId = GeneratedColumn<String>(
    'issued_by_staff_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _appointmentIdMeta = const VerificationMeta(
    'appointmentId',
  );
  @override
  late final GeneratedColumn<String> appointmentId = GeneratedColumn<String>(
    'appointment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES appointments (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _diagnosisMeta = const VerificationMeta(
    'diagnosis',
  );
  @override
  late final GeneratedColumn<String> diagnosis = GeneratedColumn<String>(
    'diagnosis',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 300,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromDateMeta = const VerificationMeta(
    'fromDate',
  );
  @override
  late final GeneratedColumn<DateTime> fromDate = GeneratedColumn<DateTime>(
    'from_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toDateMeta = const VerificationMeta('toDate');
  @override
  late final GeneratedColumn<DateTime> toDate = GeneratedColumn<DateTime>(
    'to_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
  static const VerificationMeta _issuedAtMeta = const VerificationMeta(
    'issuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> issuedAt = GeneratedColumn<DateTime>(
    'issued_at',
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
    issuedByStaffId,
    appointmentId,
    diagnosis,
    fromDate,
    toDate,
    notes,
    issuedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sick_leave_certificates';
  @override
  VerificationContext validateIntegrity(
    Insertable<SickLeaveRow> instance, {
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
    if (data.containsKey('issued_by_staff_id')) {
      context.handle(
        _issuedByStaffIdMeta,
        issuedByStaffId.isAcceptableOrUnknown(
          data['issued_by_staff_id']!,
          _issuedByStaffIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_issuedByStaffIdMeta);
    }
    if (data.containsKey('appointment_id')) {
      context.handle(
        _appointmentIdMeta,
        appointmentId.isAcceptableOrUnknown(
          data['appointment_id']!,
          _appointmentIdMeta,
        ),
      );
    }
    if (data.containsKey('diagnosis')) {
      context.handle(
        _diagnosisMeta,
        diagnosis.isAcceptableOrUnknown(data['diagnosis']!, _diagnosisMeta),
      );
    } else if (isInserting) {
      context.missing(_diagnosisMeta);
    }
    if (data.containsKey('from_date')) {
      context.handle(
        _fromDateMeta,
        fromDate.isAcceptableOrUnknown(data['from_date']!, _fromDateMeta),
      );
    } else if (isInserting) {
      context.missing(_fromDateMeta);
    }
    if (data.containsKey('to_date')) {
      context.handle(
        _toDateMeta,
        toDate.isAcceptableOrUnknown(data['to_date']!, _toDateMeta),
      );
    } else if (isInserting) {
      context.missing(_toDateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('issued_at')) {
      context.handle(
        _issuedAtMeta,
        issuedAt.isAcceptableOrUnknown(data['issued_at']!, _issuedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SickLeaveRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SickLeaveRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      issuedByStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issued_by_staff_id'],
      )!,
      appointmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appointment_id'],
      ),
      diagnosis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diagnosis'],
      )!,
      fromDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}from_date'],
      )!,
      toDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}to_date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      issuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}issued_at'],
      )!,
    );
  }

  @override
  $SickLeaveCertificatesTable createAlias(String alias) {
    return $SickLeaveCertificatesTable(attachedDatabase, alias);
  }
}

class SickLeaveRow extends DataClass implements Insertable<SickLeaveRow> {
  final String id;
  final String patientId;
  final String issuedByStaffId;

  /// The visit it was issued from, if any. Kept if the appointment is removed.
  final String? appointmentId;
  final String diagnosis;
  final DateTime fromDate;
  final DateTime toDate;
  final String? notes;
  final DateTime issuedAt;
  const SickLeaveRow({
    required this.id,
    required this.patientId,
    required this.issuedByStaffId,
    this.appointmentId,
    required this.diagnosis,
    required this.fromDate,
    required this.toDate,
    this.notes,
    required this.issuedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['issued_by_staff_id'] = Variable<String>(issuedByStaffId);
    if (!nullToAbsent || appointmentId != null) {
      map['appointment_id'] = Variable<String>(appointmentId);
    }
    map['diagnosis'] = Variable<String>(diagnosis);
    map['from_date'] = Variable<DateTime>(fromDate);
    map['to_date'] = Variable<DateTime>(toDate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['issued_at'] = Variable<DateTime>(issuedAt);
    return map;
  }

  SickLeaveCertificatesCompanion toCompanion(bool nullToAbsent) {
    return SickLeaveCertificatesCompanion(
      id: Value(id),
      patientId: Value(patientId),
      issuedByStaffId: Value(issuedByStaffId),
      appointmentId: appointmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(appointmentId),
      diagnosis: Value(diagnosis),
      fromDate: Value(fromDate),
      toDate: Value(toDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      issuedAt: Value(issuedAt),
    );
  }

  factory SickLeaveRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SickLeaveRow(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      issuedByStaffId: serializer.fromJson<String>(json['issuedByStaffId']),
      appointmentId: serializer.fromJson<String?>(json['appointmentId']),
      diagnosis: serializer.fromJson<String>(json['diagnosis']),
      fromDate: serializer.fromJson<DateTime>(json['fromDate']),
      toDate: serializer.fromJson<DateTime>(json['toDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      issuedAt: serializer.fromJson<DateTime>(json['issuedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'issuedByStaffId': serializer.toJson<String>(issuedByStaffId),
      'appointmentId': serializer.toJson<String?>(appointmentId),
      'diagnosis': serializer.toJson<String>(diagnosis),
      'fromDate': serializer.toJson<DateTime>(fromDate),
      'toDate': serializer.toJson<DateTime>(toDate),
      'notes': serializer.toJson<String?>(notes),
      'issuedAt': serializer.toJson<DateTime>(issuedAt),
    };
  }

  SickLeaveRow copyWith({
    String? id,
    String? patientId,
    String? issuedByStaffId,
    Value<String?> appointmentId = const Value.absent(),
    String? diagnosis,
    DateTime? fromDate,
    DateTime? toDate,
    Value<String?> notes = const Value.absent(),
    DateTime? issuedAt,
  }) => SickLeaveRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    issuedByStaffId: issuedByStaffId ?? this.issuedByStaffId,
    appointmentId: appointmentId.present
        ? appointmentId.value
        : this.appointmentId,
    diagnosis: diagnosis ?? this.diagnosis,
    fromDate: fromDate ?? this.fromDate,
    toDate: toDate ?? this.toDate,
    notes: notes.present ? notes.value : this.notes,
    issuedAt: issuedAt ?? this.issuedAt,
  );
  SickLeaveRow copyWithCompanion(SickLeaveCertificatesCompanion data) {
    return SickLeaveRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      issuedByStaffId: data.issuedByStaffId.present
          ? data.issuedByStaffId.value
          : this.issuedByStaffId,
      appointmentId: data.appointmentId.present
          ? data.appointmentId.value
          : this.appointmentId,
      diagnosis: data.diagnosis.present ? data.diagnosis.value : this.diagnosis,
      fromDate: data.fromDate.present ? data.fromDate.value : this.fromDate,
      toDate: data.toDate.present ? data.toDate.value : this.toDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      issuedAt: data.issuedAt.present ? data.issuedAt.value : this.issuedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SickLeaveRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('issuedByStaffId: $issuedByStaffId, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('diagnosis: $diagnosis, ')
          ..write('fromDate: $fromDate, ')
          ..write('toDate: $toDate, ')
          ..write('notes: $notes, ')
          ..write('issuedAt: $issuedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    issuedByStaffId,
    appointmentId,
    diagnosis,
    fromDate,
    toDate,
    notes,
    issuedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SickLeaveRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.issuedByStaffId == this.issuedByStaffId &&
          other.appointmentId == this.appointmentId &&
          other.diagnosis == this.diagnosis &&
          other.fromDate == this.fromDate &&
          other.toDate == this.toDate &&
          other.notes == this.notes &&
          other.issuedAt == this.issuedAt);
}

class SickLeaveCertificatesCompanion extends UpdateCompanion<SickLeaveRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> issuedByStaffId;
  final Value<String?> appointmentId;
  final Value<String> diagnosis;
  final Value<DateTime> fromDate;
  final Value<DateTime> toDate;
  final Value<String?> notes;
  final Value<DateTime> issuedAt;
  final Value<int> rowid;
  const SickLeaveCertificatesCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.issuedByStaffId = const Value.absent(),
    this.appointmentId = const Value.absent(),
    this.diagnosis = const Value.absent(),
    this.fromDate = const Value.absent(),
    this.toDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SickLeaveCertificatesCompanion.insert({
    required String id,
    required String patientId,
    required String issuedByStaffId,
    this.appointmentId = const Value.absent(),
    required String diagnosis,
    required DateTime fromDate,
    required DateTime toDate,
    this.notes = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       issuedByStaffId = Value(issuedByStaffId),
       diagnosis = Value(diagnosis),
       fromDate = Value(fromDate),
       toDate = Value(toDate);
  static Insertable<SickLeaveRow> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? issuedByStaffId,
    Expression<String>? appointmentId,
    Expression<String>? diagnosis,
    Expression<DateTime>? fromDate,
    Expression<DateTime>? toDate,
    Expression<String>? notes,
    Expression<DateTime>? issuedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (issuedByStaffId != null) 'issued_by_staff_id': issuedByStaffId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
      if (notes != null) 'notes': notes,
      if (issuedAt != null) 'issued_at': issuedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SickLeaveCertificatesCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String>? issuedByStaffId,
    Value<String?>? appointmentId,
    Value<String>? diagnosis,
    Value<DateTime>? fromDate,
    Value<DateTime>? toDate,
    Value<String?>? notes,
    Value<DateTime>? issuedAt,
    Value<int>? rowid,
  }) {
    return SickLeaveCertificatesCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      issuedByStaffId: issuedByStaffId ?? this.issuedByStaffId,
      appointmentId: appointmentId ?? this.appointmentId,
      diagnosis: diagnosis ?? this.diagnosis,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      notes: notes ?? this.notes,
      issuedAt: issuedAt ?? this.issuedAt,
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
    if (issuedByStaffId.present) {
      map['issued_by_staff_id'] = Variable<String>(issuedByStaffId.value);
    }
    if (appointmentId.present) {
      map['appointment_id'] = Variable<String>(appointmentId.value);
    }
    if (diagnosis.present) {
      map['diagnosis'] = Variable<String>(diagnosis.value);
    }
    if (fromDate.present) {
      map['from_date'] = Variable<DateTime>(fromDate.value);
    }
    if (toDate.present) {
      map['to_date'] = Variable<DateTime>(toDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (issuedAt.present) {
      map['issued_at'] = Variable<DateTime>(issuedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SickLeaveCertificatesCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('issuedByStaffId: $issuedByStaffId, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('diagnosis: $diagnosis, ')
          ..write('fromDate: $fromDate, ')
          ..write('toDate: $toDate, ')
          ..write('notes: $notes, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareMessagesTable extends CareMessages
    with TableInfo<$CareMessagesTable, CareMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareMessagesTable(this.attachedDatabase, [this._alias]);
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
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fromStaffMeta = const VerificationMeta(
    'fromStaff',
  );
  @override
  late final GeneratedColumn<bool> fromStaff = GeneratedColumn<bool>(
    'from_staff',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("from_staff" IN (0, 1))',
    ),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 4000,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
    'read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _senderAccountIdMeta = const VerificationMeta(
    'senderAccountId',
  );
  @override
  late final GeneratedColumn<String> senderAccountId = GeneratedColumn<String>(
    'sender_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _queueOwnerStaffIdMeta = const VerificationMeta(
    'queueOwnerStaffId',
  );
  @override
  late final GeneratedColumn<String> queueOwnerStaffId =
      GeneratedColumn<String>(
        'queue_owner_staff_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES users (id) ON DELETE SET NULL',
        ),
      );
  static const VerificationMeta _coverageStaffIdMeta = const VerificationMeta(
    'coverageStaffId',
  );
  @override
  late final GeneratedColumn<String> coverageStaffId = GeneratedColumn<String>(
    'coverage_staff_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _responseDueAtMeta = const VerificationMeta(
    'responseDueAt',
  );
  @override
  late final GeneratedColumn<DateTime> responseDueAt =
      GeneratedColumn<DateTime>(
        'response_due_at',
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
    fromStaff,
    body,
    sentAt,
    readAt,
    senderAccountId,
    queueOwnerStaffId,
    coverageStaffId,
    responseDueAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'care_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<CareMessageRow> instance, {
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
    if (data.containsKey('from_staff')) {
      context.handle(
        _fromStaffMeta,
        fromStaff.isAcceptableOrUnknown(data['from_staff']!, _fromStaffMeta),
      );
    } else if (isInserting) {
      context.missing(_fromStaffMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    }
    if (data.containsKey('sender_account_id')) {
      context.handle(
        _senderAccountIdMeta,
        senderAccountId.isAcceptableOrUnknown(
          data['sender_account_id']!,
          _senderAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('queue_owner_staff_id')) {
      context.handle(
        _queueOwnerStaffIdMeta,
        queueOwnerStaffId.isAcceptableOrUnknown(
          data['queue_owner_staff_id']!,
          _queueOwnerStaffIdMeta,
        ),
      );
    }
    if (data.containsKey('coverage_staff_id')) {
      context.handle(
        _coverageStaffIdMeta,
        coverageStaffId.isAcceptableOrUnknown(
          data['coverage_staff_id']!,
          _coverageStaffIdMeta,
        ),
      );
    }
    if (data.containsKey('response_due_at')) {
      context.handle(
        _responseDueAtMeta,
        responseDueAt.isAcceptableOrUnknown(
          data['response_due_at']!,
          _responseDueAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CareMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CareMessageRow(
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
      fromStaff: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}from_staff'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      )!,
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}read_at'],
      ),
      senderAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_account_id'],
      ),
      queueOwnerStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}queue_owner_staff_id'],
      ),
      coverageStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coverage_staff_id'],
      ),
      responseDueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}response_due_at'],
      ),
    );
  }

  @override
  $CareMessagesTable createAlias(String alias) {
    return $CareMessagesTable(attachedDatabase, alias);
  }
}

class CareMessageRow extends DataClass implements Insertable<CareMessageRow> {
  final String id;
  final String patientId;
  final String staffId;

  /// True when the doctor sent it, false when the patient did.
  final bool fromStaff;
  final String body;
  final DateTime sentAt;
  final DateTime? readAt;

  /// The signed-in account that wrote it — the doctor, the patient, or a
  /// proxy writing for the patient.
  final String? senderAccountId;
  final String? queueOwnerStaffId;
  final String? coverageStaffId;
  final DateTime? responseDueAt;
  const CareMessageRow({
    required this.id,
    required this.patientId,
    required this.staffId,
    required this.fromStaff,
    required this.body,
    required this.sentAt,
    this.readAt,
    this.senderAccountId,
    this.queueOwnerStaffId,
    this.coverageStaffId,
    this.responseDueAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['staff_id'] = Variable<String>(staffId);
    map['from_staff'] = Variable<bool>(fromStaff);
    map['body'] = Variable<String>(body);
    map['sent_at'] = Variable<DateTime>(sentAt);
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<DateTime>(readAt);
    }
    if (!nullToAbsent || senderAccountId != null) {
      map['sender_account_id'] = Variable<String>(senderAccountId);
    }
    if (!nullToAbsent || queueOwnerStaffId != null) {
      map['queue_owner_staff_id'] = Variable<String>(queueOwnerStaffId);
    }
    if (!nullToAbsent || coverageStaffId != null) {
      map['coverage_staff_id'] = Variable<String>(coverageStaffId);
    }
    if (!nullToAbsent || responseDueAt != null) {
      map['response_due_at'] = Variable<DateTime>(responseDueAt);
    }
    return map;
  }

  CareMessagesCompanion toCompanion(bool nullToAbsent) {
    return CareMessagesCompanion(
      id: Value(id),
      patientId: Value(patientId),
      staffId: Value(staffId),
      fromStaff: Value(fromStaff),
      body: Value(body),
      sentAt: Value(sentAt),
      readAt: readAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readAt),
      senderAccountId: senderAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(senderAccountId),
      queueOwnerStaffId: queueOwnerStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(queueOwnerStaffId),
      coverageStaffId: coverageStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverageStaffId),
      responseDueAt: responseDueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(responseDueAt),
    );
  }

  factory CareMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CareMessageRow(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      staffId: serializer.fromJson<String>(json['staffId']),
      fromStaff: serializer.fromJson<bool>(json['fromStaff']),
      body: serializer.fromJson<String>(json['body']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
      senderAccountId: serializer.fromJson<String?>(json['senderAccountId']),
      queueOwnerStaffId: serializer.fromJson<String?>(
        json['queueOwnerStaffId'],
      ),
      coverageStaffId: serializer.fromJson<String?>(json['coverageStaffId']),
      responseDueAt: serializer.fromJson<DateTime?>(json['responseDueAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'staffId': serializer.toJson<String>(staffId),
      'fromStaff': serializer.toJson<bool>(fromStaff),
      'body': serializer.toJson<String>(body),
      'sentAt': serializer.toJson<DateTime>(sentAt),
      'readAt': serializer.toJson<DateTime?>(readAt),
      'senderAccountId': serializer.toJson<String?>(senderAccountId),
      'queueOwnerStaffId': serializer.toJson<String?>(queueOwnerStaffId),
      'coverageStaffId': serializer.toJson<String?>(coverageStaffId),
      'responseDueAt': serializer.toJson<DateTime?>(responseDueAt),
    };
  }

  CareMessageRow copyWith({
    String? id,
    String? patientId,
    String? staffId,
    bool? fromStaff,
    String? body,
    DateTime? sentAt,
    Value<DateTime?> readAt = const Value.absent(),
    Value<String?> senderAccountId = const Value.absent(),
    Value<String?> queueOwnerStaffId = const Value.absent(),
    Value<String?> coverageStaffId = const Value.absent(),
    Value<DateTime?> responseDueAt = const Value.absent(),
  }) => CareMessageRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    staffId: staffId ?? this.staffId,
    fromStaff: fromStaff ?? this.fromStaff,
    body: body ?? this.body,
    sentAt: sentAt ?? this.sentAt,
    readAt: readAt.present ? readAt.value : this.readAt,
    senderAccountId: senderAccountId.present
        ? senderAccountId.value
        : this.senderAccountId,
    queueOwnerStaffId: queueOwnerStaffId.present
        ? queueOwnerStaffId.value
        : this.queueOwnerStaffId,
    coverageStaffId: coverageStaffId.present
        ? coverageStaffId.value
        : this.coverageStaffId,
    responseDueAt: responseDueAt.present
        ? responseDueAt.value
        : this.responseDueAt,
  );
  CareMessageRow copyWithCompanion(CareMessagesCompanion data) {
    return CareMessageRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      fromStaff: data.fromStaff.present ? data.fromStaff.value : this.fromStaff,
      body: data.body.present ? data.body.value : this.body,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      senderAccountId: data.senderAccountId.present
          ? data.senderAccountId.value
          : this.senderAccountId,
      queueOwnerStaffId: data.queueOwnerStaffId.present
          ? data.queueOwnerStaffId.value
          : this.queueOwnerStaffId,
      coverageStaffId: data.coverageStaffId.present
          ? data.coverageStaffId.value
          : this.coverageStaffId,
      responseDueAt: data.responseDueAt.present
          ? data.responseDueAt.value
          : this.responseDueAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CareMessageRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('staffId: $staffId, ')
          ..write('fromStaff: $fromStaff, ')
          ..write('body: $body, ')
          ..write('sentAt: $sentAt, ')
          ..write('readAt: $readAt, ')
          ..write('senderAccountId: $senderAccountId, ')
          ..write('queueOwnerStaffId: $queueOwnerStaffId, ')
          ..write('coverageStaffId: $coverageStaffId, ')
          ..write('responseDueAt: $responseDueAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    staffId,
    fromStaff,
    body,
    sentAt,
    readAt,
    senderAccountId,
    queueOwnerStaffId,
    coverageStaffId,
    responseDueAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CareMessageRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.staffId == this.staffId &&
          other.fromStaff == this.fromStaff &&
          other.body == this.body &&
          other.sentAt == this.sentAt &&
          other.readAt == this.readAt &&
          other.senderAccountId == this.senderAccountId &&
          other.queueOwnerStaffId == this.queueOwnerStaffId &&
          other.coverageStaffId == this.coverageStaffId &&
          other.responseDueAt == this.responseDueAt);
}

class CareMessagesCompanion extends UpdateCompanion<CareMessageRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> staffId;
  final Value<bool> fromStaff;
  final Value<String> body;
  final Value<DateTime> sentAt;
  final Value<DateTime?> readAt;
  final Value<String?> senderAccountId;
  final Value<String?> queueOwnerStaffId;
  final Value<String?> coverageStaffId;
  final Value<DateTime?> responseDueAt;
  final Value<int> rowid;
  const CareMessagesCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.staffId = const Value.absent(),
    this.fromStaff = const Value.absent(),
    this.body = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.senderAccountId = const Value.absent(),
    this.queueOwnerStaffId = const Value.absent(),
    this.coverageStaffId = const Value.absent(),
    this.responseDueAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareMessagesCompanion.insert({
    required String id,
    required String patientId,
    required String staffId,
    required bool fromStaff,
    required String body,
    this.sentAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.senderAccountId = const Value.absent(),
    this.queueOwnerStaffId = const Value.absent(),
    this.coverageStaffId = const Value.absent(),
    this.responseDueAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       staffId = Value(staffId),
       fromStaff = Value(fromStaff),
       body = Value(body);
  static Insertable<CareMessageRow> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? staffId,
    Expression<bool>? fromStaff,
    Expression<String>? body,
    Expression<DateTime>? sentAt,
    Expression<DateTime>? readAt,
    Expression<String>? senderAccountId,
    Expression<String>? queueOwnerStaffId,
    Expression<String>? coverageStaffId,
    Expression<DateTime>? responseDueAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (staffId != null) 'staff_id': staffId,
      if (fromStaff != null) 'from_staff': fromStaff,
      if (body != null) 'body': body,
      if (sentAt != null) 'sent_at': sentAt,
      if (readAt != null) 'read_at': readAt,
      if (senderAccountId != null) 'sender_account_id': senderAccountId,
      if (queueOwnerStaffId != null) 'queue_owner_staff_id': queueOwnerStaffId,
      if (coverageStaffId != null) 'coverage_staff_id': coverageStaffId,
      if (responseDueAt != null) 'response_due_at': responseDueAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String>? staffId,
    Value<bool>? fromStaff,
    Value<String>? body,
    Value<DateTime>? sentAt,
    Value<DateTime?>? readAt,
    Value<String?>? senderAccountId,
    Value<String?>? queueOwnerStaffId,
    Value<String?>? coverageStaffId,
    Value<DateTime?>? responseDueAt,
    Value<int>? rowid,
  }) {
    return CareMessagesCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      staffId: staffId ?? this.staffId,
      fromStaff: fromStaff ?? this.fromStaff,
      body: body ?? this.body,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      senderAccountId: senderAccountId ?? this.senderAccountId,
      queueOwnerStaffId: queueOwnerStaffId ?? this.queueOwnerStaffId,
      coverageStaffId: coverageStaffId ?? this.coverageStaffId,
      responseDueAt: responseDueAt ?? this.responseDueAt,
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
    if (fromStaff.present) {
      map['from_staff'] = Variable<bool>(fromStaff.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    if (senderAccountId.present) {
      map['sender_account_id'] = Variable<String>(senderAccountId.value);
    }
    if (queueOwnerStaffId.present) {
      map['queue_owner_staff_id'] = Variable<String>(queueOwnerStaffId.value);
    }
    if (coverageStaffId.present) {
      map['coverage_staff_id'] = Variable<String>(coverageStaffId.value);
    }
    if (responseDueAt.present) {
      map['response_due_at'] = Variable<DateTime>(responseDueAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareMessagesCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('staffId: $staffId, ')
          ..write('fromStaff: $fromStaff, ')
          ..write('body: $body, ')
          ..write('sentAt: $sentAt, ')
          ..write('readAt: $readAt, ')
          ..write('senderAccountId: $senderAccountId, ')
          ..write('queueOwnerStaffId: $queueOwnerStaffId, ')
          ..write('coverageStaffId: $coverageStaffId, ')
          ..write('responseDueAt: $responseDueAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HomeVisitRequestsTable extends HomeVisitRequests
    with TableInfo<$HomeVisitRequestsTable, HomeVisitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HomeVisitRequestsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _addressTextMeta = const VerificationMeta(
    'addressText',
  );
  @override
  late final GeneratedColumn<String> addressText = GeneratedColumn<String>(
    'address_text',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _preferredDateMeta = const VerificationMeta(
    'preferredDate',
  );
  @override
  late final GeneratedColumn<DateTime> preferredDate =
      GeneratedColumn<DateTime>(
        'preferred_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _reasonTextMeta = const VerificationMeta(
    'reasonText',
  );
  @override
  late final GeneratedColumn<String> reasonText = GeneratedColumn<String>(
    'reason_text',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 1000,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<HomeVisitStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('requested'),
      ).withConverter<HomeVisitStatus>(
        $HomeVisitRequestsTable.$converterstatus,
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
      'REFERENCES departments (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _assignedStaffIdMeta = const VerificationMeta(
    'assignedStaffId',
  );
  @override
  late final GeneratedColumn<String> assignedStaffId = GeneratedColumn<String>(
    'assigned_staff_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _decisionNoteMeta = const VerificationMeta(
    'decisionNote',
  );
  @override
  late final GeneratedColumn<String> decisionNote = GeneratedColumn<String>(
    'decision_note',
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
  static const VerificationMeta _decidedAtMeta = const VerificationMeta(
    'decidedAt',
  );
  @override
  late final GeneratedColumn<DateTime> decidedAt = GeneratedColumn<DateTime>(
    'decided_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requestedByAccountIdMeta =
      const VerificationMeta('requestedByAccountId');
  @override
  late final GeneratedColumn<String> requestedByAccountId =
      GeneratedColumn<String>(
        'requested_by_account_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    addressText,
    preferredDate,
    reasonText,
    status,
    departmentId,
    assignedStaffId,
    decisionNote,
    createdAt,
    decidedAt,
    requestedByAccountId,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'home_visit_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<HomeVisitRow> instance, {
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
    if (data.containsKey('address_text')) {
      context.handle(
        _addressTextMeta,
        addressText.isAcceptableOrUnknown(
          data['address_text']!,
          _addressTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_addressTextMeta);
    }
    if (data.containsKey('preferred_date')) {
      context.handle(
        _preferredDateMeta,
        preferredDate.isAcceptableOrUnknown(
          data['preferred_date']!,
          _preferredDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_preferredDateMeta);
    }
    if (data.containsKey('reason_text')) {
      context.handle(
        _reasonTextMeta,
        reasonText.isAcceptableOrUnknown(data['reason_text']!, _reasonTextMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonTextMeta);
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
    if (data.containsKey('assigned_staff_id')) {
      context.handle(
        _assignedStaffIdMeta,
        assignedStaffId.isAcceptableOrUnknown(
          data['assigned_staff_id']!,
          _assignedStaffIdMeta,
        ),
      );
    }
    if (data.containsKey('decision_note')) {
      context.handle(
        _decisionNoteMeta,
        decisionNote.isAcceptableOrUnknown(
          data['decision_note']!,
          _decisionNoteMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('decided_at')) {
      context.handle(
        _decidedAtMeta,
        decidedAt.isAcceptableOrUnknown(data['decided_at']!, _decidedAtMeta),
      );
    }
    if (data.containsKey('requested_by_account_id')) {
      context.handle(
        _requestedByAccountIdMeta,
        requestedByAccountId.isAcceptableOrUnknown(
          data['requested_by_account_id']!,
          _requestedByAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HomeVisitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HomeVisitRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      addressText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address_text'],
      )!,
      preferredDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}preferred_date'],
      )!,
      reasonText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_text'],
      )!,
      status: $HomeVisitRequestsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      departmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}department_id'],
      ),
      assignedStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_staff_id'],
      ),
      decisionNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decision_note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      decidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}decided_at'],
      ),
      requestedByAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requested_by_account_id'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $HomeVisitRequestsTable createAlias(String alias) {
    return $HomeVisitRequestsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<HomeVisitStatus, String, String> $converterstatus =
      const EnumNameConverter<HomeVisitStatus>(HomeVisitStatus.values);
}

class HomeVisitRow extends DataClass implements Insertable<HomeVisitRow> {
  final String id;
  final String patientId;
  final String addressText;
  final DateTime preferredDate;
  final String reasonText;
  final HomeVisitStatus status;
  final String? departmentId;
  final String? assignedStaffId;

  /// The clinic's note when scheduling / declining.
  final String? decisionNote;
  final DateTime createdAt;
  final DateTime? decidedAt;

  /// The signed-in account that asked for the visit (patient or proxy).
  final String? requestedByAccountId;

  /// Optimistic-concurrency version (trigger-bumped, schema v19).
  final int version;
  const HomeVisitRow({
    required this.id,
    required this.patientId,
    required this.addressText,
    required this.preferredDate,
    required this.reasonText,
    required this.status,
    this.departmentId,
    this.assignedStaffId,
    this.decisionNote,
    required this.createdAt,
    this.decidedAt,
    this.requestedByAccountId,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['address_text'] = Variable<String>(addressText);
    map['preferred_date'] = Variable<DateTime>(preferredDate);
    map['reason_text'] = Variable<String>(reasonText);
    {
      map['status'] = Variable<String>(
        $HomeVisitRequestsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || departmentId != null) {
      map['department_id'] = Variable<String>(departmentId);
    }
    if (!nullToAbsent || assignedStaffId != null) {
      map['assigned_staff_id'] = Variable<String>(assignedStaffId);
    }
    if (!nullToAbsent || decisionNote != null) {
      map['decision_note'] = Variable<String>(decisionNote);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || decidedAt != null) {
      map['decided_at'] = Variable<DateTime>(decidedAt);
    }
    if (!nullToAbsent || requestedByAccountId != null) {
      map['requested_by_account_id'] = Variable<String>(requestedByAccountId);
    }
    map['version'] = Variable<int>(version);
    return map;
  }

  HomeVisitRequestsCompanion toCompanion(bool nullToAbsent) {
    return HomeVisitRequestsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      addressText: Value(addressText),
      preferredDate: Value(preferredDate),
      reasonText: Value(reasonText),
      status: Value(status),
      departmentId: departmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(departmentId),
      assignedStaffId: assignedStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedStaffId),
      decisionNote: decisionNote == null && nullToAbsent
          ? const Value.absent()
          : Value(decisionNote),
      createdAt: Value(createdAt),
      decidedAt: decidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(decidedAt),
      requestedByAccountId: requestedByAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(requestedByAccountId),
      version: Value(version),
    );
  }

  factory HomeVisitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HomeVisitRow(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      addressText: serializer.fromJson<String>(json['addressText']),
      preferredDate: serializer.fromJson<DateTime>(json['preferredDate']),
      reasonText: serializer.fromJson<String>(json['reasonText']),
      status: $HomeVisitRequestsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      departmentId: serializer.fromJson<String?>(json['departmentId']),
      assignedStaffId: serializer.fromJson<String?>(json['assignedStaffId']),
      decisionNote: serializer.fromJson<String?>(json['decisionNote']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      decidedAt: serializer.fromJson<DateTime?>(json['decidedAt']),
      requestedByAccountId: serializer.fromJson<String?>(
        json['requestedByAccountId'],
      ),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'addressText': serializer.toJson<String>(addressText),
      'preferredDate': serializer.toJson<DateTime>(preferredDate),
      'reasonText': serializer.toJson<String>(reasonText),
      'status': serializer.toJson<String>(
        $HomeVisitRequestsTable.$converterstatus.toJson(status),
      ),
      'departmentId': serializer.toJson<String?>(departmentId),
      'assignedStaffId': serializer.toJson<String?>(assignedStaffId),
      'decisionNote': serializer.toJson<String?>(decisionNote),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'decidedAt': serializer.toJson<DateTime?>(decidedAt),
      'requestedByAccountId': serializer.toJson<String?>(requestedByAccountId),
      'version': serializer.toJson<int>(version),
    };
  }

  HomeVisitRow copyWith({
    String? id,
    String? patientId,
    String? addressText,
    DateTime? preferredDate,
    String? reasonText,
    HomeVisitStatus? status,
    Value<String?> departmentId = const Value.absent(),
    Value<String?> assignedStaffId = const Value.absent(),
    Value<String?> decisionNote = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> decidedAt = const Value.absent(),
    Value<String?> requestedByAccountId = const Value.absent(),
    int? version,
  }) => HomeVisitRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    addressText: addressText ?? this.addressText,
    preferredDate: preferredDate ?? this.preferredDate,
    reasonText: reasonText ?? this.reasonText,
    status: status ?? this.status,
    departmentId: departmentId.present ? departmentId.value : this.departmentId,
    assignedStaffId: assignedStaffId.present
        ? assignedStaffId.value
        : this.assignedStaffId,
    decisionNote: decisionNote.present ? decisionNote.value : this.decisionNote,
    createdAt: createdAt ?? this.createdAt,
    decidedAt: decidedAt.present ? decidedAt.value : this.decidedAt,
    requestedByAccountId: requestedByAccountId.present
        ? requestedByAccountId.value
        : this.requestedByAccountId,
    version: version ?? this.version,
  );
  HomeVisitRow copyWithCompanion(HomeVisitRequestsCompanion data) {
    return HomeVisitRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      addressText: data.addressText.present
          ? data.addressText.value
          : this.addressText,
      preferredDate: data.preferredDate.present
          ? data.preferredDate.value
          : this.preferredDate,
      reasonText: data.reasonText.present
          ? data.reasonText.value
          : this.reasonText,
      status: data.status.present ? data.status.value : this.status,
      departmentId: data.departmentId.present
          ? data.departmentId.value
          : this.departmentId,
      assignedStaffId: data.assignedStaffId.present
          ? data.assignedStaffId.value
          : this.assignedStaffId,
      decisionNote: data.decisionNote.present
          ? data.decisionNote.value
          : this.decisionNote,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      decidedAt: data.decidedAt.present ? data.decidedAt.value : this.decidedAt,
      requestedByAccountId: data.requestedByAccountId.present
          ? data.requestedByAccountId.value
          : this.requestedByAccountId,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HomeVisitRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('addressText: $addressText, ')
          ..write('preferredDate: $preferredDate, ')
          ..write('reasonText: $reasonText, ')
          ..write('status: $status, ')
          ..write('departmentId: $departmentId, ')
          ..write('assignedStaffId: $assignedStaffId, ')
          ..write('decisionNote: $decisionNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('requestedByAccountId: $requestedByAccountId, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    addressText,
    preferredDate,
    reasonText,
    status,
    departmentId,
    assignedStaffId,
    decisionNote,
    createdAt,
    decidedAt,
    requestedByAccountId,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HomeVisitRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.addressText == this.addressText &&
          other.preferredDate == this.preferredDate &&
          other.reasonText == this.reasonText &&
          other.status == this.status &&
          other.departmentId == this.departmentId &&
          other.assignedStaffId == this.assignedStaffId &&
          other.decisionNote == this.decisionNote &&
          other.createdAt == this.createdAt &&
          other.decidedAt == this.decidedAt &&
          other.requestedByAccountId == this.requestedByAccountId &&
          other.version == this.version);
}

class HomeVisitRequestsCompanion extends UpdateCompanion<HomeVisitRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> addressText;
  final Value<DateTime> preferredDate;
  final Value<String> reasonText;
  final Value<HomeVisitStatus> status;
  final Value<String?> departmentId;
  final Value<String?> assignedStaffId;
  final Value<String?> decisionNote;
  final Value<DateTime> createdAt;
  final Value<DateTime?> decidedAt;
  final Value<String?> requestedByAccountId;
  final Value<int> version;
  final Value<int> rowid;
  const HomeVisitRequestsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.addressText = const Value.absent(),
    this.preferredDate = const Value.absent(),
    this.reasonText = const Value.absent(),
    this.status = const Value.absent(),
    this.departmentId = const Value.absent(),
    this.assignedStaffId = const Value.absent(),
    this.decisionNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.requestedByAccountId = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HomeVisitRequestsCompanion.insert({
    required String id,
    required String patientId,
    required String addressText,
    required DateTime preferredDate,
    required String reasonText,
    this.status = const Value.absent(),
    this.departmentId = const Value.absent(),
    this.assignedStaffId = const Value.absent(),
    this.decisionNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.requestedByAccountId = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       addressText = Value(addressText),
       preferredDate = Value(preferredDate),
       reasonText = Value(reasonText);
  static Insertable<HomeVisitRow> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? addressText,
    Expression<DateTime>? preferredDate,
    Expression<String>? reasonText,
    Expression<String>? status,
    Expression<String>? departmentId,
    Expression<String>? assignedStaffId,
    Expression<String>? decisionNote,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? decidedAt,
    Expression<String>? requestedByAccountId,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (addressText != null) 'address_text': addressText,
      if (preferredDate != null) 'preferred_date': preferredDate,
      if (reasonText != null) 'reason_text': reasonText,
      if (status != null) 'status': status,
      if (departmentId != null) 'department_id': departmentId,
      if (assignedStaffId != null) 'assigned_staff_id': assignedStaffId,
      if (decisionNote != null) 'decision_note': decisionNote,
      if (createdAt != null) 'created_at': createdAt,
      if (decidedAt != null) 'decided_at': decidedAt,
      if (requestedByAccountId != null)
        'requested_by_account_id': requestedByAccountId,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HomeVisitRequestsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String>? addressText,
    Value<DateTime>? preferredDate,
    Value<String>? reasonText,
    Value<HomeVisitStatus>? status,
    Value<String?>? departmentId,
    Value<String?>? assignedStaffId,
    Value<String?>? decisionNote,
    Value<DateTime>? createdAt,
    Value<DateTime?>? decidedAt,
    Value<String?>? requestedByAccountId,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return HomeVisitRequestsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      addressText: addressText ?? this.addressText,
      preferredDate: preferredDate ?? this.preferredDate,
      reasonText: reasonText ?? this.reasonText,
      status: status ?? this.status,
      departmentId: departmentId ?? this.departmentId,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      decisionNote: decisionNote ?? this.decisionNote,
      createdAt: createdAt ?? this.createdAt,
      decidedAt: decidedAt ?? this.decidedAt,
      requestedByAccountId: requestedByAccountId ?? this.requestedByAccountId,
      version: version ?? this.version,
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
    if (addressText.present) {
      map['address_text'] = Variable<String>(addressText.value);
    }
    if (preferredDate.present) {
      map['preferred_date'] = Variable<DateTime>(preferredDate.value);
    }
    if (reasonText.present) {
      map['reason_text'] = Variable<String>(reasonText.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $HomeVisitRequestsTable.$converterstatus.toSql(status.value),
      );
    }
    if (departmentId.present) {
      map['department_id'] = Variable<String>(departmentId.value);
    }
    if (assignedStaffId.present) {
      map['assigned_staff_id'] = Variable<String>(assignedStaffId.value);
    }
    if (decisionNote.present) {
      map['decision_note'] = Variable<String>(decisionNote.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (decidedAt.present) {
      map['decided_at'] = Variable<DateTime>(decidedAt.value);
    }
    if (requestedByAccountId.present) {
      map['requested_by_account_id'] = Variable<String>(
        requestedByAccountId.value,
      );
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HomeVisitRequestsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('addressText: $addressText, ')
          ..write('preferredDate: $preferredDate, ')
          ..write('reasonText: $reasonText, ')
          ..write('status: $status, ')
          ..write('departmentId: $departmentId, ')
          ..write('assignedStaffId: $assignedStaffId, ')
          ..write('decisionNote: $decisionNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('requestedByAccountId: $requestedByAccountId, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WalkInTicketsTable extends WalkInTickets
    with TableInfo<$WalkInTicketsTable, WalkInRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalkInTicketsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _departmentIdMeta = const VerificationMeta(
    'departmentId',
  );
  @override
  late final GeneratedColumn<String> departmentId = GeneratedColumn<String>(
    'department_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES departments (id)',
    ),
  );
  static const VerificationMeta _ticketTagMeta = const VerificationMeta(
    'ticketTag',
  );
  @override
  late final GeneratedColumn<String> ticketTag = GeneratedColumn<String>(
    'ticket_tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WalkInStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('waiting'),
      ).withConverter<WalkInStatus>($WalkInTicketsTable.$converterstatus);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceAppointmentIdMeta =
      const VerificationMeta('sourceAppointmentId');
  @override
  late final GeneratedColumn<String> sourceAppointmentId =
      GeneratedColumn<String>(
        'source_appointment_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES appointments (id) ON DELETE SET NULL',
        ),
      );
  static const VerificationMeta _createdByStaffIdMeta = const VerificationMeta(
    'createdByStaffId',
  );
  @override
  late final GeneratedColumn<String> createdByStaffId = GeneratedColumn<String>(
    'created_by_staff_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _claimedByStaffIdMeta = const VerificationMeta(
    'claimedByStaffId',
  );
  @override
  late final GeneratedColumn<String> claimedByStaffId = GeneratedColumn<String>(
    'claimed_by_staff_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _resultAppointmentIdMeta =
      const VerificationMeta('resultAppointmentId');
  @override
  late final GeneratedColumn<String> resultAppointmentId =
      GeneratedColumn<String>(
        'result_appointment_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES appointments (id) ON DELETE SET NULL',
        ),
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
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    departmentId,
    ticketTag,
    status,
    reason,
    sourceAppointmentId,
    createdByStaffId,
    claimedByStaffId,
    resultAppointmentId,
    createdAt,
    resolvedAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'walk_in_tickets';
  @override
  VerificationContext validateIntegrity(
    Insertable<WalkInRow> instance, {
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
    if (data.containsKey('department_id')) {
      context.handle(
        _departmentIdMeta,
        departmentId.isAcceptableOrUnknown(
          data['department_id']!,
          _departmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_departmentIdMeta);
    }
    if (data.containsKey('ticket_tag')) {
      context.handle(
        _ticketTagMeta,
        ticketTag.isAcceptableOrUnknown(data['ticket_tag']!, _ticketTagMeta),
      );
    } else if (isInserting) {
      context.missing(_ticketTagMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('source_appointment_id')) {
      context.handle(
        _sourceAppointmentIdMeta,
        sourceAppointmentId.isAcceptableOrUnknown(
          data['source_appointment_id']!,
          _sourceAppointmentIdMeta,
        ),
      );
    }
    if (data.containsKey('created_by_staff_id')) {
      context.handle(
        _createdByStaffIdMeta,
        createdByStaffId.isAcceptableOrUnknown(
          data['created_by_staff_id']!,
          _createdByStaffIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdByStaffIdMeta);
    }
    if (data.containsKey('claimed_by_staff_id')) {
      context.handle(
        _claimedByStaffIdMeta,
        claimedByStaffId.isAcceptableOrUnknown(
          data['claimed_by_staff_id']!,
          _claimedByStaffIdMeta,
        ),
      );
    }
    if (data.containsKey('result_appointment_id')) {
      context.handle(
        _resultAppointmentIdMeta,
        resultAppointmentId.isAcceptableOrUnknown(
          data['result_appointment_id']!,
          _resultAppointmentIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WalkInRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WalkInRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      departmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}department_id'],
      )!,
      ticketTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ticket_tag'],
      )!,
      status: $WalkInTicketsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      sourceAppointmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_appointment_id'],
      ),
      createdByStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_staff_id'],
      )!,
      claimedByStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}claimed_by_staff_id'],
      ),
      resultAppointmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_appointment_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $WalkInTicketsTable createAlias(String alias) {
    return $WalkInTicketsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WalkInStatus, String, String> $converterstatus =
      const EnumNameConverter<WalkInStatus>(WalkInStatus.values);
}

class WalkInRow extends DataClass implements Insertable<WalkInRow> {
  final String id;
  final String patientId;
  final String departmentId;

  /// `[department letter]-[per-department count that day]`, e.g. `C-14`.
  final String ticketTag;
  final WalkInStatus status;
  final String? reason;

  /// The visit the referral came from, if any.
  final String? sourceAppointmentId;

  /// The admin who actioned the referral into this ticket.
  final String createdByStaffId;

  /// The doctor who picked it up.
  final String? claimedByStaffId;

  /// The [Appointments] row created when a doctor starts the visit.
  final String? resultAppointmentId;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  /// Optimistic-concurrency version (trigger-bumped, schema v19). Two
  /// clinicians claiming one ticket race on this.
  final int version;
  const WalkInRow({
    required this.id,
    required this.patientId,
    required this.departmentId,
    required this.ticketTag,
    required this.status,
    this.reason,
    this.sourceAppointmentId,
    required this.createdByStaffId,
    this.claimedByStaffId,
    this.resultAppointmentId,
    required this.createdAt,
    this.resolvedAt,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['department_id'] = Variable<String>(departmentId);
    map['ticket_tag'] = Variable<String>(ticketTag);
    {
      map['status'] = Variable<String>(
        $WalkInTicketsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    if (!nullToAbsent || sourceAppointmentId != null) {
      map['source_appointment_id'] = Variable<String>(sourceAppointmentId);
    }
    map['created_by_staff_id'] = Variable<String>(createdByStaffId);
    if (!nullToAbsent || claimedByStaffId != null) {
      map['claimed_by_staff_id'] = Variable<String>(claimedByStaffId);
    }
    if (!nullToAbsent || resultAppointmentId != null) {
      map['result_appointment_id'] = Variable<String>(resultAppointmentId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    map['version'] = Variable<int>(version);
    return map;
  }

  WalkInTicketsCompanion toCompanion(bool nullToAbsent) {
    return WalkInTicketsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      departmentId: Value(departmentId),
      ticketTag: Value(ticketTag),
      status: Value(status),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      sourceAppointmentId: sourceAppointmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceAppointmentId),
      createdByStaffId: Value(createdByStaffId),
      claimedByStaffId: claimedByStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(claimedByStaffId),
      resultAppointmentId: resultAppointmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(resultAppointmentId),
      createdAt: Value(createdAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
      version: Value(version),
    );
  }

  factory WalkInRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WalkInRow(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      departmentId: serializer.fromJson<String>(json['departmentId']),
      ticketTag: serializer.fromJson<String>(json['ticketTag']),
      status: $WalkInTicketsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      reason: serializer.fromJson<String?>(json['reason']),
      sourceAppointmentId: serializer.fromJson<String?>(
        json['sourceAppointmentId'],
      ),
      createdByStaffId: serializer.fromJson<String>(json['createdByStaffId']),
      claimedByStaffId: serializer.fromJson<String?>(json['claimedByStaffId']),
      resultAppointmentId: serializer.fromJson<String?>(
        json['resultAppointmentId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'departmentId': serializer.toJson<String>(departmentId),
      'ticketTag': serializer.toJson<String>(ticketTag),
      'status': serializer.toJson<String>(
        $WalkInTicketsTable.$converterstatus.toJson(status),
      ),
      'reason': serializer.toJson<String?>(reason),
      'sourceAppointmentId': serializer.toJson<String?>(sourceAppointmentId),
      'createdByStaffId': serializer.toJson<String>(createdByStaffId),
      'claimedByStaffId': serializer.toJson<String?>(claimedByStaffId),
      'resultAppointmentId': serializer.toJson<String?>(resultAppointmentId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
      'version': serializer.toJson<int>(version),
    };
  }

  WalkInRow copyWith({
    String? id,
    String? patientId,
    String? departmentId,
    String? ticketTag,
    WalkInStatus? status,
    Value<String?> reason = const Value.absent(),
    Value<String?> sourceAppointmentId = const Value.absent(),
    String? createdByStaffId,
    Value<String?> claimedByStaffId = const Value.absent(),
    Value<String?> resultAppointmentId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> resolvedAt = const Value.absent(),
    int? version,
  }) => WalkInRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    departmentId: departmentId ?? this.departmentId,
    ticketTag: ticketTag ?? this.ticketTag,
    status: status ?? this.status,
    reason: reason.present ? reason.value : this.reason,
    sourceAppointmentId: sourceAppointmentId.present
        ? sourceAppointmentId.value
        : this.sourceAppointmentId,
    createdByStaffId: createdByStaffId ?? this.createdByStaffId,
    claimedByStaffId: claimedByStaffId.present
        ? claimedByStaffId.value
        : this.claimedByStaffId,
    resultAppointmentId: resultAppointmentId.present
        ? resultAppointmentId.value
        : this.resultAppointmentId,
    createdAt: createdAt ?? this.createdAt,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
    version: version ?? this.version,
  );
  WalkInRow copyWithCompanion(WalkInTicketsCompanion data) {
    return WalkInRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      departmentId: data.departmentId.present
          ? data.departmentId.value
          : this.departmentId,
      ticketTag: data.ticketTag.present ? data.ticketTag.value : this.ticketTag,
      status: data.status.present ? data.status.value : this.status,
      reason: data.reason.present ? data.reason.value : this.reason,
      sourceAppointmentId: data.sourceAppointmentId.present
          ? data.sourceAppointmentId.value
          : this.sourceAppointmentId,
      createdByStaffId: data.createdByStaffId.present
          ? data.createdByStaffId.value
          : this.createdByStaffId,
      claimedByStaffId: data.claimedByStaffId.present
          ? data.claimedByStaffId.value
          : this.claimedByStaffId,
      resultAppointmentId: data.resultAppointmentId.present
          ? data.resultAppointmentId.value
          : this.resultAppointmentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WalkInRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('departmentId: $departmentId, ')
          ..write('ticketTag: $ticketTag, ')
          ..write('status: $status, ')
          ..write('reason: $reason, ')
          ..write('sourceAppointmentId: $sourceAppointmentId, ')
          ..write('createdByStaffId: $createdByStaffId, ')
          ..write('claimedByStaffId: $claimedByStaffId, ')
          ..write('resultAppointmentId: $resultAppointmentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    departmentId,
    ticketTag,
    status,
    reason,
    sourceAppointmentId,
    createdByStaffId,
    claimedByStaffId,
    resultAppointmentId,
    createdAt,
    resolvedAt,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalkInRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.departmentId == this.departmentId &&
          other.ticketTag == this.ticketTag &&
          other.status == this.status &&
          other.reason == this.reason &&
          other.sourceAppointmentId == this.sourceAppointmentId &&
          other.createdByStaffId == this.createdByStaffId &&
          other.claimedByStaffId == this.claimedByStaffId &&
          other.resultAppointmentId == this.resultAppointmentId &&
          other.createdAt == this.createdAt &&
          other.resolvedAt == this.resolvedAt &&
          other.version == this.version);
}

class WalkInTicketsCompanion extends UpdateCompanion<WalkInRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> departmentId;
  final Value<String> ticketTag;
  final Value<WalkInStatus> status;
  final Value<String?> reason;
  final Value<String?> sourceAppointmentId;
  final Value<String> createdByStaffId;
  final Value<String?> claimedByStaffId;
  final Value<String?> resultAppointmentId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> resolvedAt;
  final Value<int> version;
  final Value<int> rowid;
  const WalkInTicketsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.departmentId = const Value.absent(),
    this.ticketTag = const Value.absent(),
    this.status = const Value.absent(),
    this.reason = const Value.absent(),
    this.sourceAppointmentId = const Value.absent(),
    this.createdByStaffId = const Value.absent(),
    this.claimedByStaffId = const Value.absent(),
    this.resultAppointmentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WalkInTicketsCompanion.insert({
    required String id,
    required String patientId,
    required String departmentId,
    required String ticketTag,
    this.status = const Value.absent(),
    this.reason = const Value.absent(),
    this.sourceAppointmentId = const Value.absent(),
    required String createdByStaffId,
    this.claimedByStaffId = const Value.absent(),
    this.resultAppointmentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       departmentId = Value(departmentId),
       ticketTag = Value(ticketTag),
       createdByStaffId = Value(createdByStaffId);
  static Insertable<WalkInRow> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? departmentId,
    Expression<String>? ticketTag,
    Expression<String>? status,
    Expression<String>? reason,
    Expression<String>? sourceAppointmentId,
    Expression<String>? createdByStaffId,
    Expression<String>? claimedByStaffId,
    Expression<String>? resultAppointmentId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? resolvedAt,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (departmentId != null) 'department_id': departmentId,
      if (ticketTag != null) 'ticket_tag': ticketTag,
      if (status != null) 'status': status,
      if (reason != null) 'reason': reason,
      if (sourceAppointmentId != null)
        'source_appointment_id': sourceAppointmentId,
      if (createdByStaffId != null) 'created_by_staff_id': createdByStaffId,
      if (claimedByStaffId != null) 'claimed_by_staff_id': claimedByStaffId,
      if (resultAppointmentId != null)
        'result_appointment_id': resultAppointmentId,
      if (createdAt != null) 'created_at': createdAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WalkInTicketsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String>? departmentId,
    Value<String>? ticketTag,
    Value<WalkInStatus>? status,
    Value<String?>? reason,
    Value<String?>? sourceAppointmentId,
    Value<String>? createdByStaffId,
    Value<String?>? claimedByStaffId,
    Value<String?>? resultAppointmentId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? resolvedAt,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return WalkInTicketsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      departmentId: departmentId ?? this.departmentId,
      ticketTag: ticketTag ?? this.ticketTag,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      sourceAppointmentId: sourceAppointmentId ?? this.sourceAppointmentId,
      createdByStaffId: createdByStaffId ?? this.createdByStaffId,
      claimedByStaffId: claimedByStaffId ?? this.claimedByStaffId,
      resultAppointmentId: resultAppointmentId ?? this.resultAppointmentId,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      version: version ?? this.version,
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
    if (departmentId.present) {
      map['department_id'] = Variable<String>(departmentId.value);
    }
    if (ticketTag.present) {
      map['ticket_tag'] = Variable<String>(ticketTag.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $WalkInTicketsTable.$converterstatus.toSql(status.value),
      );
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (sourceAppointmentId.present) {
      map['source_appointment_id'] = Variable<String>(
        sourceAppointmentId.value,
      );
    }
    if (createdByStaffId.present) {
      map['created_by_staff_id'] = Variable<String>(createdByStaffId.value);
    }
    if (claimedByStaffId.present) {
      map['claimed_by_staff_id'] = Variable<String>(claimedByStaffId.value);
    }
    if (resultAppointmentId.present) {
      map['result_appointment_id'] = Variable<String>(
        resultAppointmentId.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalkInTicketsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('departmentId: $departmentId, ')
          ..write('ticketTag: $ticketTag, ')
          ..write('status: $status, ')
          ..write('reason: $reason, ')
          ..write('sourceAppointmentId: $sourceAppointmentId, ')
          ..write('createdByStaffId: $createdByStaffId, ')
          ..write('claimedByStaffId: $claimedByStaffId, ')
          ..write('resultAppointmentId: $resultAppointmentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReferralRequestsTable extends ReferralRequests
    with TableInfo<$ReferralRequestsTable, ReferralRequestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReferralRequestsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _appointmentIdMeta = const VerificationMeta(
    'appointmentId',
  );
  @override
  late final GeneratedColumn<String> appointmentId = GeneratedColumn<String>(
    'appointment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES appointments (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _requestedByStaffIdMeta =
      const VerificationMeta('requestedByStaffId');
  @override
  late final GeneratedColumn<String> requestedByStaffId =
      GeneratedColumn<String>(
        'requested_by_staff_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES users (id)',
        ),
      );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 2000,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReferralRequestStatus, String>
  status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<ReferralRequestStatus>(
        $ReferralRequestsTable.$converterstatus,
      );
  static const VerificationMeta _decidedByAdminIdMeta = const VerificationMeta(
    'decidedByAdminId',
  );
  @override
  late final GeneratedColumn<String> decidedByAdminId = GeneratedColumn<String>(
    'decided_by_admin_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _decisionNoteMeta = const VerificationMeta(
    'decisionNote',
  );
  @override
  late final GeneratedColumn<String> decisionNote = GeneratedColumn<String>(
    'decision_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _decidedAtMeta = const VerificationMeta(
    'decidedAt',
  );
  @override
  late final GeneratedColumn<DateTime> decidedAt = GeneratedColumn<DateTime>(
    'decided_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
  static const VerificationMeta _ownerStaffIdMeta = const VerificationMeta(
    'ownerStaffId',
  );
  @override
  late final GeneratedColumn<String> ownerStaffId = GeneratedColumn<String>(
    'owner_staff_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _coverageStaffIdMeta = const VerificationMeta(
    'coverageStaffId',
  );
  @override
  late final GeneratedColumn<String> coverageStaffId = GeneratedColumn<String>(
    'coverage_staff_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE SET NULL',
    ),
  );
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
  late final GeneratedColumnWithTypeConverter<WorkPriority, String> priority =
      GeneratedColumn<String>(
        'priority',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('routine'),
      ).withConverter<WorkPriority>($ReferralRequestsTable.$converterpriority);
  static const VerificationMeta _handoverNoteMeta = const VerificationMeta(
    'handoverNote',
  );
  @override
  late final GeneratedColumn<String> handoverNote = GeneratedColumn<String>(
    'handover_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    appointmentId,
    requestedByStaffId,
    reason,
    status,
    decidedByAdminId,
    decisionNote,
    decidedAt,
    createdAt,
    ownerStaffId,
    coverageStaffId,
    dueAt,
    priority,
    handoverNote,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'referral_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReferralRequestRow> instance, {
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
    if (data.containsKey('appointment_id')) {
      context.handle(
        _appointmentIdMeta,
        appointmentId.isAcceptableOrUnknown(
          data['appointment_id']!,
          _appointmentIdMeta,
        ),
      );
    }
    if (data.containsKey('requested_by_staff_id')) {
      context.handle(
        _requestedByStaffIdMeta,
        requestedByStaffId.isAcceptableOrUnknown(
          data['requested_by_staff_id']!,
          _requestedByStaffIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestedByStaffIdMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('decided_by_admin_id')) {
      context.handle(
        _decidedByAdminIdMeta,
        decidedByAdminId.isAcceptableOrUnknown(
          data['decided_by_admin_id']!,
          _decidedByAdminIdMeta,
        ),
      );
    }
    if (data.containsKey('decision_note')) {
      context.handle(
        _decisionNoteMeta,
        decisionNote.isAcceptableOrUnknown(
          data['decision_note']!,
          _decisionNoteMeta,
        ),
      );
    }
    if (data.containsKey('decided_at')) {
      context.handle(
        _decidedAtMeta,
        decidedAt.isAcceptableOrUnknown(data['decided_at']!, _decidedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('owner_staff_id')) {
      context.handle(
        _ownerStaffIdMeta,
        ownerStaffId.isAcceptableOrUnknown(
          data['owner_staff_id']!,
          _ownerStaffIdMeta,
        ),
      );
    }
    if (data.containsKey('coverage_staff_id')) {
      context.handle(
        _coverageStaffIdMeta,
        coverageStaffId.isAcceptableOrUnknown(
          data['coverage_staff_id']!,
          _coverageStaffIdMeta,
        ),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('handover_note')) {
      context.handle(
        _handoverNoteMeta,
        handoverNote.isAcceptableOrUnknown(
          data['handover_note']!,
          _handoverNoteMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReferralRequestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReferralRequestRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      appointmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appointment_id'],
      ),
      requestedByStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requested_by_staff_id'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      status: $ReferralRequestsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      decidedByAdminId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decided_by_admin_id'],
      ),
      decisionNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decision_note'],
      ),
      decidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}decided_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      ownerStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_staff_id'],
      ),
      coverageStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coverage_staff_id'],
      ),
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      priority: $ReferralRequestsTable.$converterpriority.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}priority'],
        )!,
      ),
      handoverNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}handover_note'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $ReferralRequestsTable createAlias(String alias) {
    return $ReferralRequestsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ReferralRequestStatus, String, String>
  $converterstatus = const EnumNameConverter<ReferralRequestStatus>(
    ReferralRequestStatus.values,
  );
  static JsonTypeConverter2<WorkPriority, String, String> $converterpriority =
      const EnumNameConverter<WorkPriority>(WorkPriority.values);
}

class ReferralRequestRow extends DataClass
    implements Insertable<ReferralRequestRow> {
  final String id;
  final String patientId;
  final String? appointmentId;
  final String requestedByStaffId;
  final String reason;
  final ReferralRequestStatus status;
  final String? decidedByAdminId;
  final String? decisionNote;
  final DateTime? decidedAt;
  final DateTime createdAt;
  final String? ownerStaffId;
  final String? coverageStaffId;
  final DateTime? dueAt;
  final WorkPriority priority;
  final String? handoverNote;

  /// Optimistic-concurrency version (trigger-bumped, schema v19).
  final int version;
  const ReferralRequestRow({
    required this.id,
    required this.patientId,
    this.appointmentId,
    required this.requestedByStaffId,
    required this.reason,
    required this.status,
    this.decidedByAdminId,
    this.decisionNote,
    this.decidedAt,
    required this.createdAt,
    this.ownerStaffId,
    this.coverageStaffId,
    this.dueAt,
    required this.priority,
    this.handoverNote,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    if (!nullToAbsent || appointmentId != null) {
      map['appointment_id'] = Variable<String>(appointmentId);
    }
    map['requested_by_staff_id'] = Variable<String>(requestedByStaffId);
    map['reason'] = Variable<String>(reason);
    {
      map['status'] = Variable<String>(
        $ReferralRequestsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || decidedByAdminId != null) {
      map['decided_by_admin_id'] = Variable<String>(decidedByAdminId);
    }
    if (!nullToAbsent || decisionNote != null) {
      map['decision_note'] = Variable<String>(decisionNote);
    }
    if (!nullToAbsent || decidedAt != null) {
      map['decided_at'] = Variable<DateTime>(decidedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || ownerStaffId != null) {
      map['owner_staff_id'] = Variable<String>(ownerStaffId);
    }
    if (!nullToAbsent || coverageStaffId != null) {
      map['coverage_staff_id'] = Variable<String>(coverageStaffId);
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    {
      map['priority'] = Variable<String>(
        $ReferralRequestsTable.$converterpriority.toSql(priority),
      );
    }
    if (!nullToAbsent || handoverNote != null) {
      map['handover_note'] = Variable<String>(handoverNote);
    }
    map['version'] = Variable<int>(version);
    return map;
  }

  ReferralRequestsCompanion toCompanion(bool nullToAbsent) {
    return ReferralRequestsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      appointmentId: appointmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(appointmentId),
      requestedByStaffId: Value(requestedByStaffId),
      reason: Value(reason),
      status: Value(status),
      decidedByAdminId: decidedByAdminId == null && nullToAbsent
          ? const Value.absent()
          : Value(decidedByAdminId),
      decisionNote: decisionNote == null && nullToAbsent
          ? const Value.absent()
          : Value(decisionNote),
      decidedAt: decidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(decidedAt),
      createdAt: Value(createdAt),
      ownerStaffId: ownerStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerStaffId),
      coverageStaffId: coverageStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverageStaffId),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      priority: Value(priority),
      handoverNote: handoverNote == null && nullToAbsent
          ? const Value.absent()
          : Value(handoverNote),
      version: Value(version),
    );
  }

  factory ReferralRequestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReferralRequestRow(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      appointmentId: serializer.fromJson<String?>(json['appointmentId']),
      requestedByStaffId: serializer.fromJson<String>(
        json['requestedByStaffId'],
      ),
      reason: serializer.fromJson<String>(json['reason']),
      status: $ReferralRequestsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      decidedByAdminId: serializer.fromJson<String?>(json['decidedByAdminId']),
      decisionNote: serializer.fromJson<String?>(json['decisionNote']),
      decidedAt: serializer.fromJson<DateTime?>(json['decidedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      ownerStaffId: serializer.fromJson<String?>(json['ownerStaffId']),
      coverageStaffId: serializer.fromJson<String?>(json['coverageStaffId']),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      priority: $ReferralRequestsTable.$converterpriority.fromJson(
        serializer.fromJson<String>(json['priority']),
      ),
      handoverNote: serializer.fromJson<String?>(json['handoverNote']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'appointmentId': serializer.toJson<String?>(appointmentId),
      'requestedByStaffId': serializer.toJson<String>(requestedByStaffId),
      'reason': serializer.toJson<String>(reason),
      'status': serializer.toJson<String>(
        $ReferralRequestsTable.$converterstatus.toJson(status),
      ),
      'decidedByAdminId': serializer.toJson<String?>(decidedByAdminId),
      'decisionNote': serializer.toJson<String?>(decisionNote),
      'decidedAt': serializer.toJson<DateTime?>(decidedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'ownerStaffId': serializer.toJson<String?>(ownerStaffId),
      'coverageStaffId': serializer.toJson<String?>(coverageStaffId),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'priority': serializer.toJson<String>(
        $ReferralRequestsTable.$converterpriority.toJson(priority),
      ),
      'handoverNote': serializer.toJson<String?>(handoverNote),
      'version': serializer.toJson<int>(version),
    };
  }

  ReferralRequestRow copyWith({
    String? id,
    String? patientId,
    Value<String?> appointmentId = const Value.absent(),
    String? requestedByStaffId,
    String? reason,
    ReferralRequestStatus? status,
    Value<String?> decidedByAdminId = const Value.absent(),
    Value<String?> decisionNote = const Value.absent(),
    Value<DateTime?> decidedAt = const Value.absent(),
    DateTime? createdAt,
    Value<String?> ownerStaffId = const Value.absent(),
    Value<String?> coverageStaffId = const Value.absent(),
    Value<DateTime?> dueAt = const Value.absent(),
    WorkPriority? priority,
    Value<String?> handoverNote = const Value.absent(),
    int? version,
  }) => ReferralRequestRow(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    appointmentId: appointmentId.present
        ? appointmentId.value
        : this.appointmentId,
    requestedByStaffId: requestedByStaffId ?? this.requestedByStaffId,
    reason: reason ?? this.reason,
    status: status ?? this.status,
    decidedByAdminId: decidedByAdminId.present
        ? decidedByAdminId.value
        : this.decidedByAdminId,
    decisionNote: decisionNote.present ? decisionNote.value : this.decisionNote,
    decidedAt: decidedAt.present ? decidedAt.value : this.decidedAt,
    createdAt: createdAt ?? this.createdAt,
    ownerStaffId: ownerStaffId.present ? ownerStaffId.value : this.ownerStaffId,
    coverageStaffId: coverageStaffId.present
        ? coverageStaffId.value
        : this.coverageStaffId,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    priority: priority ?? this.priority,
    handoverNote: handoverNote.present ? handoverNote.value : this.handoverNote,
    version: version ?? this.version,
  );
  ReferralRequestRow copyWithCompanion(ReferralRequestsCompanion data) {
    return ReferralRequestRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      appointmentId: data.appointmentId.present
          ? data.appointmentId.value
          : this.appointmentId,
      requestedByStaffId: data.requestedByStaffId.present
          ? data.requestedByStaffId.value
          : this.requestedByStaffId,
      reason: data.reason.present ? data.reason.value : this.reason,
      status: data.status.present ? data.status.value : this.status,
      decidedByAdminId: data.decidedByAdminId.present
          ? data.decidedByAdminId.value
          : this.decidedByAdminId,
      decisionNote: data.decisionNote.present
          ? data.decisionNote.value
          : this.decisionNote,
      decidedAt: data.decidedAt.present ? data.decidedAt.value : this.decidedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      ownerStaffId: data.ownerStaffId.present
          ? data.ownerStaffId.value
          : this.ownerStaffId,
      coverageStaffId: data.coverageStaffId.present
          ? data.coverageStaffId.value
          : this.coverageStaffId,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      priority: data.priority.present ? data.priority.value : this.priority,
      handoverNote: data.handoverNote.present
          ? data.handoverNote.value
          : this.handoverNote,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReferralRequestRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('requestedByStaffId: $requestedByStaffId, ')
          ..write('reason: $reason, ')
          ..write('status: $status, ')
          ..write('decidedByAdminId: $decidedByAdminId, ')
          ..write('decisionNote: $decisionNote, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('ownerStaffId: $ownerStaffId, ')
          ..write('coverageStaffId: $coverageStaffId, ')
          ..write('dueAt: $dueAt, ')
          ..write('priority: $priority, ')
          ..write('handoverNote: $handoverNote, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    appointmentId,
    requestedByStaffId,
    reason,
    status,
    decidedByAdminId,
    decisionNote,
    decidedAt,
    createdAt,
    ownerStaffId,
    coverageStaffId,
    dueAt,
    priority,
    handoverNote,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReferralRequestRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.appointmentId == this.appointmentId &&
          other.requestedByStaffId == this.requestedByStaffId &&
          other.reason == this.reason &&
          other.status == this.status &&
          other.decidedByAdminId == this.decidedByAdminId &&
          other.decisionNote == this.decisionNote &&
          other.decidedAt == this.decidedAt &&
          other.createdAt == this.createdAt &&
          other.ownerStaffId == this.ownerStaffId &&
          other.coverageStaffId == this.coverageStaffId &&
          other.dueAt == this.dueAt &&
          other.priority == this.priority &&
          other.handoverNote == this.handoverNote &&
          other.version == this.version);
}

class ReferralRequestsCompanion extends UpdateCompanion<ReferralRequestRow> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String?> appointmentId;
  final Value<String> requestedByStaffId;
  final Value<String> reason;
  final Value<ReferralRequestStatus> status;
  final Value<String?> decidedByAdminId;
  final Value<String?> decisionNote;
  final Value<DateTime?> decidedAt;
  final Value<DateTime> createdAt;
  final Value<String?> ownerStaffId;
  final Value<String?> coverageStaffId;
  final Value<DateTime?> dueAt;
  final Value<WorkPriority> priority;
  final Value<String?> handoverNote;
  final Value<int> version;
  final Value<int> rowid;
  const ReferralRequestsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.appointmentId = const Value.absent(),
    this.requestedByStaffId = const Value.absent(),
    this.reason = const Value.absent(),
    this.status = const Value.absent(),
    this.decidedByAdminId = const Value.absent(),
    this.decisionNote = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.ownerStaffId = const Value.absent(),
    this.coverageStaffId = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.handoverNote = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReferralRequestsCompanion.insert({
    required String id,
    required String patientId,
    this.appointmentId = const Value.absent(),
    required String requestedByStaffId,
    required String reason,
    this.status = const Value.absent(),
    this.decidedByAdminId = const Value.absent(),
    this.decisionNote = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.ownerStaffId = const Value.absent(),
    this.coverageStaffId = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.handoverNote = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       requestedByStaffId = Value(requestedByStaffId),
       reason = Value(reason);
  static Insertable<ReferralRequestRow> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? appointmentId,
    Expression<String>? requestedByStaffId,
    Expression<String>? reason,
    Expression<String>? status,
    Expression<String>? decidedByAdminId,
    Expression<String>? decisionNote,
    Expression<DateTime>? decidedAt,
    Expression<DateTime>? createdAt,
    Expression<String>? ownerStaffId,
    Expression<String>? coverageStaffId,
    Expression<DateTime>? dueAt,
    Expression<String>? priority,
    Expression<String>? handoverNote,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (requestedByStaffId != null)
        'requested_by_staff_id': requestedByStaffId,
      if (reason != null) 'reason': reason,
      if (status != null) 'status': status,
      if (decidedByAdminId != null) 'decided_by_admin_id': decidedByAdminId,
      if (decisionNote != null) 'decision_note': decisionNote,
      if (decidedAt != null) 'decided_at': decidedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (ownerStaffId != null) 'owner_staff_id': ownerStaffId,
      if (coverageStaffId != null) 'coverage_staff_id': coverageStaffId,
      if (dueAt != null) 'due_at': dueAt,
      if (priority != null) 'priority': priority,
      if (handoverNote != null) 'handover_note': handoverNote,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReferralRequestsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String?>? appointmentId,
    Value<String>? requestedByStaffId,
    Value<String>? reason,
    Value<ReferralRequestStatus>? status,
    Value<String?>? decidedByAdminId,
    Value<String?>? decisionNote,
    Value<DateTime?>? decidedAt,
    Value<DateTime>? createdAt,
    Value<String?>? ownerStaffId,
    Value<String?>? coverageStaffId,
    Value<DateTime?>? dueAt,
    Value<WorkPriority>? priority,
    Value<String?>? handoverNote,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return ReferralRequestsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      appointmentId: appointmentId ?? this.appointmentId,
      requestedByStaffId: requestedByStaffId ?? this.requestedByStaffId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      decidedByAdminId: decidedByAdminId ?? this.decidedByAdminId,
      decisionNote: decisionNote ?? this.decisionNote,
      decidedAt: decidedAt ?? this.decidedAt,
      createdAt: createdAt ?? this.createdAt,
      ownerStaffId: ownerStaffId ?? this.ownerStaffId,
      coverageStaffId: coverageStaffId ?? this.coverageStaffId,
      dueAt: dueAt ?? this.dueAt,
      priority: priority ?? this.priority,
      handoverNote: handoverNote ?? this.handoverNote,
      version: version ?? this.version,
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
    if (appointmentId.present) {
      map['appointment_id'] = Variable<String>(appointmentId.value);
    }
    if (requestedByStaffId.present) {
      map['requested_by_staff_id'] = Variable<String>(requestedByStaffId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ReferralRequestsTable.$converterstatus.toSql(status.value),
      );
    }
    if (decidedByAdminId.present) {
      map['decided_by_admin_id'] = Variable<String>(decidedByAdminId.value);
    }
    if (decisionNote.present) {
      map['decision_note'] = Variable<String>(decisionNote.value);
    }
    if (decidedAt.present) {
      map['decided_at'] = Variable<DateTime>(decidedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (ownerStaffId.present) {
      map['owner_staff_id'] = Variable<String>(ownerStaffId.value);
    }
    if (coverageStaffId.present) {
      map['coverage_staff_id'] = Variable<String>(coverageStaffId.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(
        $ReferralRequestsTable.$converterpriority.toSql(priority.value),
      );
    }
    if (handoverNote.present) {
      map['handover_note'] = Variable<String>(handoverNote.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReferralRequestsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('requestedByStaffId: $requestedByStaffId, ')
          ..write('reason: $reason, ')
          ..write('status: $status, ')
          ..write('decidedByAdminId: $decidedByAdminId, ')
          ..write('decisionNote: $decisionNote, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('ownerStaffId: $ownerStaffId, ')
          ..write('coverageStaffId: $coverageStaffId, ')
          ..write('dueAt: $dueAt, ')
          ..write('priority: $priority, ')
          ..write('handoverNote: $handoverNote, ')
          ..write('version: $version, ')
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
  static const VerificationMeta _subjectPatientIdMeta = const VerificationMeta(
    'subjectPatientId',
  );
  @override
  late final GeneratedColumn<String> subjectPatientId = GeneratedColumn<String>(
    'subject_patient_id',
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
    subjectPatientId,
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
    if (data.containsKey('subject_patient_id')) {
      context.handle(
        _subjectPatientIdMeta,
        subjectPatientId.isAcceptableOrUnknown(
          data['subject_patient_id']!,
          _subjectPatientIdMeta,
        ),
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
      subjectPatientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_patient_id'],
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

  /// The patient whose data the action touched, when that differs from (or
  /// is not implied by) the actor — e.g. a proxy acting for a dependent.
  final String? subjectPatientId;
  final DateTime at;
  const AuditLogRow({
    required this.id,
    this.actorUserId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.detail,
    this.subjectPatientId,
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
    if (!nullToAbsent || subjectPatientId != null) {
      map['subject_patient_id'] = Variable<String>(subjectPatientId);
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
      subjectPatientId: subjectPatientId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectPatientId),
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
      subjectPatientId: serializer.fromJson<String?>(json['subjectPatientId']),
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
      'subjectPatientId': serializer.toJson<String?>(subjectPatientId),
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
    Value<String?> subjectPatientId = const Value.absent(),
    DateTime? at,
  }) => AuditLogRow(
    id: id ?? this.id,
    actorUserId: actorUserId.present ? actorUserId.value : this.actorUserId,
    action: action ?? this.action,
    entityType: entityType ?? this.entityType,
    entityId: entityId.present ? entityId.value : this.entityId,
    detail: detail.present ? detail.value : this.detail,
    subjectPatientId: subjectPatientId.present
        ? subjectPatientId.value
        : this.subjectPatientId,
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
      subjectPatientId: data.subjectPatientId.present
          ? data.subjectPatientId.value
          : this.subjectPatientId,
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
          ..write('subjectPatientId: $subjectPatientId, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    actorUserId,
    action,
    entityType,
    entityId,
    detail,
    subjectPatientId,
    at,
  );
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
          other.subjectPatientId == this.subjectPatientId &&
          other.at == this.at);
}

class AuditLogCompanion extends UpdateCompanion<AuditLogRow> {
  final Value<String> id;
  final Value<String?> actorUserId;
  final Value<String> action;
  final Value<String> entityType;
  final Value<String?> entityId;
  final Value<String?> detail;
  final Value<String?> subjectPatientId;
  final Value<DateTime> at;
  final Value<int> rowid;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.actorUserId = const Value.absent(),
    this.action = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.detail = const Value.absent(),
    this.subjectPatientId = const Value.absent(),
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
    this.subjectPatientId = const Value.absent(),
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
    Expression<String>? subjectPatientId,
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
      if (subjectPatientId != null) 'subject_patient_id': subjectPatientId,
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
    Value<String?>? subjectPatientId,
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
      subjectPatientId: subjectPatientId ?? this.subjectPatientId,
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
    if (subjectPatientId.present) {
      map['subject_patient_id'] = Variable<String>(subjectPatientId.value);
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
          ..write('subjectPatientId: $subjectPatientId, ')
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
  static const VerificationMeta _clinicOpenDaysMeta = const VerificationMeta(
    'clinicOpenDays',
  );
  @override
  late final GeneratedColumn<String> clinicOpenDays = GeneratedColumn<String>(
    'clinic_open_days',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clinicOpenHourMeta = const VerificationMeta(
    'clinicOpenHour',
  );
  @override
  late final GeneratedColumn<int> clinicOpenHour = GeneratedColumn<int>(
    'clinic_open_hour',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clinicCloseHourMeta = const VerificationMeta(
    'clinicCloseHour',
  );
  @override
  late final GeneratedColumn<int> clinicCloseHour = GeneratedColumn<int>(
    'clinic_close_hour',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    clinicOpenDays,
    clinicOpenHour,
    clinicCloseHour,
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
    if (data.containsKey('clinic_open_days')) {
      context.handle(
        _clinicOpenDaysMeta,
        clinicOpenDays.isAcceptableOrUnknown(
          data['clinic_open_days']!,
          _clinicOpenDaysMeta,
        ),
      );
    }
    if (data.containsKey('clinic_open_hour')) {
      context.handle(
        _clinicOpenHourMeta,
        clinicOpenHour.isAcceptableOrUnknown(
          data['clinic_open_hour']!,
          _clinicOpenHourMeta,
        ),
      );
    }
    if (data.containsKey('clinic_close_hour')) {
      context.handle(
        _clinicCloseHourMeta,
        clinicCloseHour.isAcceptableOrUnknown(
          data['clinic_close_hour']!,
          _clinicCloseHourMeta,
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
      clinicOpenDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clinic_open_days'],
      ),
      clinicOpenHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}clinic_open_hour'],
      ),
      clinicCloseHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}clinic_close_hour'],
      ),
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

  /// Clinic-wide opening schedule — shared operational data, so it lives
  /// here rather than in one device's SharedPreferences. Null until first
  /// saved (the app then uses its built-in default: every day, 08:00-20:00).
  /// Open days are ISO weekdays (1 = Monday), comma-separated.
  final String? clinicOpenDays;
  final int? clinicOpenHour;
  final int? clinicCloseHour;
  final DateTime updatedAt;
  const AppSettingsRow({
    required this.id,
    required this.aiEnabled,
    required this.mockMode,
    required this.modelId,
    required this.aiTaskWeight,
    required this.seedVersion,
    this.clinicOpenDays,
    this.clinicOpenHour,
    this.clinicCloseHour,
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
    if (!nullToAbsent || clinicOpenDays != null) {
      map['clinic_open_days'] = Variable<String>(clinicOpenDays);
    }
    if (!nullToAbsent || clinicOpenHour != null) {
      map['clinic_open_hour'] = Variable<int>(clinicOpenHour);
    }
    if (!nullToAbsent || clinicCloseHour != null) {
      map['clinic_close_hour'] = Variable<int>(clinicCloseHour);
    }
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
      clinicOpenDays: clinicOpenDays == null && nullToAbsent
          ? const Value.absent()
          : Value(clinicOpenDays),
      clinicOpenHour: clinicOpenHour == null && nullToAbsent
          ? const Value.absent()
          : Value(clinicOpenHour),
      clinicCloseHour: clinicCloseHour == null && nullToAbsent
          ? const Value.absent()
          : Value(clinicCloseHour),
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
      clinicOpenDays: serializer.fromJson<String?>(json['clinicOpenDays']),
      clinicOpenHour: serializer.fromJson<int?>(json['clinicOpenHour']),
      clinicCloseHour: serializer.fromJson<int?>(json['clinicCloseHour']),
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
      'clinicOpenDays': serializer.toJson<String?>(clinicOpenDays),
      'clinicOpenHour': serializer.toJson<int?>(clinicOpenHour),
      'clinicCloseHour': serializer.toJson<int?>(clinicCloseHour),
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
    Value<String?> clinicOpenDays = const Value.absent(),
    Value<int?> clinicOpenHour = const Value.absent(),
    Value<int?> clinicCloseHour = const Value.absent(),
    DateTime? updatedAt,
  }) => AppSettingsRow(
    id: id ?? this.id,
    aiEnabled: aiEnabled ?? this.aiEnabled,
    mockMode: mockMode ?? this.mockMode,
    modelId: modelId ?? this.modelId,
    aiTaskWeight: aiTaskWeight ?? this.aiTaskWeight,
    seedVersion: seedVersion ?? this.seedVersion,
    clinicOpenDays: clinicOpenDays.present
        ? clinicOpenDays.value
        : this.clinicOpenDays,
    clinicOpenHour: clinicOpenHour.present
        ? clinicOpenHour.value
        : this.clinicOpenHour,
    clinicCloseHour: clinicCloseHour.present
        ? clinicCloseHour.value
        : this.clinicCloseHour,
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
      clinicOpenDays: data.clinicOpenDays.present
          ? data.clinicOpenDays.value
          : this.clinicOpenDays,
      clinicOpenHour: data.clinicOpenHour.present
          ? data.clinicOpenHour.value
          : this.clinicOpenHour,
      clinicCloseHour: data.clinicCloseHour.present
          ? data.clinicCloseHour.value
          : this.clinicCloseHour,
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
          ..write('clinicOpenDays: $clinicOpenDays, ')
          ..write('clinicOpenHour: $clinicOpenHour, ')
          ..write('clinicCloseHour: $clinicCloseHour, ')
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
    clinicOpenDays,
    clinicOpenHour,
    clinicCloseHour,
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
          other.clinicOpenDays == this.clinicOpenDays &&
          other.clinicOpenHour == this.clinicOpenHour &&
          other.clinicCloseHour == this.clinicCloseHour &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<int> id;
  final Value<bool> aiEnabled;
  final Value<bool> mockMode;
  final Value<String> modelId;
  final Value<double> aiTaskWeight;
  final Value<int> seedVersion;
  final Value<String?> clinicOpenDays;
  final Value<int?> clinicOpenHour;
  final Value<int?> clinicCloseHour;
  final Value<DateTime> updatedAt;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.aiEnabled = const Value.absent(),
    this.mockMode = const Value.absent(),
    this.modelId = const Value.absent(),
    this.aiTaskWeight = const Value.absent(),
    this.seedVersion = const Value.absent(),
    this.clinicOpenDays = const Value.absent(),
    this.clinicOpenHour = const Value.absent(),
    this.clinicCloseHour = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.aiEnabled = const Value.absent(),
    this.mockMode = const Value.absent(),
    this.modelId = const Value.absent(),
    this.aiTaskWeight = const Value.absent(),
    this.seedVersion = const Value.absent(),
    this.clinicOpenDays = const Value.absent(),
    this.clinicOpenHour = const Value.absent(),
    this.clinicCloseHour = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<AppSettingsRow> custom({
    Expression<int>? id,
    Expression<bool>? aiEnabled,
    Expression<bool>? mockMode,
    Expression<String>? modelId,
    Expression<double>? aiTaskWeight,
    Expression<int>? seedVersion,
    Expression<String>? clinicOpenDays,
    Expression<int>? clinicOpenHour,
    Expression<int>? clinicCloseHour,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aiEnabled != null) 'ai_enabled': aiEnabled,
      if (mockMode != null) 'mock_mode': mockMode,
      if (modelId != null) 'model_id': modelId,
      if (aiTaskWeight != null) 'ai_task_weight': aiTaskWeight,
      if (seedVersion != null) 'seed_version': seedVersion,
      if (clinicOpenDays != null) 'clinic_open_days': clinicOpenDays,
      if (clinicOpenHour != null) 'clinic_open_hour': clinicOpenHour,
      if (clinicCloseHour != null) 'clinic_close_hour': clinicCloseHour,
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
    Value<String?>? clinicOpenDays,
    Value<int?>? clinicOpenHour,
    Value<int?>? clinicCloseHour,
    Value<DateTime>? updatedAt,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      mockMode: mockMode ?? this.mockMode,
      modelId: modelId ?? this.modelId,
      aiTaskWeight: aiTaskWeight ?? this.aiTaskWeight,
      seedVersion: seedVersion ?? this.seedVersion,
      clinicOpenDays: clinicOpenDays ?? this.clinicOpenDays,
      clinicOpenHour: clinicOpenHour ?? this.clinicOpenHour,
      clinicCloseHour: clinicCloseHour ?? this.clinicCloseHour,
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
    if (clinicOpenDays.present) {
      map['clinic_open_days'] = Variable<String>(clinicOpenDays.value);
    }
    if (clinicOpenHour.present) {
      map['clinic_open_hour'] = Variable<int>(clinicOpenHour.value);
    }
    if (clinicCloseHour.present) {
      map['clinic_close_hour'] = Variable<int>(clinicCloseHour.value);
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
          ..write('clinicOpenDays: $clinicOpenDays, ')
          ..write('clinicOpenHour: $clinicOpenHour, ')
          ..write('clinicCloseHour: $clinicCloseHour, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FeedbacksTable extends Feedbacks
    with TableInfo<$FeedbacksTable, FeedbackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedbacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reporterIdMeta = const VerificationMeta(
    'reporterId',
  );
  @override
  late final GeneratedColumn<String> reporterId = GeneratedColumn<String>(
    'reporter_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<FeedbackCategory, String>
  category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<FeedbackCategory>($FeedbacksTable.$convertercategory);
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FeedbackStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('open'),
      ).withConverter<FeedbackStatus>($FeedbacksTable.$converterstatus);
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
  static const VerificationMeta _handledByAdminIdMeta = const VerificationMeta(
    'handledByAdminId',
  );
  @override
  late final GeneratedColumn<String> handledByAdminId = GeneratedColumn<String>(
    'handled_by_admin_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _handledAtMeta = const VerificationMeta(
    'handledAt',
  );
  @override
  late final GeneratedColumn<DateTime> handledAt = GeneratedColumn<DateTime>(
    'handled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reporterId,
    category,
    message,
    status,
    createdAt,
    handledByAdminId,
    handledAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feedbacks';
  @override
  VerificationContext validateIntegrity(
    Insertable<FeedbackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('reporter_id')) {
      context.handle(
        _reporterIdMeta,
        reporterId.isAcceptableOrUnknown(data['reporter_id']!, _reporterIdMeta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('handled_by_admin_id')) {
      context.handle(
        _handledByAdminIdMeta,
        handledByAdminId.isAcceptableOrUnknown(
          data['handled_by_admin_id']!,
          _handledByAdminIdMeta,
        ),
      );
    }
    if (data.containsKey('handled_at')) {
      context.handle(
        _handledAtMeta,
        handledAt.isAcceptableOrUnknown(data['handled_at']!, _handledAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FeedbackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeedbackRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      reporterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reporter_id'],
      ),
      category: $FeedbacksTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      status: $FeedbacksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      handledByAdminId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}handled_by_admin_id'],
      ),
      handledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}handled_at'],
      ),
    );
  }

  @override
  $FeedbacksTable createAlias(String alias) {
    return $FeedbacksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FeedbackCategory, String, String>
  $convertercategory = const EnumNameConverter<FeedbackCategory>(
    FeedbackCategory.values,
  );
  static JsonTypeConverter2<FeedbackStatus, String, String> $converterstatus =
      const EnumNameConverter<FeedbackStatus>(FeedbackStatus.values);
}

class FeedbackRow extends DataClass implements Insertable<FeedbackRow> {
  final String id;
  final String? reporterId;
  final FeedbackCategory category;
  final String message;
  final FeedbackStatus status;
  final DateTime createdAt;
  final String? handledByAdminId;
  final DateTime? handledAt;
  const FeedbackRow({
    required this.id,
    this.reporterId,
    required this.category,
    required this.message,
    required this.status,
    required this.createdAt,
    this.handledByAdminId,
    this.handledAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || reporterId != null) {
      map['reporter_id'] = Variable<String>(reporterId);
    }
    {
      map['category'] = Variable<String>(
        $FeedbacksTable.$convertercategory.toSql(category),
      );
    }
    map['message'] = Variable<String>(message);
    {
      map['status'] = Variable<String>(
        $FeedbacksTable.$converterstatus.toSql(status),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || handledByAdminId != null) {
      map['handled_by_admin_id'] = Variable<String>(handledByAdminId);
    }
    if (!nullToAbsent || handledAt != null) {
      map['handled_at'] = Variable<DateTime>(handledAt);
    }
    return map;
  }

  FeedbacksCompanion toCompanion(bool nullToAbsent) {
    return FeedbacksCompanion(
      id: Value(id),
      reporterId: reporterId == null && nullToAbsent
          ? const Value.absent()
          : Value(reporterId),
      category: Value(category),
      message: Value(message),
      status: Value(status),
      createdAt: Value(createdAt),
      handledByAdminId: handledByAdminId == null && nullToAbsent
          ? const Value.absent()
          : Value(handledByAdminId),
      handledAt: handledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(handledAt),
    );
  }

  factory FeedbackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeedbackRow(
      id: serializer.fromJson<String>(json['id']),
      reporterId: serializer.fromJson<String?>(json['reporterId']),
      category: $FeedbacksTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
      message: serializer.fromJson<String>(json['message']),
      status: $FeedbacksTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      handledByAdminId: serializer.fromJson<String?>(json['handledByAdminId']),
      handledAt: serializer.fromJson<DateTime?>(json['handledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'reporterId': serializer.toJson<String?>(reporterId),
      'category': serializer.toJson<String>(
        $FeedbacksTable.$convertercategory.toJson(category),
      ),
      'message': serializer.toJson<String>(message),
      'status': serializer.toJson<String>(
        $FeedbacksTable.$converterstatus.toJson(status),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'handledByAdminId': serializer.toJson<String?>(handledByAdminId),
      'handledAt': serializer.toJson<DateTime?>(handledAt),
    };
  }

  FeedbackRow copyWith({
    String? id,
    Value<String?> reporterId = const Value.absent(),
    FeedbackCategory? category,
    String? message,
    FeedbackStatus? status,
    DateTime? createdAt,
    Value<String?> handledByAdminId = const Value.absent(),
    Value<DateTime?> handledAt = const Value.absent(),
  }) => FeedbackRow(
    id: id ?? this.id,
    reporterId: reporterId.present ? reporterId.value : this.reporterId,
    category: category ?? this.category,
    message: message ?? this.message,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    handledByAdminId: handledByAdminId.present
        ? handledByAdminId.value
        : this.handledByAdminId,
    handledAt: handledAt.present ? handledAt.value : this.handledAt,
  );
  FeedbackRow copyWithCompanion(FeedbacksCompanion data) {
    return FeedbackRow(
      id: data.id.present ? data.id.value : this.id,
      reporterId: data.reporterId.present
          ? data.reporterId.value
          : this.reporterId,
      category: data.category.present ? data.category.value : this.category,
      message: data.message.present ? data.message.value : this.message,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      handledByAdminId: data.handledByAdminId.present
          ? data.handledByAdminId.value
          : this.handledByAdminId,
      handledAt: data.handledAt.present ? data.handledAt.value : this.handledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeedbackRow(')
          ..write('id: $id, ')
          ..write('reporterId: $reporterId, ')
          ..write('category: $category, ')
          ..write('message: $message, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('handledByAdminId: $handledByAdminId, ')
          ..write('handledAt: $handledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    reporterId,
    category,
    message,
    status,
    createdAt,
    handledByAdminId,
    handledAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeedbackRow &&
          other.id == this.id &&
          other.reporterId == this.reporterId &&
          other.category == this.category &&
          other.message == this.message &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.handledByAdminId == this.handledByAdminId &&
          other.handledAt == this.handledAt);
}

class FeedbacksCompanion extends UpdateCompanion<FeedbackRow> {
  final Value<String> id;
  final Value<String?> reporterId;
  final Value<FeedbackCategory> category;
  final Value<String> message;
  final Value<FeedbackStatus> status;
  final Value<DateTime> createdAt;
  final Value<String?> handledByAdminId;
  final Value<DateTime?> handledAt;
  final Value<int> rowid;
  const FeedbacksCompanion({
    this.id = const Value.absent(),
    this.reporterId = const Value.absent(),
    this.category = const Value.absent(),
    this.message = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.handledByAdminId = const Value.absent(),
    this.handledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FeedbacksCompanion.insert({
    required String id,
    this.reporterId = const Value.absent(),
    required FeedbackCategory category,
    required String message,
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.handledByAdminId = const Value.absent(),
    this.handledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       message = Value(message);
  static Insertable<FeedbackRow> custom({
    Expression<String>? id,
    Expression<String>? reporterId,
    Expression<String>? category,
    Expression<String>? message,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<String>? handledByAdminId,
    Expression<DateTime>? handledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reporterId != null) 'reporter_id': reporterId,
      if (category != null) 'category': category,
      if (message != null) 'message': message,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (handledByAdminId != null) 'handled_by_admin_id': handledByAdminId,
      if (handledAt != null) 'handled_at': handledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FeedbacksCompanion copyWith({
    Value<String>? id,
    Value<String?>? reporterId,
    Value<FeedbackCategory>? category,
    Value<String>? message,
    Value<FeedbackStatus>? status,
    Value<DateTime>? createdAt,
    Value<String?>? handledByAdminId,
    Value<DateTime?>? handledAt,
    Value<int>? rowid,
  }) {
    return FeedbacksCompanion(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      category: category ?? this.category,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      handledByAdminId: handledByAdminId ?? this.handledByAdminId,
      handledAt: handledAt ?? this.handledAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (reporterId.present) {
      map['reporter_id'] = Variable<String>(reporterId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $FeedbacksTable.$convertercategory.toSql(category.value),
      );
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $FeedbacksTable.$converterstatus.toSql(status.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (handledByAdminId.present) {
      map['handled_by_admin_id'] = Variable<String>(handledByAdminId.value);
    }
    if (handledAt.present) {
      map['handled_at'] = Variable<DateTime>(handledAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeedbacksCompanion(')
          ..write('id: $id, ')
          ..write('reporterId: $reporterId, ')
          ..write('category: $category, ')
          ..write('message: $message, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('handledByAdminId: $handledByAdminId, ')
          ..write('handledAt: $handledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiUsageLogTable extends AiUsageLog
    with TableInfo<$AiUsageLogTable, AiUsageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiUsageLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AiFeature, String> feature =
      GeneratedColumn<String>(
        'feature',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AiFeature>($AiUsageLogTable.$converterfeature);
  static const VerificationMeta _usedLiveModelMeta = const VerificationMeta(
    'usedLiveModel',
  );
  @override
  late final GeneratedColumn<bool> usedLiveModel = GeneratedColumn<bool>(
    'used_live_model',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("used_live_model" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    userId,
    feature,
    usedLiveModel,
    summary,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_usage_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiUsageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('used_live_model')) {
      context.handle(
        _usedLiveModelMeta,
        usedLiveModel.isAcceptableOrUnknown(
          data['used_live_model']!,
          _usedLiveModelMeta,
        ),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
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
  AiUsageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiUsageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      feature: $AiUsageLogTable.$converterfeature.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}feature'],
        )!,
      ),
      usedLiveModel: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}used_live_model'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $AiUsageLogTable createAlias(String alias) {
    return $AiUsageLogTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AiFeature, String, String> $converterfeature =
      const EnumNameConverter<AiFeature>(AiFeature.values);
}

class AiUsageRow extends DataClass implements Insertable<AiUsageRow> {
  final String id;
  final String? userId;
  final AiFeature feature;
  final bool usedLiveModel;
  final String? summary;
  final DateTime at;
  const AiUsageRow({
    required this.id,
    this.userId,
    required this.feature,
    required this.usedLiveModel,
    this.summary,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    {
      map['feature'] = Variable<String>(
        $AiUsageLogTable.$converterfeature.toSql(feature),
      );
    }
    map['used_live_model'] = Variable<bool>(usedLiveModel);
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  AiUsageLogCompanion toCompanion(bool nullToAbsent) {
    return AiUsageLogCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      feature: Value(feature),
      usedLiveModel: Value(usedLiveModel),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      at: Value(at),
    );
  }

  factory AiUsageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiUsageRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      feature: $AiUsageLogTable.$converterfeature.fromJson(
        serializer.fromJson<String>(json['feature']),
      ),
      usedLiveModel: serializer.fromJson<bool>(json['usedLiveModel']),
      summary: serializer.fromJson<String?>(json['summary']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'feature': serializer.toJson<String>(
        $AiUsageLogTable.$converterfeature.toJson(feature),
      ),
      'usedLiveModel': serializer.toJson<bool>(usedLiveModel),
      'summary': serializer.toJson<String?>(summary),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  AiUsageRow copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    AiFeature? feature,
    bool? usedLiveModel,
    Value<String?> summary = const Value.absent(),
    DateTime? at,
  }) => AiUsageRow(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    feature: feature ?? this.feature,
    usedLiveModel: usedLiveModel ?? this.usedLiveModel,
    summary: summary.present ? summary.value : this.summary,
    at: at ?? this.at,
  );
  AiUsageRow copyWithCompanion(AiUsageLogCompanion data) {
    return AiUsageRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      feature: data.feature.present ? data.feature.value : this.feature,
      usedLiveModel: data.usedLiveModel.present
          ? data.usedLiveModel.value
          : this.usedLiveModel,
      summary: data.summary.present ? data.summary.value : this.summary,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiUsageRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('feature: $feature, ')
          ..write('usedLiveModel: $usedLiveModel, ')
          ..write('summary: $summary, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, feature, usedLiveModel, summary, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiUsageRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.feature == this.feature &&
          other.usedLiveModel == this.usedLiveModel &&
          other.summary == this.summary &&
          other.at == this.at);
}

class AiUsageLogCompanion extends UpdateCompanion<AiUsageRow> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<AiFeature> feature;
  final Value<bool> usedLiveModel;
  final Value<String?> summary;
  final Value<DateTime> at;
  final Value<int> rowid;
  const AiUsageLogCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.feature = const Value.absent(),
    this.usedLiveModel = const Value.absent(),
    this.summary = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiUsageLogCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    required AiFeature feature,
    this.usedLiveModel = const Value.absent(),
    this.summary = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       feature = Value(feature);
  static Insertable<AiUsageRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? feature,
    Expression<bool>? usedLiveModel,
    Expression<String>? summary,
    Expression<DateTime>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (feature != null) 'feature': feature,
      if (usedLiveModel != null) 'used_live_model': usedLiveModel,
      if (summary != null) 'summary': summary,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiUsageLogCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<AiFeature>? feature,
    Value<bool>? usedLiveModel,
    Value<String?>? summary,
    Value<DateTime>? at,
    Value<int>? rowid,
  }) {
    return AiUsageLogCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      feature: feature ?? this.feature,
      usedLiveModel: usedLiveModel ?? this.usedLiveModel,
      summary: summary ?? this.summary,
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (feature.present) {
      map['feature'] = Variable<String>(
        $AiUsageLogTable.$converterfeature.toSql(feature.value),
      );
    }
    if (usedLiveModel.present) {
      map['used_live_model'] = Variable<bool>(usedLiveModel.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
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
    return (StringBuffer('AiUsageLogCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('feature: $feature, ')
          ..write('usedLiveModel: $usedLiveModel, ')
          ..write('summary: $summary, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IdempotencyRecordsTable extends IdempotencyRecords
    with TableInfo<$IdempotencyRecordsTable, IdempotencyRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IdempotencyRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorAccountIdMeta = const VerificationMeta(
    'actorAccountId',
  );
  @override
  late final GeneratedColumn<String> actorAccountId = GeneratedColumn<String>(
    'actor_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resultRefMeta = const VerificationMeta(
    'resultRef',
  );
  @override
  late final GeneratedColumn<String> resultRef = GeneratedColumn<String>(
    'result_ref',
    aliasedName,
    false,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    scope,
    actorAccountId,
    resultRef,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'idempotency_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<IdempotencyRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('actor_account_id')) {
      context.handle(
        _actorAccountIdMeta,
        actorAccountId.isAcceptableOrUnknown(
          data['actor_account_id']!,
          _actorAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('result_ref')) {
      context.handle(
        _resultRefMeta,
        resultRef.isAcceptableOrUnknown(data['result_ref']!, _resultRefMeta),
      );
    } else if (isInserting) {
      context.missing(_resultRefMeta);
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
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  IdempotencyRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IdempotencyRecordRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      actorAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_account_id'],
      ),
      resultRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_ref'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $IdempotencyRecordsTable createAlias(String alias) {
    return $IdempotencyRecordsTable(attachedDatabase, alias);
  }
}

class IdempotencyRecordRow extends DataClass
    implements Insertable<IdempotencyRecordRow> {
  final String key;

  /// What kind of mutation used the key (`appointment.book`,
  /// `billing.pay`…). Reusing a key for a different mutation is refused.
  final String scope;

  /// The signed-in account that made the request. A key is never honoured
  /// for a different account.
  final String? actorAccountId;

  /// Id of the object the mutation produced or changed, returned on retry.
  final String resultRef;
  final DateTime createdAt;
  const IdempotencyRecordRow({
    required this.key,
    required this.scope,
    this.actorAccountId,
    required this.resultRef,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || actorAccountId != null) {
      map['actor_account_id'] = Variable<String>(actorAccountId);
    }
    map['result_ref'] = Variable<String>(resultRef);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  IdempotencyRecordsCompanion toCompanion(bool nullToAbsent) {
    return IdempotencyRecordsCompanion(
      key: Value(key),
      scope: Value(scope),
      actorAccountId: actorAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorAccountId),
      resultRef: Value(resultRef),
      createdAt: Value(createdAt),
    );
  }

  factory IdempotencyRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IdempotencyRecordRow(
      key: serializer.fromJson<String>(json['key']),
      scope: serializer.fromJson<String>(json['scope']),
      actorAccountId: serializer.fromJson<String?>(json['actorAccountId']),
      resultRef: serializer.fromJson<String>(json['resultRef']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'scope': serializer.toJson<String>(scope),
      'actorAccountId': serializer.toJson<String?>(actorAccountId),
      'resultRef': serializer.toJson<String>(resultRef),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  IdempotencyRecordRow copyWith({
    String? key,
    String? scope,
    Value<String?> actorAccountId = const Value.absent(),
    String? resultRef,
    DateTime? createdAt,
  }) => IdempotencyRecordRow(
    key: key ?? this.key,
    scope: scope ?? this.scope,
    actorAccountId: actorAccountId.present
        ? actorAccountId.value
        : this.actorAccountId,
    resultRef: resultRef ?? this.resultRef,
    createdAt: createdAt ?? this.createdAt,
  );
  IdempotencyRecordRow copyWithCompanion(IdempotencyRecordsCompanion data) {
    return IdempotencyRecordRow(
      key: data.key.present ? data.key.value : this.key,
      scope: data.scope.present ? data.scope.value : this.scope,
      actorAccountId: data.actorAccountId.present
          ? data.actorAccountId.value
          : this.actorAccountId,
      resultRef: data.resultRef.present ? data.resultRef.value : this.resultRef,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IdempotencyRecordRow(')
          ..write('key: $key, ')
          ..write('scope: $scope, ')
          ..write('actorAccountId: $actorAccountId, ')
          ..write('resultRef: $resultRef, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(key, scope, actorAccountId, resultRef, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdempotencyRecordRow &&
          other.key == this.key &&
          other.scope == this.scope &&
          other.actorAccountId == this.actorAccountId &&
          other.resultRef == this.resultRef &&
          other.createdAt == this.createdAt);
}

class IdempotencyRecordsCompanion
    extends UpdateCompanion<IdempotencyRecordRow> {
  final Value<String> key;
  final Value<String> scope;
  final Value<String?> actorAccountId;
  final Value<String> resultRef;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const IdempotencyRecordsCompanion({
    this.key = const Value.absent(),
    this.scope = const Value.absent(),
    this.actorAccountId = const Value.absent(),
    this.resultRef = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IdempotencyRecordsCompanion.insert({
    required String key,
    required String scope,
    this.actorAccountId = const Value.absent(),
    required String resultRef,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       scope = Value(scope),
       resultRef = Value(resultRef),
       createdAt = Value(createdAt);
  static Insertable<IdempotencyRecordRow> custom({
    Expression<String>? key,
    Expression<String>? scope,
    Expression<String>? actorAccountId,
    Expression<String>? resultRef,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (scope != null) 'scope': scope,
      if (actorAccountId != null) 'actor_account_id': actorAccountId,
      if (resultRef != null) 'result_ref': resultRef,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IdempotencyRecordsCompanion copyWith({
    Value<String>? key,
    Value<String>? scope,
    Value<String?>? actorAccountId,
    Value<String>? resultRef,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return IdempotencyRecordsCompanion(
      key: key ?? this.key,
      scope: scope ?? this.scope,
      actorAccountId: actorAccountId ?? this.actorAccountId,
      resultRef: resultRef ?? this.resultRef,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (actorAccountId.present) {
      map['actor_account_id'] = Variable<String>(actorAccountId.value);
    }
    if (resultRef.present) {
      map['result_ref'] = Variable<String>(resultRef.value);
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
    return (StringBuffer('IdempotencyRecordsCompanion(')
          ..write('key: $key, ')
          ..write('scope: $scope, ')
          ..write('actorAccountId: $actorAccountId, ')
          ..write('resultRef: $resultRef, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxEventsTable extends OutboxEvents
    with TableInfo<$OutboxEventsTable, OutboxEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<OutboxStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<OutboxStatus>($OutboxEventsTable.$converterstatus);
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _deliveredAtMeta = const VerificationMeta(
    'deliveredAt',
  );
  @override
  late final GeneratedColumn<DateTime> deliveredAt = GeneratedColumn<DateTime>(
    'delivered_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    payload,
    status,
    attempts,
    createdAt,
    nextAttemptAt,
    deliveredAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
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
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('delivered_at')) {
      context.handle(
        _deliveredAtMeta,
        deliveredAt.isAcceptableOrUnknown(
          data['delivered_at']!,
          _deliveredAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: $OutboxEventsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      deliveredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}delivered_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $OutboxEventsTable createAlias(String alias) {
    return $OutboxEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<OutboxStatus, String, String> $converterstatus =
      const EnumNameConverter<OutboxStatus>(OutboxStatus.values);
}

class OutboxEventRow extends DataClass implements Insertable<OutboxEventRow> {
  final String id;

  /// Handler name, e.g. `notification.deliver`.
  final String type;

  /// JSON payload for the handler.
  final String payload;
  final OutboxStatus status;
  final int attempts;
  final DateTime createdAt;
  final DateTime nextAttemptAt;
  final DateTime? deliveredAt;

  /// Last failure reason (never payload content).
  final String? lastError;
  const OutboxEventRow({
    required this.id,
    required this.type,
    required this.payload,
    required this.status,
    required this.attempts,
    required this.createdAt,
    required this.nextAttemptAt,
    this.deliveredAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<String>(payload);
    {
      map['status'] = Variable<String>(
        $OutboxEventsTable.$converterstatus.toSql(status),
      );
    }
    map['attempts'] = Variable<int>(attempts);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    if (!nullToAbsent || deliveredAt != null) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  OutboxEventsCompanion toCompanion(bool nullToAbsent) {
    return OutboxEventsCompanion(
      id: Value(id),
      type: Value(type),
      payload: Value(payload),
      status: Value(status),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
      nextAttemptAt: Value(nextAttemptAt),
      deliveredAt: deliveredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveredAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory OutboxEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEventRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String>(json['payload']),
      status: $OutboxEventsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      attempts: serializer.fromJson<int>(json['attempts']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      deliveredAt: serializer.fromJson<DateTime?>(json['deliveredAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(
        $OutboxEventsTable.$converterstatus.toJson(status),
      ),
      'attempts': serializer.toJson<int>(attempts),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'deliveredAt': serializer.toJson<DateTime?>(deliveredAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  OutboxEventRow copyWith({
    String? id,
    String? type,
    String? payload,
    OutboxStatus? status,
    int? attempts,
    DateTime? createdAt,
    DateTime? nextAttemptAt,
    Value<DateTime?> deliveredAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => OutboxEventRow(
    id: id ?? this.id,
    type: type ?? this.type,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    createdAt: createdAt ?? this.createdAt,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    deliveredAt: deliveredAt.present ? deliveredAt.value : this.deliveredAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  OutboxEventRow copyWithCompanion(OutboxEventsCompanion data) {
    return OutboxEventRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      deliveredAt: data.deliveredAt.present
          ? data.deliveredAt.value
          : this.deliveredAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEventRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    payload,
    status,
    attempts,
    createdAt,
    nextAttemptAt,
    deliveredAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEventRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.createdAt == this.createdAt &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.deliveredAt == this.deliveredAt &&
          other.lastError == this.lastError);
}

class OutboxEventsCompanion extends UpdateCompanion<OutboxEventRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> payload;
  final Value<OutboxStatus> status;
  final Value<int> attempts;
  final Value<DateTime> createdAt;
  final Value<DateTime> nextAttemptAt;
  final Value<DateTime?> deliveredAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const OutboxEventsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.deliveredAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxEventsCompanion.insert({
    required String id,
    required String type,
    required String payload,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    required DateTime createdAt,
    required DateTime nextAttemptAt,
    this.deliveredAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       payload = Value(payload),
       createdAt = Value(createdAt),
       nextAttemptAt = Value(nextAttemptAt);
  static Insertable<OutboxEventRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? nextAttemptAt,
    Expression<DateTime>? deliveredAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (createdAt != null) 'created_at': createdAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (deliveredAt != null) 'delivered_at': deliveredAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? payload,
    Value<OutboxStatus>? status,
    Value<int>? attempts,
    Value<DateTime>? createdAt,
    Value<DateTime>? nextAttemptAt,
    Value<DateTime?>? deliveredAt,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return OutboxEventsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $OutboxEventsTable.$converterstatus.toSql(status.value),
      );
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (deliveredAt.present) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEventsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
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
  late final $PasswordResetRequestsTable passwordResetRequests =
      $PasswordResetRequestsTable(this);
  late final $AccountRecoveryTokensTable accountRecoveryTokens =
      $AccountRecoveryTokensTable(this);
  late final $CareTeamAssignmentsTable careTeamAssignments =
      $CareTeamAssignmentsTable(this);
  late final $StaffCredentialsTable staffCredentials = $StaffCredentialsTable(
    this,
  );
  late final $ScheduleTemplatesTable scheduleTemplates =
      $ScheduleTemplatesTable(this);
  late final $AvailabilityExceptionsTable availabilityExceptions =
      $AvailabilityExceptionsTable(this);
  late final $AppointmentsTable appointments = $AppointmentsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $MedicalRecordsTable medicalRecords = $MedicalRecordsTable(this);
  late final $LabValuesTable labValues = $LabValuesTable(this);
  late final $ResultReviewsTable resultReviews = $ResultReviewsTable(this);
  late final $VitalsTable vitals = $VitalsTable(this);
  late final $MedicationsTable medications = $MedicationsTable(this);
  late final $EncounterDraftsTable encounterDrafts = $EncounterDraftsTable(
    this,
  );
  late final $SignedNotesTable signedNotes = $SignedNotesTable(this);
  late final $SignedNoteAmendmentsTable signedNoteAmendments =
      $SignedNoteAmendmentsTable(this);
  late final $DocumentFilesTable documentFiles = $DocumentFilesTable(this);
  late final $DocumentVerificationsTable documentVerifications =
      $DocumentVerificationsTable(this);
  late final $AiSummariesTable aiSummaries = $AiSummariesTable(this);
  late final $StaffTasksTable staffTasks = $StaffTasksTable(this);
  late final $RiskFlagsTable riskFlags = $RiskFlagsTable(this);
  late final $InvoicesTable invoices = $InvoicesTable(this);
  late final $PaymentMethodsTable paymentMethods = $PaymentMethodsTable(this);
  late final $WalletTransactionsTable walletTransactions =
      $WalletTransactionsTable(this);
  late final $PaymentTransactionsTable paymentTransactions =
      $PaymentTransactionsTable(this);
  late final $SimulatedGatewayChargesTable simulatedGatewayCharges =
      $SimulatedGatewayChargesTable(this);
  late final $FamilyLinksTable familyLinks = $FamilyLinksTable(this);
  late final $NotificationsTable notifications = $NotificationsTable(this);
  late final $SickLeaveCertificatesTable sickLeaveCertificates =
      $SickLeaveCertificatesTable(this);
  late final $CareMessagesTable careMessages = $CareMessagesTable(this);
  late final $HomeVisitRequestsTable homeVisitRequests =
      $HomeVisitRequestsTable(this);
  late final $WalkInTicketsTable walkInTickets = $WalkInTicketsTable(this);
  late final $ReferralRequestsTable referralRequests = $ReferralRequestsTable(
    this,
  );
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $FeedbacksTable feedbacks = $FeedbacksTable(this);
  late final $AiUsageLogTable aiUsageLog = $AiUsageLogTable(this);
  late final $IdempotencyRecordsTable idempotencyRecords =
      $IdempotencyRecordsTable(this);
  late final $OutboxEventsTable outboxEvents = $OutboxEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    departments,
    users,
    patientProfiles,
    staffProfiles,
    passwordResetRequests,
    accountRecoveryTokens,
    careTeamAssignments,
    staffCredentials,
    scheduleTemplates,
    availabilityExceptions,
    appointments,
    reminders,
    medicalRecords,
    labValues,
    resultReviews,
    vitals,
    medications,
    encounterDrafts,
    signedNotes,
    signedNoteAmendments,
    documentFiles,
    documentVerifications,
    aiSummaries,
    staffTasks,
    riskFlags,
    invoices,
    paymentMethods,
    walletTransactions,
    paymentTransactions,
    simulatedGatewayCharges,
    familyLinks,
    notifications,
    sickLeaveCertificates,
    careMessages,
    homeVisitRequests,
    walkInTickets,
    referralRequests,
    auditLog,
    appSettings,
    feedbacks,
    aiUsageLog,
    idempotencyRecords,
    outboxEvents,
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
      result: [TableUpdate('password_reset_requests', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('account_recovery_tokens', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('care_team_assignments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('care_team_assignments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('staff_credentials', kind: UpdateKind.delete)],
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
      result: [TableUpdate('availability_exceptions', kind: UpdateKind.delete)],
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
        'appointments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('medical_records', kind: UpdateKind.update)],
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
      result: [TableUpdate('lab_values', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'medical_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('result_reviews', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('result_reviews', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('result_reviews', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('result_reviews', kind: UpdateKind.update)],
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
        'appointments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('vitals', kind: UpdateKind.update)],
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
        'appointments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('medications', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'appointments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('encounter_drafts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'signed_notes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('signed_note_amendments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'medical_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('document_files', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('document_verifications', kind: UpdateKind.delete)],
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
      result: [TableUpdate('staff_tasks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('risk_flags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('invoices', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'appointments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('invoices', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('payment_methods', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('wallet_transactions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'invoices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('wallet_transactions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('payment_transactions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'invoices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('payment_transactions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('family_links', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('family_links', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('notifications', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sick_leave_certificates', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'appointments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sick_leave_certificates', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('care_messages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('care_messages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('care_messages', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('care_messages', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('home_visit_requests', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'departments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('home_visit_requests', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('home_visit_requests', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('walk_in_tickets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'appointments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('walk_in_tickets', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('walk_in_tickets', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'appointments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('walk_in_tickets', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('referral_requests', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'appointments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('referral_requests', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('referral_requests', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('referral_requests', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('referral_requests', kind: UpdateKind.update)],
    ),
  ]);
}
