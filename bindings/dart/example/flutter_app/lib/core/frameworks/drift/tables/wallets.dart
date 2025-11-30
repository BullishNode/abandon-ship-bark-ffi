import 'package:drift/drift.dart';

/// General wallet information table
class Wallets extends Table {
  /// Unique identifier
  IntColumn get id => integer().autoIncrement()();

  /// User-facing name/label for the wallet
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Wallet type (bark, etc.) - stored as string
  TextColumn get type => text()();

  /// Bitcoin network (mainnet, testnet3, testnet4, signet) - stored as string
  TextColumn get network => text()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last updated timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Optional description
  TextColumn get description => text().nullable()();
}
