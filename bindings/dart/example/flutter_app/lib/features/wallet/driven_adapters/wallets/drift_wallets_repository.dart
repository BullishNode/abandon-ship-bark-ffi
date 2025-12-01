import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/frameworks/drift/app_database.dart';
import 'package:flutter_app/features/wallet/application/ports/wallets_repository_port.dart';
import 'package:flutter_app/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter_app/features/wallet/domain/entities/wallet_config.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/wallet_type_vo.dart';

/// Drift adapter implementing WalletsRepositoryPort
class DriftWalletsRepository implements WalletsRepositoryPort {
  final AppDatabase _database;

  DriftWalletsRepository(this._database);

  @override
  Future<Either<Failure, WalletEntity>> createBarkWallet({
    required String name,
    required String network,
    String? description,
    required BarkWalletConfig config,
  }) async {
    try {
      // Insert into Wallets table
      final walletId = await _database
          .into(_database.wallets)
          .insert(
            WalletsCompanion.insert(
              name: name,
              type: WalletTypeVO.bark.value,
              network: network,
              description: Value(description),
            ),
          );

      // Insert into BarkWallets table
      await _database
          .into(_database.barkWallets)
          .insert(
            BarkWalletsCompanion.insert(
              walletId: Value(walletId),
              fingerprint: config.fingerprint,
              dbPath: config.dbPath,
              asp: config.asp,
              vtxoRefreshExpiryThreshold: Value(
                config.vtxoRefreshExpiryThreshold,
              ),
              vtxoExitMargin: Value(config.vtxoExitMargin),
              htlcRecvClaimDelta: Value(config.htlcRecvClaimDelta),
            ),
          );

      // Fetch and return the created Bark wallet entity
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
      final entities = <WalletEntity>[];

      for (final wallet in wallets) {
        final walletType = WalletTypeVO.fromString(wallet.type);
        final config = await _getWalletConfig(wallet.id, walletType);

        if (config == null) {
          return Left(
            NotFoundFailure(
              message: 'Config not found for wallet ${wallet.id}',
            ),
          );
        }

        entities.add(wallet.toEntity(config));
      }

      return Right(entities);
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

      final walletType = WalletTypeVO.fromString(wallet.type);
      final config = await _getWalletConfig(walletId, walletType);

      if (config == null) {
        return Left(
          NotFoundFailure(
            message: 'Wallet config not found for wallet $walletId',
          ),
        );
      }

      return Right(wallet.toEntity(config));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get wallet: $e'));
    }
  }

  /// Get wallet config for a specific wallet ID
  Future<WalletConfig?> _getWalletConfig(
    int walletId,
    WalletTypeVO type,
  ) async {
    switch (type) {
      case WalletTypeVO.bark:
        final barkConfig = await (_database.select(
          _database.barkWallets,
        )..where((tbl) => tbl.walletId.equals(walletId))).getSingleOrNull();
        return barkConfig?.toConfig();
    }
    return null;
  }
}

extension on Wallet {
  WalletEntity toEntity(WalletConfig config) {
    return WalletEntity(
      id: this.id,
      name: name,
      type: WalletTypeVO.fromString(type),
      network: network,
      createdAt: createdAt,
      updatedAt: updatedAt,
      description: description,
      config: config,
    );
  }
}

extension on BarkWallet {
  WalletConfig toConfig() {
    return BarkWalletConfig(
      fingerprint: fingerprint,
      dbPath: dbPath,
      asp: asp,
      vtxoRefreshExpiryThreshold: vtxoRefreshExpiryThreshold,
      vtxoExitMargin: vtxoExitMargin,
      htlcRecvClaimDelta: htlcRecvClaimDelta,
    );
  }
}
