import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/features/wallet/application/ports/esplora_endpoint_port.dart';
import 'package:flutter_app/features/wallet/application/ports/wallets_repository_port.dart';
import 'package:flutter_app/features/wallet/application/ports/mnemonic_repository_port.dart';
import 'package:flutter_app/features/wallet/domain/entities/wallet_config.dart';
import 'package:flutter_app/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/bark_balance_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/vtxo_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/wallet_type_vo.dart';
import 'package:flutter_app/features/wallet/driven_adapters/wallets/bark_wallet.dart';
import 'package:flutter_app/features/wallet/driven_adapters/wallets/wallet_port_registry.dart';

class WalletService {
  final WalletPortRegistry _walletPortRegistry;
  final WalletsRepositoryPort _walletsRepository;
  final MnemonicRepositoryPort _mnemonicRepository;
  final EsploraEndpointPort _esploraEndpointPort;

  WalletService({
    required WalletPortRegistry walletPortRegistry,
    required WalletsRepositoryPort walletsRepository,
    required MnemonicRepositoryPort mnemonicRepository,
    required EsploraEndpointPort esploraEndpointPort,
  }) : _walletPortRegistry = walletPortRegistry,
       _walletsRepository = walletsRepository,
       _mnemonicRepository = mnemonicRepository,
       _esploraEndpointPort = esploraEndpointPort;

  /// Create a new bark wallet from mnemonic
  Future<Either<Failure, WalletEntity>> createBarkWallet({
    required String name,
    String? description,
    required String network,
    required String asp,
    int? vtxoRefreshExpiryThreshold,
    int? vtxoExitMargin,
    int? htlcRecvClaimDelta,
  }) async {
    try {
      final mnemonic = await _mnemonicRepository.generateMnemonic();

      // Get Esplora endpoint for the network
      final esploraResult = await _esploraEndpointPort.getEndpointUrlForNetwork(
        network,
      );

      return await esploraResult.fold((failure) => Left(failure), (
        esploraAddress,
      ) async {
        final walletPort =
            _walletPortRegistry.getPort(WalletTypeVO.bark) as BarkWallet;

        // Configure the wallet using the provided mnemonic
        final configResult = await walletPort.configureWallet(
          mnemonic: mnemonic,
          network: network,
          asp: asp,
          esploraAddress: esploraAddress,
          vtxoRefreshExpiryThreshold: vtxoRefreshExpiryThreshold,
          vtxoExitMargin: vtxoExitMargin,
          htlcRecvClaimDelta: htlcRecvClaimDelta,
        );

        return await configResult.fold((failure) => Left(failure), (
          config,
        ) async {
          // Store the mnemonic securely
          await _mnemonicRepository.storeMnemonic(
            fingerprint: config.fingerprint,
            mnemonic: mnemonic,
          );

          // Create the bark wallet in the repository
          return await _walletsRepository.createBarkWallet(
            name: name,
            network: network,
            description: description,
            config: config,
          );
        });
      });
    } catch (e) {
      return Left(ServiceFailure(message: 'Failed to create bark wallet: $e'));
    }
  }

  Future<Either<Failure, String>> generatePaymentRequest({
    required int walletId,
  }) async {
    try {
      final walletResult = await _walletsRepository.getWalletById(walletId);

      return await walletResult.fold((failure) => Left(failure), (
        wallet,
      ) async {
        await _prepareWalletConfig(wallet);
        final walletPort = _walletPortRegistry.getPort(wallet.type);
        return await walletPort.generatePaymentRequest(wallet: wallet);
      });
    } catch (e) {
      return Left(
        ServiceFailure(message: 'Failed to generate payment request: $e'),
      );
    }
  }

  Future<Either<Failure, BarkBalanceVO>> getBalance({
    required int walletId,
  }) async {
    try {
      final walletResult = await _walletsRepository.getWalletById(walletId);

      return await walletResult.fold((failure) => Left(failure), (
        wallet,
      ) async {
        await _prepareWalletConfig(wallet);
        final walletPort = _walletPortRegistry.getPort(wallet.type);
        return await walletPort.getBalance(wallet: wallet);
      });
    } catch (e) {
      return Left(ServiceFailure(message: 'Failed to get balance: $e'));
    }
  }

  Future<Either<Failure, List<VtxoVO>>> getVtxos({
    required int walletId,
  }) async {
    try {
      final walletResult = await _walletsRepository.getWalletById(walletId);

      return await walletResult.fold((failure) => Left(failure), (
        wallet,
      ) async {
        await _prepareWalletConfig(wallet);
        final walletPort = _walletPortRegistry.getPort(wallet.type);
        return await walletPort.getVtxos(wallet: wallet);
      });
    } catch (e) {
      return Left(ServiceFailure(message: 'Failed to get vtxos: $e'));
    }
  }

  Future<Either<Failure, void>> sync({required int walletId}) async {
    try {
      final walletResult = await _walletsRepository.getWalletById(walletId);

      return await walletResult.fold((failure) => Left(failure), (
        wallet,
      ) async {
        await _prepareWalletConfig(wallet);
        final walletPort = _walletPortRegistry.getPort(wallet.type);
        return await walletPort.sync(wallet: wallet);
      });
    } catch (e) {
      return Left(ServiceFailure(message: 'Failed to sync wallet: $e'));
    }
  }

  /// Prepare wallet config with mnemonic and esplora addresses
  Future<void> _prepareWalletConfig(WalletEntity wallet) async {
    final config = wallet.config;
    if (wallet.type == WalletTypeVO.bark) {
      if (config is! BarkWalletConfig) {
        throw ServiceFailure(
          message:
              'Invalid wallet config type for BarkWallet: ${wallet.runtimeType}',
        );
      }

      // Set mnemonic
      final mnemonic = await _mnemonicRepository.getMnemonic(
        config.fingerprint,
      );
      if (mnemonic == null) {
        throw NotFoundFailure(
          message: 'Mnemonic not found for wallet ${wallet.id}',
        );
      }
      config.setMnemonic(mnemonic);

      // Set esplora addresses
      final esploraResult = await _esploraEndpointPort.getEndpointUrlForNetwork(
        wallet.network,
      );
      esploraResult.fold(
        (failure) => throw failure,
        (esploraAddress) => config.setEsploraAddresses([esploraAddress]),
      );
    }
  }
}
