import 'dart:io';

import 'package:bark/bark.dart' as bark;
import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/features/wallet/application/ports/wallet_port.dart';
import 'package:flutter_app/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter_app/features/wallet/domain/entities/wallet_config.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/bark_balance_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/vtxo_vo.dart';
import 'package:path_provider/path_provider.dart';

/// Adapter implementing WalletPort using Bark
class BarkWallet implements WalletPort {
  const BarkWallet();

  Future<Either<Failure, BarkWalletConfig>> configureWallet({
    required String mnemonic,
    required String network,
    required String asp,
    required String esploraAddress,
    int? vtxoRefreshExpiryThreshold,
    int? vtxoExitMargin,
    int? htlcRecvClaimDelta,
  }) async {
    try {
      // Create unique db directory path based on timestamp.
      // Store only the relative path to avoid iOS container ID changes
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final relativeDbPath = 'wallets/bark_$timestamp';

      final fullDbPath = await _getWalletDataDir(relativeDbPath);

      final config = bark.Config(
        asp,
        esploraAddress,
        _mapNetwork(network),
        vtxoRefreshExpiryThreshold,
        vtxoExitMargin,
        htlcRecvClaimDelta,
      );

      final wallet = await bark.Wallet.create(
        mnemonic,
        config,
        fullDbPath,
        false, // forceRescan
      );

      // Get fingerprint from wallet properties
      final properties = wallet.properties();

      // Fetch the created wallet
      return Right(
        BarkWalletConfig(
          fingerprint: properties.fingerprint,
          dbPath: relativeDbPath,
          asp: asp,
          vtxoRefreshExpiryThreshold: vtxoRefreshExpiryThreshold,
          vtxoExitMargin: vtxoExitMargin,
          htlcRecvClaimDelta: htlcRecvClaimDelta,
        ),
      );
    } catch (e) {
      return Left(ServiceFailure(message: 'Failed to create wallet: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> generatePaymentRequest({
    required WalletEntity wallet,
  }) async {
    return _executeWithEsploraRetry<String>(
      wallet: wallet,
      operation: (barkWallet) async {
        return barkWallet.newAddress();
      },
    );
  }

  @override
  Future<Either<Failure, BarkBalanceVO>> getBalance({
    required WalletEntity wallet,
  }) async {
    return _executeWithEsploraRetry<BarkBalanceVO>(
      wallet: wallet,
      operation: (barkWallet) async {
        final balance = barkWallet.balance();
        return BarkBalanceVO(
          spendableSats: balance.spendableSats,
          pendingInRoundSats: balance.pendingInRoundSats,
          pendingExitSats: balance.pendingExitSats,
          pendingLightningSendSats: balance.pendingLightningSendSats,
          pendingLightningReceiveTotalSats:
              balance.pendingLightningReceiveTotalSats,
          pendingLightningReceiveClaimableSats:
              balance.pendingLightningReceiveClaimableSats,
          pendingBoardSats: balance.pendingBoardSats,
        );
      },
    );
  }

  @override
  Future<Either<Failure, List<VtxoVO>>> getVtxos({
    required WalletEntity wallet,
  }) async {
    return _executeWithEsploraRetry<List<VtxoVO>>(
      wallet: wallet,
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
  Future<Either<Failure, void>> sync({required WalletEntity wallet}) async {
    return _executeWithEsploraRetry<void>(
      wallet: wallet,
      operation: (barkWallet) async {
        // Sync with server to fetch latest transactions
        await barkWallet.sync();

        // Run maintenance (includes VTXO refresh)
        await barkWallet.maintenance();
      },
    );
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
    required WalletEntity wallet,
    required Future<T> Function(bark.Wallet) operation,
  }) async {
    final walletConfig = wallet.config;
    if (walletConfig is! BarkWalletConfig) {
      return Left(
        ServiceFailure(
          message:
              'Invalid wallet config type for BarkWallet: ${wallet.runtimeType}',
        ),
      );
    }

    final mnemonic = walletConfig.mnemonic;
    if (mnemonic == null) {
      return Left(
        NotFoundFailure(message: 'Mnemonic not found for wallet ${wallet.id}'),
      );
    }

    final esploraAddresses = walletConfig.esploraAddresses;
    if ((esploraAddresses == null || esploraAddresses.isEmpty)) {
      return Left(
        NotFoundFailure(
          message: 'Esplora addresses not found for wallet ${wallet.id}',
        ),
      );
    }

    final fullDbPath = await _getWalletDataDir(walletConfig.dbPath);

    // Try each esplora endpoint until one succeeds

    Exception? lastException;
    for (final esploraAddress in esploraAddresses) {
      try {
        final config = bark.Config(
          walletConfig.asp,
          esploraAddress,
          _mapNetwork(wallet.network),
          walletConfig.vtxoRefreshExpiryThreshold,
          walletConfig.vtxoExitMargin,
          walletConfig.htlcRecvClaimDelta,
        );

        final barkWallet = await bark.Wallet.open(mnemonic, config, fullDbPath);

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
