import 'dart:io';

import 'package:bark/bark.dart' as bark;
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/constants/storage_keys.dart';
import 'package:flutter_app/core/frameworks/drift/app_database.dart';
import 'package:flutter_app/features/wallet/application/ports/wallet_port.dart';
import 'package:flutter_app/features/wallet/domain/entities/wallet_config_entity.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/bark_balance_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/new_wallet_config_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/send_payment_request_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/transaction_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/vtxo_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/wallet_backup_vo.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Adapter implementing WalletPort using Bark
/// TODO: Split in a local and remote adapter and the service will orchestrate between them
class BarkWallet implements WalletPort {
  final AppDatabase _database;
  final FlutterSecureStorage _secureStorage;

  const BarkWallet({
    required AppDatabase database,
    required FlutterSecureStorage secureStorage,
  }) : _database = database,
       _secureStorage = secureStorage;

  @override
  Future<Either<Failure, WalletConfigEntity>> createWallet(
    NewWalletConfigVO config,
  ) async {
    try {
      if (config is! NewBarkWalletConfigVO) {
        return Left(
          ServiceFailure(
            message:
                'Invalid wallet config type for BarkWallet creation: ${config.runtimeType}',
          ),
        );
      }

      final mnemonic = bark.BarkUtils.generateMnemonic();

      return await _configureWallet(
        walletId: config.walletId,
        mnemonic: mnemonic,
        network: config.network,
        asp: config.asp,
        esploraAddresses: config.esploraAddresses,
        vtxoRefreshExpiryThreshold: config.vtxoRefreshExpiryThreshold,
        vtxoExitMargin: config.vtxoExitMargin,
        htlcRecvClaimDelta: config.htlcRecvClaimDelta,
      );
    } catch (e) {
      return Left(ServiceFailure(message: 'Failed to create wallet: $e'));
    }
  }

  @override
  Future<Either<Failure, WalletConfigEntity>> recoverWallet({
    required WalletBackupVO backup,
    required NewWalletConfigVO config,
  }) async {
    try {
      if (backup is! BarkWalletBackupVO) {
        return Left(
          ServiceFailure(
            message:
                'Invalid wallet backup type for BarkWallet recovery: ${backup.runtimeType}',
          ),
        );
      }

      if (config is! NewBarkWalletConfigVO) {
        return Left(
          ServiceFailure(
            message:
                'Invalid wallet config type for BarkWallet recovery: ${config.runtimeType}',
          ),
        );
      }

      return await _configureWallet(
        walletId: config.walletId,
        mnemonic: backup.mnemonic,
        network: config.network,
        asp: config.asp,
        esploraAddresses: config.esploraAddresses,
        vtxoRefreshExpiryThreshold: config.vtxoRefreshExpiryThreshold,
        vtxoExitMargin: config.vtxoExitMargin,
        htlcRecvClaimDelta: config.htlcRecvClaimDelta,
      );
    } catch (e) {
      return Left(ServiceFailure(message: 'Failed to recover wallet: $e'));
    }
  }

  @override
  Future<Either<Failure, WalletConfigEntity>> loadWalletConfig({
    required int walletId,
  }) async {
    try {
      final query = _database.select(_database.barkWallets)
        ..where((tbl) => tbl.walletId.equals(walletId));
      final barkWalletRow = await query.getSingleOrNull();
      if (barkWalletRow == null) {
        return Left(
          NotFoundFailure(message: 'Bark wallet not found for id: $walletId'),
        );
      }

      return Right(
        BarkWalletConfigEntity(
          walletId: barkWalletRow.walletId,
          network: barkWalletRow.network,
          fingerprint: barkWalletRow.fingerprint,
          dbPath: barkWalletRow.dbPath,
          asp: barkWalletRow.asp,
          vtxoRefreshExpiryThreshold: barkWalletRow.vtxoRefreshExpiryThreshold,
          vtxoExitMargin: barkWalletRow.vtxoExitMargin,
          htlcRecvClaimDelta: barkWalletRow.htlcRecvClaimDelta,
        ),
      );
    } catch (e) {
      return Left(ServiceFailure(message: 'Failed to load wallet config: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> generatePaymentRequest({
    required WalletConfigEntity config,
  }) async {
    return _executeWithEsploraRetry<String>(
      config: config,
      operation: (barkWallet) async {
        return barkWallet.newAddress();
      },
    );
  }

  @override
  Future<Either<Failure, BarkBalanceVO>> getBalance({
    required WalletConfigEntity config,
  }) async {
    return _executeWithEsploraRetry<BarkBalanceVO>(
      config: config,
      operation: (barkWallet) async {
        final balance = barkWallet.balance();
        return BarkBalanceVO(
          spendableSats: balance.spendableSats,
          pendingInRoundSats: balance.pendingInRoundSats,
          pendingExitSats: balance.pendingExitSats,
          pendingLightningSendSats: balance.pendingLightningSendSats,
          claimableLightningReceiveSats: balance.claimableLightningReceiveSats,
          pendingBoardSats: balance.pendingBoardSats,
        );
      },
    );
  }

  @override
  Future<Either<Failure, List<VtxoVO>>> getVtxos({
    required WalletConfigEntity config,
  }) async {
    return _executeWithEsploraRetry<List<VtxoVO>>(
      config: config,
      operation: (barkWallet) async {
        final vtxos = barkWallet.vtxos();
        return vtxos
            .map(
              (vtxo) => VtxoVO(
                id: vtxo.id,
                amountSats: vtxo.amountSats,
                expiryHeight: vtxo.expiryHeight,
                kind: vtxo.kind,
                state: vtxo.state,
              ),
            )
            .toList();
      },
    );
  }

  @override
  Future<Either<Failure, List<TransactionVO>>> getTransactions({
    required WalletConfigEntity config,
  }) async {
    return _executeWithEsploraRetry<List<TransactionVO>>(
      config: config,
      operation: (barkWallet) async {
        final movements = barkWallet.history();
        return movements
            .map(
              (movement) => TransactionVO(
                id: movement.id,
                status: movement.status,
                subsystemName: movement.subsystemName,
                subsystemKind: movement.subsystemKind,
                intendedBalanceSats: movement.intendedBalanceSats,
                effectiveBalanceSats: movement.effectiveBalanceSats,
                offchainFeeSats: movement.offchainFeeSats,
                createdAt: movement.createdAt,
                completedAt: movement.completedAt,
              ),
            )
            .toList();
      },
    );
  }

  @override
  Future<Either<Failure, void>> sync({
    required WalletConfigEntity config,
  }) async {
    return _executeWithEsploraRetry<void>(
      config: config,
      operation: (barkWallet) async {
        // Sync with server to fetch latest transactions
        await barkWallet.sync();

        // Run maintenance (includes VTXO refresh)
        await barkWallet.maintenance();
      },
    );
  }

  @override
  Future<Either<Failure, WalletBackupVO>> getBackup({
    required WalletConfigEntity config,
  }) async {
    try {
      if (config is! BarkWalletConfigEntity) {
        return Left(
          ServiceFailure(
            message: 'Invalid wallet config type for BarkWallet backup',
          ),
        );
      }

      final mnemonic = await _getMnemonic(config);

      if (mnemonic == null) {
        return Left(NotFoundFailure(message: 'Mnemonic not found for wallet'));
      }

      return Right(
        BarkWalletBackupVO(mnemonic: mnemonic, fingerprint: config.fingerprint),
      );
    } catch (e) {
      return Left(
        ServiceFailure(message: 'Failed to retrieve wallet backup: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> confirmPayment({
    required WalletConfigEntity config,
    required SendPaymentRequestVO request,
  }) async {
    return _executeWithEsploraRetry<String>(
      config: config,
      operation: (barkWallet) async {
        switch (request) {
          case ArkoorSendPaymentRequestVO():
            final txid = await barkWallet.sendArkoorPayment(
              request.arkAddress,
              request.amountSats,
            );
            return txid;
        }
      },
    );
  }

  Future<Either<Failure, BarkWalletConfigEntity>> _configureWallet({
    required int walletId,
    required String mnemonic,
    required String network,
    required String asp,
    required List<String> esploraAddresses,
    int? vtxoRefreshExpiryThreshold,
    int? vtxoExitMargin,
    int? htlcRecvClaimDelta,
  }) async {
    try {
      // Create unique db directory path based if you want to maintain multiple wallets
      // Store only the relative path to avoid iOS container ID changes
      final relativeDbPath = 'wallets/$walletId';
      // But use the full path for bark wallet creation
      final fullDbPath = await _getWalletDataDir(relativeDbPath);

      bark.Wallet? wallet;
      for (final esploraAddress in esploraAddresses) {
        final barkConfig = bark.Config(
          asp,
          esploraAddress,
          null,
          null,
          null,
          null,
          _mapNetwork(network),
          vtxoRefreshExpiryThreshold,
          vtxoExitMargin,
          htlcRecvClaimDelta,
          null,
          null,
        );

        try {
          // Try to open the wallet to validate the esplora address
          wallet = await bark.Wallet.create(
            mnemonic,
            barkConfig,
            fullDbPath,
            true,
          );
          // If successful, break the loop and use this config
          break;
        } catch (e) {
          // If it fails, continue to the next esplora address
          continue;
        }
      }

      if (wallet == null) {
        return const Left(
          ServiceFailure(message: 'Failed to connect to any Esplora endpoint'),
        );
      }

      // Store mnemonic securely
      final properties = wallet.properties();
      final fingerprint = properties.fingerprint;
      final mnemonicKey = '${StorageKeys.mnemonicPrefix}$fingerprint';
      await _secureStorage.write(key: mnemonicKey, value: mnemonic);

      // Insert into BarkWallets table
      await _database
          .into(_database.barkWallets)
          .insert(
            BarkWalletsCompanion.insert(
              walletId: Value(walletId),
              network: network,
              fingerprint: fingerprint,
              dbPath: relativeDbPath,
              asp: asp,
              vtxoRefreshExpiryThreshold: Value(vtxoRefreshExpiryThreshold),
              vtxoExitMargin: Value(vtxoExitMargin),
              htlcRecvClaimDelta: Value(htlcRecvClaimDelta),
            ),
          );

      // Return wallet config
      return Right(
        BarkWalletConfigEntity(
          walletId: walletId,
          network: network,
          fingerprint: properties.fingerprint,
          dbPath: relativeDbPath,
          asp: asp,
          vtxoRefreshExpiryThreshold: vtxoRefreshExpiryThreshold,
          vtxoExitMargin: vtxoExitMargin,
          htlcRecvClaimDelta: htlcRecvClaimDelta,
        ),
      );
    } catch (e) {
      return Left(ServiceFailure(message: 'Failed to configure wallet: $e'));
    }
  }

  Future<String?> _getMnemonic(WalletConfigEntity config) async {
    if (config is! BarkWalletConfigEntity) {
      throw ServiceFailure(
        message:
            'Invalid wallet config type for BarkWallet: ${config.runtimeType}',
      );
    }

    final mnemonicKey = '${StorageKeys.mnemonicPrefix}${config.fingerprint}';
    return await _secureStorage.read(key: mnemonicKey);
  }

  /// Ensure the wallet data directory exists before creating a wallet
  /// dbPath should be a directory path, not a file path (matching pure dart example)
  Future<String> _getWalletDataDir(String relativeDbPath) async {
    // Get app directory and construct full path for wallet creation
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDir.path}/$relativeDbPath';
    final directory = Directory(dbPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return dbPath;
  }

  /// Map domain BitcoinNetwork to bark.Network
  bark.Network _mapNetwork(String network) {
    switch (network) {
      case 'mainnet':
        return bark.Network.bitcoin;
      case 'testnet3':
        return bark.Network.testnet;
      case 'signet':
        return bark.Network.signet;
      default:
        throw ArgumentError('Unsupported network: $network');
    }
  }

  /// Execute a wallet operation with retry logic across multiple esplora endpoints
  Future<Either<Failure, T>> _executeWithEsploraRetry<T>({
    required WalletConfigEntity config,
    required Future<T> Function(bark.Wallet) operation,
  }) async {
    if (config is! BarkWalletConfigEntity) {
      return Left(
        ServiceFailure(
          message:
              'Invalid wallet config type for BarkWallet: ${config.runtimeType}',
        ),
      );
    }

    final mnemonic = await _getMnemonic(config);
    if (mnemonic == null) {
      return Left(
        NotFoundFailure(
          message: 'Mnemonic not found for wallet ${config.walletId}',
        ),
      );
    }

    final esploraAddresses = config.esploraAddresses;
    if ((esploraAddresses == null || esploraAddresses.isEmpty)) {
      return Left(
        NotFoundFailure(
          message: 'Esplora addresses not found for wallet ${config.walletId}',
        ),
      );
    }

    final fullDbPath = await _getWalletDataDir(config.dbPath);

    // Try each esplora endpoint until one succeeds
    Exception? lastException;
    for (final esploraAddress in esploraAddresses) {
      try {
        final barkConfig = bark.Config(
          config.asp,
          esploraAddress,
          null,
          null,
          null,
          null,
          _mapNetwork(config.network),
          config.vtxoRefreshExpiryThreshold,
          config.vtxoExitMargin,
          config.htlcRecvClaimDelta,
          null,
          null,
        );

        final barkWallet = await bark.Wallet.open(
          mnemonic,
          barkConfig,
          fullDbPath,
        );

        final result = await operation(barkWallet);
        return Right(result);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        // Continue to next endpoint if available
        continue;
      }
    }

    // All endpoints failed
    return Left(
      ServiceFailure(
        message:
            'Failed to execute wallet operation with all esplora endpoints: $lastException',
      ),
    );
  }
}
