import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/frameworks/drift/app_database.dart';
import 'package:flutter_app/features/wallet/application/ports/wallets_repository_port.dart';
import 'package:flutter_app/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/wallet_type_vo.dart';

/// Drift adapter implementing WalletsRepositoryPort
class DriftWalletsRepository implements WalletsRepositoryPort {
  final AppDatabase _database;

  DriftWalletsRepository(this._database);

  @override
  Future<Either<Failure, WalletEntity>> createWallet({
    required String name,
    required String network,
    required WalletTypeVO type,
    String? description,
  }) async {
    try {
      // Insert into Wallets table
      final walletId = await _database
          .into(_database.wallets)
          .insert(
            WalletsCompanion.insert(
              name: name,
              type: type.value,
              network: network,
              description: Value(description),
            ),
          );

      // Fetch and return the created wallet entity
      return await _getWalletEntityById(walletId);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to create bark wallet: $e'));
    }
  }

  @override
  Future<Either<Failure, WalletEntity>> getWalletById(int walletId) async {
    return await _getWalletEntityById(walletId);
  }

  @override
  Future<Either<Failure, List<WalletEntity>>> getAllWallets() async {
    try {
      final wallets = await _database.select(_database.wallets).get();

      return Right(wallets.map((w) => w.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get wallets: $e'));
    }
  }

  /// Helper function to get a wallet entity by ID with its config
  Future<Either<Failure, WalletEntity>> _getWalletEntityById(
    int walletId,
  ) async {
    try {
      final wallet = await (_database.select(
        _database.wallets,
      )..where((tbl) => tbl.id.equals(walletId))).getSingleOrNull();

      if (wallet == null) {
        return Left(NotFoundFailure(message: 'Wallet not found'));
      }

      return Right(wallet.toEntity());
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get wallet: $e'));
    }
  }
}

extension on Wallet {
  WalletEntity toEntity() {
    return WalletEntity(
      id: this.id,
      name: name,
      type: WalletTypeVO.fromString(type),
      network: network,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
