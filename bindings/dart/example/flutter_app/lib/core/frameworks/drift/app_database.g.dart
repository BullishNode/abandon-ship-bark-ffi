// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WalletsTable extends Wallets with TableInfo<$WalletsTable, Wallet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalletsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
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
  static const VerificationMeta _networkMeta = const VerificationMeta(
    'network',
  );
  @override
  late final GeneratedColumn<String> network = GeneratedColumn<String>(
    'network',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    network,
    createdAt,
    updatedAt,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Wallet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('network')) {
      context.handle(
        _networkMeta,
        network.isAcceptableOrUnknown(data['network']!, _networkMeta),
      );
    } else if (isInserting) {
      context.missing(_networkMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
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
  Wallet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Wallet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      network: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}network'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
    );
  }

  @override
  $WalletsTable createAlias(String alias) {
    return $WalletsTable(attachedDatabase, alias);
  }
}

class Wallet extends DataClass implements Insertable<Wallet> {
  /// Unique identifier
  final int id;

  /// User-facing name/label for the wallet
  final String name;

  /// Wallet type (bark, etc.) - stored as string
  final String type;

  /// Bitcoin network (mainnet, testnet3, testnet4, signet) - stored as string
  final String network;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last updated timestamp
  final DateTime updatedAt;

  /// Optional description
  final String? description;
  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.network,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['network'] = Variable<String>(network);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  WalletsCompanion toCompanion(bool nullToAbsent) {
    return WalletsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      network: Value(network),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory Wallet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Wallet(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      network: serializer.fromJson<String>(json['network']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'network': serializer.toJson<String>(network),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'description': serializer.toJson<String?>(description),
    };
  }

  Wallet copyWith({
    int? id,
    String? name,
    String? type,
    String? network,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> description = const Value.absent(),
  }) => Wallet(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    network: network ?? this.network,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    description: description.present ? description.value : this.description,
  );
  Wallet copyWithCompanion(WalletsCompanion data) {
    return Wallet(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      network: data.network.present ? data.network.value : this.network,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Wallet(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('network: $network, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, type, network, createdAt, updatedAt, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Wallet &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.network == this.network &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.description == this.description);
}

class WalletsCompanion extends UpdateCompanion<Wallet> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String> network;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> description;
  const WalletsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.network = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.description = const Value.absent(),
  });
  WalletsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String type,
    required String network,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.description = const Value.absent(),
  }) : name = Value(name),
       type = Value(type),
       network = Value(network);
  static Insertable<Wallet> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? network,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? description,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (network != null) 'network': network,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (description != null) 'description': description,
    });
  }

  WalletsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String>? network,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? description,
  }) {
    return WalletsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      network: network ?? this.network,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (network.present) {
      map['network'] = Variable<String>(network.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalletsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('network: $network, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }
}

class $BarkWalletsTable extends BarkWallets
    with TableInfo<$BarkWalletsTable, BarkWallet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BarkWalletsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _walletIdMeta = const VerificationMeta(
    'walletId',
  );
  @override
  late final GeneratedColumn<int> walletId = GeneratedColumn<int>(
    'wallet_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wallets (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 8,
      maxTextLength: 8,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dbPathMeta = const VerificationMeta('dbPath');
  @override
  late final GeneratedColumn<String> dbPath = GeneratedColumn<String>(
    'db_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aspMeta = const VerificationMeta('asp');
  @override
  late final GeneratedColumn<String> asp = GeneratedColumn<String>(
    'asp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vtxoRefreshExpiryThresholdMeta =
      const VerificationMeta('vtxoRefreshExpiryThreshold');
  @override
  late final GeneratedColumn<int> vtxoRefreshExpiryThreshold =
      GeneratedColumn<int>(
        'vtxo_refresh_expiry_threshold',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _vtxoExitMarginMeta = const VerificationMeta(
    'vtxoExitMargin',
  );
  @override
  late final GeneratedColumn<int> vtxoExitMargin = GeneratedColumn<int>(
    'vtxo_exit_margin',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _htlcRecvClaimDeltaMeta =
      const VerificationMeta('htlcRecvClaimDelta');
  @override
  late final GeneratedColumn<int> htlcRecvClaimDelta = GeneratedColumn<int>(
    'htlc_recv_claim_delta',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    walletId,
    fingerprint,
    dbPath,
    asp,
    vtxoRefreshExpiryThreshold,
    vtxoExitMargin,
    htlcRecvClaimDelta,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bark_wallets';
  @override
  VerificationContext validateIntegrity(
    Insertable<BarkWallet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('wallet_id')) {
      context.handle(
        _walletIdMeta,
        walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta),
      );
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('db_path')) {
      context.handle(
        _dbPathMeta,
        dbPath.isAcceptableOrUnknown(data['db_path']!, _dbPathMeta),
      );
    } else if (isInserting) {
      context.missing(_dbPathMeta);
    }
    if (data.containsKey('asp')) {
      context.handle(
        _aspMeta,
        asp.isAcceptableOrUnknown(data['asp']!, _aspMeta),
      );
    } else if (isInserting) {
      context.missing(_aspMeta);
    }
    if (data.containsKey('vtxo_refresh_expiry_threshold')) {
      context.handle(
        _vtxoRefreshExpiryThresholdMeta,
        vtxoRefreshExpiryThreshold.isAcceptableOrUnknown(
          data['vtxo_refresh_expiry_threshold']!,
          _vtxoRefreshExpiryThresholdMeta,
        ),
      );
    }
    if (data.containsKey('vtxo_exit_margin')) {
      context.handle(
        _vtxoExitMarginMeta,
        vtxoExitMargin.isAcceptableOrUnknown(
          data['vtxo_exit_margin']!,
          _vtxoExitMarginMeta,
        ),
      );
    }
    if (data.containsKey('htlc_recv_claim_delta')) {
      context.handle(
        _htlcRecvClaimDeltaMeta,
        htlcRecvClaimDelta.isAcceptableOrUnknown(
          data['htlc_recv_claim_delta']!,
          _htlcRecvClaimDeltaMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {walletId};
  @override
  BarkWallet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BarkWallet(
      walletId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wallet_id'],
      )!,
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      dbPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}db_path'],
      )!,
      asp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asp'],
      )!,
      vtxoRefreshExpiryThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vtxo_refresh_expiry_threshold'],
      ),
      vtxoExitMargin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vtxo_exit_margin'],
      ),
      htlcRecvClaimDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}htlc_recv_claim_delta'],
      ),
    );
  }

  @override
  $BarkWalletsTable createAlias(String alias) {
    return $BarkWalletsTable(attachedDatabase, alias);
  }
}

class BarkWallet extends DataClass implements Insertable<BarkWallet> {
  /// Foreign key to Wallets table
  final int walletId;

  /// Master key fingerprint (hex string)
  final String fingerprint;

  /// Path to the wallet's local database
  final String dbPath;

  /// Ark Service Provider URL
  final String asp;

  /// VTXO refresh expiry threshold in seconds (optional, can be null for server default)
  final int? vtxoRefreshExpiryThreshold;

  /// VTXO exit margin in seconds (optional, can be null for server default)
  final int? vtxoExitMargin;

  /// HTLC receive claim delta in blocks (optional, can be null for server default)
  final int? htlcRecvClaimDelta;
  const BarkWallet({
    required this.walletId,
    required this.fingerprint,
    required this.dbPath,
    required this.asp,
    this.vtxoRefreshExpiryThreshold,
    this.vtxoExitMargin,
    this.htlcRecvClaimDelta,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['wallet_id'] = Variable<int>(walletId);
    map['fingerprint'] = Variable<String>(fingerprint);
    map['db_path'] = Variable<String>(dbPath);
    map['asp'] = Variable<String>(asp);
    if (!nullToAbsent || vtxoRefreshExpiryThreshold != null) {
      map['vtxo_refresh_expiry_threshold'] = Variable<int>(
        vtxoRefreshExpiryThreshold,
      );
    }
    if (!nullToAbsent || vtxoExitMargin != null) {
      map['vtxo_exit_margin'] = Variable<int>(vtxoExitMargin);
    }
    if (!nullToAbsent || htlcRecvClaimDelta != null) {
      map['htlc_recv_claim_delta'] = Variable<int>(htlcRecvClaimDelta);
    }
    return map;
  }

  BarkWalletsCompanion toCompanion(bool nullToAbsent) {
    return BarkWalletsCompanion(
      walletId: Value(walletId),
      fingerprint: Value(fingerprint),
      dbPath: Value(dbPath),
      asp: Value(asp),
      vtxoRefreshExpiryThreshold:
          vtxoRefreshExpiryThreshold == null && nullToAbsent
          ? const Value.absent()
          : Value(vtxoRefreshExpiryThreshold),
      vtxoExitMargin: vtxoExitMargin == null && nullToAbsent
          ? const Value.absent()
          : Value(vtxoExitMargin),
      htlcRecvClaimDelta: htlcRecvClaimDelta == null && nullToAbsent
          ? const Value.absent()
          : Value(htlcRecvClaimDelta),
    );
  }

  factory BarkWallet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BarkWallet(
      walletId: serializer.fromJson<int>(json['walletId']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      dbPath: serializer.fromJson<String>(json['dbPath']),
      asp: serializer.fromJson<String>(json['asp']),
      vtxoRefreshExpiryThreshold: serializer.fromJson<int?>(
        json['vtxoRefreshExpiryThreshold'],
      ),
      vtxoExitMargin: serializer.fromJson<int?>(json['vtxoExitMargin']),
      htlcRecvClaimDelta: serializer.fromJson<int?>(json['htlcRecvClaimDelta']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'walletId': serializer.toJson<int>(walletId),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'dbPath': serializer.toJson<String>(dbPath),
      'asp': serializer.toJson<String>(asp),
      'vtxoRefreshExpiryThreshold': serializer.toJson<int?>(
        vtxoRefreshExpiryThreshold,
      ),
      'vtxoExitMargin': serializer.toJson<int?>(vtxoExitMargin),
      'htlcRecvClaimDelta': serializer.toJson<int?>(htlcRecvClaimDelta),
    };
  }

  BarkWallet copyWith({
    int? walletId,
    String? fingerprint,
    String? dbPath,
    String? asp,
    Value<int?> vtxoRefreshExpiryThreshold = const Value.absent(),
    Value<int?> vtxoExitMargin = const Value.absent(),
    Value<int?> htlcRecvClaimDelta = const Value.absent(),
  }) => BarkWallet(
    walletId: walletId ?? this.walletId,
    fingerprint: fingerprint ?? this.fingerprint,
    dbPath: dbPath ?? this.dbPath,
    asp: asp ?? this.asp,
    vtxoRefreshExpiryThreshold: vtxoRefreshExpiryThreshold.present
        ? vtxoRefreshExpiryThreshold.value
        : this.vtxoRefreshExpiryThreshold,
    vtxoExitMargin: vtxoExitMargin.present
        ? vtxoExitMargin.value
        : this.vtxoExitMargin,
    htlcRecvClaimDelta: htlcRecvClaimDelta.present
        ? htlcRecvClaimDelta.value
        : this.htlcRecvClaimDelta,
  );
  BarkWallet copyWithCompanion(BarkWalletsCompanion data) {
    return BarkWallet(
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      dbPath: data.dbPath.present ? data.dbPath.value : this.dbPath,
      asp: data.asp.present ? data.asp.value : this.asp,
      vtxoRefreshExpiryThreshold: data.vtxoRefreshExpiryThreshold.present
          ? data.vtxoRefreshExpiryThreshold.value
          : this.vtxoRefreshExpiryThreshold,
      vtxoExitMargin: data.vtxoExitMargin.present
          ? data.vtxoExitMargin.value
          : this.vtxoExitMargin,
      htlcRecvClaimDelta: data.htlcRecvClaimDelta.present
          ? data.htlcRecvClaimDelta.value
          : this.htlcRecvClaimDelta,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BarkWallet(')
          ..write('walletId: $walletId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('dbPath: $dbPath, ')
          ..write('asp: $asp, ')
          ..write('vtxoRefreshExpiryThreshold: $vtxoRefreshExpiryThreshold, ')
          ..write('vtxoExitMargin: $vtxoExitMargin, ')
          ..write('htlcRecvClaimDelta: $htlcRecvClaimDelta')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    walletId,
    fingerprint,
    dbPath,
    asp,
    vtxoRefreshExpiryThreshold,
    vtxoExitMargin,
    htlcRecvClaimDelta,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BarkWallet &&
          other.walletId == this.walletId &&
          other.fingerprint == this.fingerprint &&
          other.dbPath == this.dbPath &&
          other.asp == this.asp &&
          other.vtxoRefreshExpiryThreshold == this.vtxoRefreshExpiryThreshold &&
          other.vtxoExitMargin == this.vtxoExitMargin &&
          other.htlcRecvClaimDelta == this.htlcRecvClaimDelta);
}

class BarkWalletsCompanion extends UpdateCompanion<BarkWallet> {
  final Value<int> walletId;
  final Value<String> fingerprint;
  final Value<String> dbPath;
  final Value<String> asp;
  final Value<int?> vtxoRefreshExpiryThreshold;
  final Value<int?> vtxoExitMargin;
  final Value<int?> htlcRecvClaimDelta;
  const BarkWalletsCompanion({
    this.walletId = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.dbPath = const Value.absent(),
    this.asp = const Value.absent(),
    this.vtxoRefreshExpiryThreshold = const Value.absent(),
    this.vtxoExitMargin = const Value.absent(),
    this.htlcRecvClaimDelta = const Value.absent(),
  });
  BarkWalletsCompanion.insert({
    this.walletId = const Value.absent(),
    required String fingerprint,
    required String dbPath,
    required String asp,
    this.vtxoRefreshExpiryThreshold = const Value.absent(),
    this.vtxoExitMargin = const Value.absent(),
    this.htlcRecvClaimDelta = const Value.absent(),
  }) : fingerprint = Value(fingerprint),
       dbPath = Value(dbPath),
       asp = Value(asp);
  static Insertable<BarkWallet> custom({
    Expression<int>? walletId,
    Expression<String>? fingerprint,
    Expression<String>? dbPath,
    Expression<String>? asp,
    Expression<int>? vtxoRefreshExpiryThreshold,
    Expression<int>? vtxoExitMargin,
    Expression<int>? htlcRecvClaimDelta,
  }) {
    return RawValuesInsertable({
      if (walletId != null) 'wallet_id': walletId,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (dbPath != null) 'db_path': dbPath,
      if (asp != null) 'asp': asp,
      if (vtxoRefreshExpiryThreshold != null)
        'vtxo_refresh_expiry_threshold': vtxoRefreshExpiryThreshold,
      if (vtxoExitMargin != null) 'vtxo_exit_margin': vtxoExitMargin,
      if (htlcRecvClaimDelta != null)
        'htlc_recv_claim_delta': htlcRecvClaimDelta,
    });
  }

  BarkWalletsCompanion copyWith({
    Value<int>? walletId,
    Value<String>? fingerprint,
    Value<String>? dbPath,
    Value<String>? asp,
    Value<int?>? vtxoRefreshExpiryThreshold,
    Value<int?>? vtxoExitMargin,
    Value<int?>? htlcRecvClaimDelta,
  }) {
    return BarkWalletsCompanion(
      walletId: walletId ?? this.walletId,
      fingerprint: fingerprint ?? this.fingerprint,
      dbPath: dbPath ?? this.dbPath,
      asp: asp ?? this.asp,
      vtxoRefreshExpiryThreshold:
          vtxoRefreshExpiryThreshold ?? this.vtxoRefreshExpiryThreshold,
      vtxoExitMargin: vtxoExitMargin ?? this.vtxoExitMargin,
      htlcRecvClaimDelta: htlcRecvClaimDelta ?? this.htlcRecvClaimDelta,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (walletId.present) {
      map['wallet_id'] = Variable<int>(walletId.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (dbPath.present) {
      map['db_path'] = Variable<String>(dbPath.value);
    }
    if (asp.present) {
      map['asp'] = Variable<String>(asp.value);
    }
    if (vtxoRefreshExpiryThreshold.present) {
      map['vtxo_refresh_expiry_threshold'] = Variable<int>(
        vtxoRefreshExpiryThreshold.value,
      );
    }
    if (vtxoExitMargin.present) {
      map['vtxo_exit_margin'] = Variable<int>(vtxoExitMargin.value);
    }
    if (htlcRecvClaimDelta.present) {
      map['htlc_recv_claim_delta'] = Variable<int>(htlcRecvClaimDelta.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BarkWalletsCompanion(')
          ..write('walletId: $walletId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('dbPath: $dbPath, ')
          ..write('asp: $asp, ')
          ..write('vtxoRefreshExpiryThreshold: $vtxoRefreshExpiryThreshold, ')
          ..write('vtxoExitMargin: $vtxoExitMargin, ')
          ..write('htlcRecvClaimDelta: $htlcRecvClaimDelta')
          ..write(')'))
        .toString();
  }
}

class $EsploraEndpointsTable extends EsploraEndpoints
    with TableInfo<$EsploraEndpointsTable, EsploraEndpoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EsploraEndpointsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _networkMeta = const VerificationMeta(
    'network',
  );
  @override
  late final GeneratedColumn<String> network = GeneratedColumn<String>(
    'network',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, baseUrl, label, network, priority];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'esplora_endpoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<EsploraEndpoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('network')) {
      context.handle(
        _networkMeta,
        network.isAcceptableOrUnknown(data['network']!, _networkMeta),
      );
    } else if (isInserting) {
      context.missing(_networkMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EsploraEndpoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EsploraEndpoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      network: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}network'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
    );
  }

  @override
  $EsploraEndpointsTable createAlias(String alias) {
    return $EsploraEndpointsTable(attachedDatabase, alias);
  }
}

class EsploraEndpoint extends DataClass implements Insertable<EsploraEndpoint> {
  final int id;
  final String baseUrl;
  final String? label;

  /// Bitcoin network
  final String network;

  /// Priority for selection (lower number = higher priority)
  final int priority;
  const EsploraEndpoint({
    required this.id,
    required this.baseUrl,
    this.label,
    required this.network,
    required this.priority,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['base_url'] = Variable<String>(baseUrl);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['network'] = Variable<String>(network);
    map['priority'] = Variable<int>(priority);
    return map;
  }

  EsploraEndpointsCompanion toCompanion(bool nullToAbsent) {
    return EsploraEndpointsCompanion(
      id: Value(id),
      baseUrl: Value(baseUrl),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      network: Value(network),
      priority: Value(priority),
    );
  }

  factory EsploraEndpoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EsploraEndpoint(
      id: serializer.fromJson<int>(json['id']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      label: serializer.fromJson<String?>(json['label']),
      network: serializer.fromJson<String>(json['network']),
      priority: serializer.fromJson<int>(json['priority']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'label': serializer.toJson<String?>(label),
      'network': serializer.toJson<String>(network),
      'priority': serializer.toJson<int>(priority),
    };
  }

  EsploraEndpoint copyWith({
    int? id,
    String? baseUrl,
    Value<String?> label = const Value.absent(),
    String? network,
    int? priority,
  }) => EsploraEndpoint(
    id: id ?? this.id,
    baseUrl: baseUrl ?? this.baseUrl,
    label: label.present ? label.value : this.label,
    network: network ?? this.network,
    priority: priority ?? this.priority,
  );
  EsploraEndpoint copyWithCompanion(EsploraEndpointsCompanion data) {
    return EsploraEndpoint(
      id: data.id.present ? data.id.value : this.id,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      label: data.label.present ? data.label.value : this.label,
      network: data.network.present ? data.network.value : this.network,
      priority: data.priority.present ? data.priority.value : this.priority,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EsploraEndpoint(')
          ..write('id: $id, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('label: $label, ')
          ..write('network: $network, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, baseUrl, label, network, priority);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EsploraEndpoint &&
          other.id == this.id &&
          other.baseUrl == this.baseUrl &&
          other.label == this.label &&
          other.network == this.network &&
          other.priority == this.priority);
}

class EsploraEndpointsCompanion extends UpdateCompanion<EsploraEndpoint> {
  final Value<int> id;
  final Value<String> baseUrl;
  final Value<String?> label;
  final Value<String> network;
  final Value<int> priority;
  const EsploraEndpointsCompanion({
    this.id = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.label = const Value.absent(),
    this.network = const Value.absent(),
    this.priority = const Value.absent(),
  });
  EsploraEndpointsCompanion.insert({
    this.id = const Value.absent(),
    required String baseUrl,
    this.label = const Value.absent(),
    required String network,
    this.priority = const Value.absent(),
  }) : baseUrl = Value(baseUrl),
       network = Value(network);
  static Insertable<EsploraEndpoint> custom({
    Expression<int>? id,
    Expression<String>? baseUrl,
    Expression<String>? label,
    Expression<String>? network,
    Expression<int>? priority,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseUrl != null) 'base_url': baseUrl,
      if (label != null) 'label': label,
      if (network != null) 'network': network,
      if (priority != null) 'priority': priority,
    });
  }

  EsploraEndpointsCompanion copyWith({
    Value<int>? id,
    Value<String>? baseUrl,
    Value<String?>? label,
    Value<String>? network,
    Value<int>? priority,
  }) {
    return EsploraEndpointsCompanion(
      id: id ?? this.id,
      baseUrl: baseUrl ?? this.baseUrl,
      label: label ?? this.label,
      network: network ?? this.network,
      priority: priority ?? this.priority,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (network.present) {
      map['network'] = Variable<String>(network.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EsploraEndpointsCompanion(')
          ..write('id: $id, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('label: $label, ')
          ..write('network: $network, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WalletsTable wallets = $WalletsTable(this);
  late final $BarkWalletsTable barkWallets = $BarkWalletsTable(this);
  late final $EsploraEndpointsTable esploraEndpoints = $EsploraEndpointsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    wallets,
    barkWallets,
    esploraEndpoints,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'wallets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('bark_wallets', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$WalletsTableCreateCompanionBuilder =
    WalletsCompanion Function({
      Value<int> id,
      required String name,
      required String type,
      required String network,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> description,
    });
typedef $$WalletsTableUpdateCompanionBuilder =
    WalletsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> type,
      Value<String> network,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> description,
    });

final class $$WalletsTableReferences
    extends BaseReferences<_$AppDatabase, $WalletsTable, Wallet> {
  $$WalletsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BarkWalletsTable, List<BarkWallet>>
  _barkWalletsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.barkWallets,
    aliasName: $_aliasNameGenerator(db.wallets.id, db.barkWallets.walletId),
  );

  $$BarkWalletsTableProcessedTableManager get barkWalletsRefs {
    final manager = $$BarkWalletsTableTableManager(
      $_db,
      $_db.barkWallets,
    ).filter((f) => f.walletId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_barkWalletsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WalletsTableFilterComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get network => $composableBuilder(
    column: $table.network,
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> barkWalletsRefs(
    Expression<bool> Function($$BarkWalletsTableFilterComposer f) f,
  ) {
    final $$BarkWalletsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.barkWallets,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BarkWalletsTableFilterComposer(
            $db: $db,
            $table: $db.barkWallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WalletsTableOrderingComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get network => $composableBuilder(
    column: $table.network,
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WalletsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get network =>
      $composableBuilder(column: $table.network, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  Expression<T> barkWalletsRefs<T extends Object>(
    Expression<T> Function($$BarkWalletsTableAnnotationComposer a) f,
  ) {
    final $$BarkWalletsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.barkWallets,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BarkWalletsTableAnnotationComposer(
            $db: $db,
            $table: $db.barkWallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WalletsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WalletsTable,
          Wallet,
          $$WalletsTableFilterComposer,
          $$WalletsTableOrderingComposer,
          $$WalletsTableAnnotationComposer,
          $$WalletsTableCreateCompanionBuilder,
          $$WalletsTableUpdateCompanionBuilder,
          (Wallet, $$WalletsTableReferences),
          Wallet,
          PrefetchHooks Function({bool barkWalletsRefs})
        > {
  $$WalletsTableTableManager(_$AppDatabase db, $WalletsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalletsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalletsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalletsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> network = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> description = const Value.absent(),
              }) => WalletsCompanion(
                id: id,
                name: name,
                type: type,
                network: network,
                createdAt: createdAt,
                updatedAt: updatedAt,
                description: description,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String type,
                required String network,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> description = const Value.absent(),
              }) => WalletsCompanion.insert(
                id: id,
                name: name,
                type: type,
                network: network,
                createdAt: createdAt,
                updatedAt: updatedAt,
                description: description,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WalletsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({barkWalletsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (barkWalletsRefs) db.barkWallets],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (barkWalletsRefs)
                    await $_getPrefetchedData<
                      Wallet,
                      $WalletsTable,
                      BarkWallet
                    >(
                      currentTable: table,
                      referencedTable: $$WalletsTableReferences
                          ._barkWalletsRefsTable(db),
                      managerFromTypedResult: (p0) => $$WalletsTableReferences(
                        db,
                        table,
                        p0,
                      ).barkWalletsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.walletId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WalletsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WalletsTable,
      Wallet,
      $$WalletsTableFilterComposer,
      $$WalletsTableOrderingComposer,
      $$WalletsTableAnnotationComposer,
      $$WalletsTableCreateCompanionBuilder,
      $$WalletsTableUpdateCompanionBuilder,
      (Wallet, $$WalletsTableReferences),
      Wallet,
      PrefetchHooks Function({bool barkWalletsRefs})
    >;
typedef $$BarkWalletsTableCreateCompanionBuilder =
    BarkWalletsCompanion Function({
      Value<int> walletId,
      required String fingerprint,
      required String dbPath,
      required String asp,
      Value<int?> vtxoRefreshExpiryThreshold,
      Value<int?> vtxoExitMargin,
      Value<int?> htlcRecvClaimDelta,
    });
typedef $$BarkWalletsTableUpdateCompanionBuilder =
    BarkWalletsCompanion Function({
      Value<int> walletId,
      Value<String> fingerprint,
      Value<String> dbPath,
      Value<String> asp,
      Value<int?> vtxoRefreshExpiryThreshold,
      Value<int?> vtxoExitMargin,
      Value<int?> htlcRecvClaimDelta,
    });

final class $$BarkWalletsTableReferences
    extends BaseReferences<_$AppDatabase, $BarkWalletsTable, BarkWallet> {
  $$BarkWalletsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WalletsTable _walletIdTable(_$AppDatabase db) =>
      db.wallets.createAlias(
        $_aliasNameGenerator(db.barkWallets.walletId, db.wallets.id),
      );

  $$WalletsTableProcessedTableManager get walletId {
    final $_column = $_itemColumn<int>('wallet_id')!;

    final manager = $$WalletsTableTableManager(
      $_db,
      $_db.wallets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BarkWalletsTableFilterComposer
    extends Composer<_$AppDatabase, $BarkWalletsTable> {
  $$BarkWalletsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dbPath => $composableBuilder(
    column: $table.dbPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get asp => $composableBuilder(
    column: $table.asp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vtxoRefreshExpiryThreshold => $composableBuilder(
    column: $table.vtxoRefreshExpiryThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vtxoExitMargin => $composableBuilder(
    column: $table.vtxoExitMargin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get htlcRecvClaimDelta => $composableBuilder(
    column: $table.htlcRecvClaimDelta,
    builder: (column) => ColumnFilters(column),
  );

  $$WalletsTableFilterComposer get walletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableFilterComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BarkWalletsTableOrderingComposer
    extends Composer<_$AppDatabase, $BarkWalletsTable> {
  $$BarkWalletsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dbPath => $composableBuilder(
    column: $table.dbPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get asp => $composableBuilder(
    column: $table.asp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vtxoRefreshExpiryThreshold => $composableBuilder(
    column: $table.vtxoRefreshExpiryThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vtxoExitMargin => $composableBuilder(
    column: $table.vtxoExitMargin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get htlcRecvClaimDelta => $composableBuilder(
    column: $table.htlcRecvClaimDelta,
    builder: (column) => ColumnOrderings(column),
  );

  $$WalletsTableOrderingComposer get walletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableOrderingComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BarkWalletsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BarkWalletsTable> {
  $$BarkWalletsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dbPath =>
      $composableBuilder(column: $table.dbPath, builder: (column) => column);

  GeneratedColumn<String> get asp =>
      $composableBuilder(column: $table.asp, builder: (column) => column);

  GeneratedColumn<int> get vtxoRefreshExpiryThreshold => $composableBuilder(
    column: $table.vtxoRefreshExpiryThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<int> get vtxoExitMargin => $composableBuilder(
    column: $table.vtxoExitMargin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get htlcRecvClaimDelta => $composableBuilder(
    column: $table.htlcRecvClaimDelta,
    builder: (column) => column,
  );

  $$WalletsTableAnnotationComposer get walletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableAnnotationComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BarkWalletsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BarkWalletsTable,
          BarkWallet,
          $$BarkWalletsTableFilterComposer,
          $$BarkWalletsTableOrderingComposer,
          $$BarkWalletsTableAnnotationComposer,
          $$BarkWalletsTableCreateCompanionBuilder,
          $$BarkWalletsTableUpdateCompanionBuilder,
          (BarkWallet, $$BarkWalletsTableReferences),
          BarkWallet,
          PrefetchHooks Function({bool walletId})
        > {
  $$BarkWalletsTableTableManager(_$AppDatabase db, $BarkWalletsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BarkWalletsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BarkWalletsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BarkWalletsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> walletId = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<String> dbPath = const Value.absent(),
                Value<String> asp = const Value.absent(),
                Value<int?> vtxoRefreshExpiryThreshold = const Value.absent(),
                Value<int?> vtxoExitMargin = const Value.absent(),
                Value<int?> htlcRecvClaimDelta = const Value.absent(),
              }) => BarkWalletsCompanion(
                walletId: walletId,
                fingerprint: fingerprint,
                dbPath: dbPath,
                asp: asp,
                vtxoRefreshExpiryThreshold: vtxoRefreshExpiryThreshold,
                vtxoExitMargin: vtxoExitMargin,
                htlcRecvClaimDelta: htlcRecvClaimDelta,
              ),
          createCompanionCallback:
              ({
                Value<int> walletId = const Value.absent(),
                required String fingerprint,
                required String dbPath,
                required String asp,
                Value<int?> vtxoRefreshExpiryThreshold = const Value.absent(),
                Value<int?> vtxoExitMargin = const Value.absent(),
                Value<int?> htlcRecvClaimDelta = const Value.absent(),
              }) => BarkWalletsCompanion.insert(
                walletId: walletId,
                fingerprint: fingerprint,
                dbPath: dbPath,
                asp: asp,
                vtxoRefreshExpiryThreshold: vtxoRefreshExpiryThreshold,
                vtxoExitMargin: vtxoExitMargin,
                htlcRecvClaimDelta: htlcRecvClaimDelta,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BarkWalletsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({walletId = false}) {
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
                    if (walletId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.walletId,
                                referencedTable: $$BarkWalletsTableReferences
                                    ._walletIdTable(db),
                                referencedColumn: $$BarkWalletsTableReferences
                                    ._walletIdTable(db)
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

typedef $$BarkWalletsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BarkWalletsTable,
      BarkWallet,
      $$BarkWalletsTableFilterComposer,
      $$BarkWalletsTableOrderingComposer,
      $$BarkWalletsTableAnnotationComposer,
      $$BarkWalletsTableCreateCompanionBuilder,
      $$BarkWalletsTableUpdateCompanionBuilder,
      (BarkWallet, $$BarkWalletsTableReferences),
      BarkWallet,
      PrefetchHooks Function({bool walletId})
    >;
typedef $$EsploraEndpointsTableCreateCompanionBuilder =
    EsploraEndpointsCompanion Function({
      Value<int> id,
      required String baseUrl,
      Value<String?> label,
      required String network,
      Value<int> priority,
    });
typedef $$EsploraEndpointsTableUpdateCompanionBuilder =
    EsploraEndpointsCompanion Function({
      Value<int> id,
      Value<String> baseUrl,
      Value<String?> label,
      Value<String> network,
      Value<int> priority,
    });

class $$EsploraEndpointsTableFilterComposer
    extends Composer<_$AppDatabase, $EsploraEndpointsTable> {
  $$EsploraEndpointsTableFilterComposer({
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

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get network => $composableBuilder(
    column: $table.network,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EsploraEndpointsTableOrderingComposer
    extends Composer<_$AppDatabase, $EsploraEndpointsTable> {
  $$EsploraEndpointsTableOrderingComposer({
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

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get network => $composableBuilder(
    column: $table.network,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EsploraEndpointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EsploraEndpointsTable> {
  $$EsploraEndpointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get network =>
      $composableBuilder(column: $table.network, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);
}

class $$EsploraEndpointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EsploraEndpointsTable,
          EsploraEndpoint,
          $$EsploraEndpointsTableFilterComposer,
          $$EsploraEndpointsTableOrderingComposer,
          $$EsploraEndpointsTableAnnotationComposer,
          $$EsploraEndpointsTableCreateCompanionBuilder,
          $$EsploraEndpointsTableUpdateCompanionBuilder,
          (
            EsploraEndpoint,
            BaseReferences<
              _$AppDatabase,
              $EsploraEndpointsTable,
              EsploraEndpoint
            >,
          ),
          EsploraEndpoint,
          PrefetchHooks Function()
        > {
  $$EsploraEndpointsTableTableManager(
    _$AppDatabase db,
    $EsploraEndpointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EsploraEndpointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EsploraEndpointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EsploraEndpointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String> network = const Value.absent(),
                Value<int> priority = const Value.absent(),
              }) => EsploraEndpointsCompanion(
                id: id,
                baseUrl: baseUrl,
                label: label,
                network: network,
                priority: priority,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String baseUrl,
                Value<String?> label = const Value.absent(),
                required String network,
                Value<int> priority = const Value.absent(),
              }) => EsploraEndpointsCompanion.insert(
                id: id,
                baseUrl: baseUrl,
                label: label,
                network: network,
                priority: priority,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EsploraEndpointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EsploraEndpointsTable,
      EsploraEndpoint,
      $$EsploraEndpointsTableFilterComposer,
      $$EsploraEndpointsTableOrderingComposer,
      $$EsploraEndpointsTableAnnotationComposer,
      $$EsploraEndpointsTableCreateCompanionBuilder,
      $$EsploraEndpointsTableUpdateCompanionBuilder,
      (
        EsploraEndpoint,
        BaseReferences<_$AppDatabase, $EsploraEndpointsTable, EsploraEndpoint>,
      ),
      EsploraEndpoint,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WalletsTableTableManager get wallets =>
      $$WalletsTableTableManager(_db, _db.wallets);
  $$BarkWalletsTableTableManager get barkWallets =>
      $$BarkWalletsTableTableManager(_db, _db.barkWallets);
  $$EsploraEndpointsTableTableManager get esploraEndpoints =>
      $$EsploraEndpointsTableTableManager(_db, _db.esploraEndpoints);
}
