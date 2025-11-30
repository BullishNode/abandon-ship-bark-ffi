import 'package:drift/drift.dart';
import 'package:flutter_app/core/frameworks/drift/tables/wallets.dart';

/// Bark-specific wallet data
class BarkWallets extends Table {
  /// Foreign key to Wallets table
  IntColumn get walletId =>
      integer().references(Wallets, #id, onDelete: KeyAction.cascade)();

  /// Master key fingerprint (hex string)
  TextColumn get fingerprint => text().withLength(min: 8, max: 8)();

  /// Path to the wallet's local database
  TextColumn get dbPath => text()();

  /// Ark Service Provider URL
  TextColumn get asp => text()();

  /// VTXO refresh expiry threshold in seconds (optional, can be null for server default)
  IntColumn get vtxoRefreshExpiryThreshold => integer().nullable()();

  /// VTXO exit margin in seconds (optional, can be null for server default)
  IntColumn get vtxoExitMargin => integer().nullable()();

  /// HTLC receive claim delta in blocks (optional, can be null for server default)
  IntColumn get htlcRecvClaimDelta => integer().nullable()();

  @override
  Set<Column> get primaryKey => {walletId};
}
