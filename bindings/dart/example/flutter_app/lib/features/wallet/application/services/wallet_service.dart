import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/features/wallet/application/ports/esplora_endpoint_port.dart';
import 'package:flutter_app/features/wallet/application/ports/wallets_repository_port.dart';
import 'package:flutter_app/features/wallet/application/ports/mnemonic_repository_port.dart';
import 'package:flutter_app/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/bark_balance_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/new_wallet_config_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/send_payment_request_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/transaction_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/vtxo_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/wallet_backup_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/wallet_type_vo.dart';
import 'package:flutter_app/features/wallet/driven_adapters/wallets/wallet_port_registry.dart';

class WalletService {
  final WalletPortRegistry _walletPortRegistry;
  final WalletsRepositoryPort _walletsRepository;
  final EsploraEndpointPort _esploraEndpointPort;

  WalletService({
    required WalletPortRegistry walletPortRegistry,
    required WalletsRepositoryPort walletsRepository,
    required MnemonicRepositoryPort mnemonicRepository,
    required EsploraEndpointPort esploraEndpointPort,
  }) : _walletPortRegistry = walletPortRegistry,
       _walletsRepository = walletsRepository,
       _esploraEndpointPort = esploraEndpointPort;

  /// Create a bark wallet
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
      // Get Esplora endpoint for the network
      final esploraResult = await _esploraEndpointPort.getEndpointUrlForNetwork(
        network,
      );

      return await esploraResult.fold((failure) => Left(failure), (
        esploraAddress,
      ) async {
        // Create the bark wallet in the repository
        final walletResult = await _walletsRepository.createWallet(
          name: name,
          network: network,
          type: WalletTypeVO.bark,
          description: description,
        );

        return await walletResult.fold((failure) => Left(failure), (
          wallet,
        ) async {
          final walletPort = _walletPortRegistry.getPort(WalletTypeVO.bark);

          // Configure the wallet using the correct port
          final walletConfig = await walletPort.createWallet(
            NewBarkWalletConfigVO(
              walletId: wallet.id,
              network: network,
              asp: asp,
              esploraAddresses: [esploraAddress],
              vtxoRefreshExpiryThreshold: vtxoRefreshExpiryThreshold,
              vtxoExitMargin: vtxoExitMargin,
              htlcRecvClaimDelta: htlcRecvClaimDelta,
            ),
          );
          return await walletConfig.fold((failure) => Left(failure), (
            walletConfig,
          ) async {
            return Right(wallet);
          });
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
        final walletPort = _walletPortRegistry.getPort(wallet.type);
        final configResult = await walletPort.loadWalletConfig(
          walletId: walletId,
        );
        return await configResult.fold((failure) => Left(failure), (
          config,
        ) async {
          // Get Esplora endpoint for the network
          final esploraResult = await _esploraEndpointPort
              .getEndpointUrlForNetwork(config.network);

          return await esploraResult.fold((failure) => Left(failure), (
            esploraAddress,
          ) async {
            config.setEsploraAddresses([esploraAddress]);
            return await walletPort.generatePaymentRequest(config: config);
          });
        });
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
        final walletPort = _walletPortRegistry.getPort(wallet.type);
        final configResult = await walletPort.loadWalletConfig(
          walletId: walletId,
        );
        return await configResult.fold((failure) => Left(failure), (
          config,
        ) async {
          // Get Esplora endpoint for the network
          final esploraResult = await _esploraEndpointPort
              .getEndpointUrlForNetwork(config.network);

          return await esploraResult.fold((failure) => Left(failure), (
            esploraAddress,
          ) async {
            config.setEsploraAddresses([esploraAddress]);
            return await walletPort.getBalance(config: config);
          });
        });
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
        final walletPort = _walletPortRegistry.getPort(wallet.type);
        final configResult = await walletPort.loadWalletConfig(
          walletId: walletId,
        );
        return await configResult.fold((failure) => Left(failure), (
          config,
        ) async {
          // Get Esplora endpoint for the network
          final esploraResult = await _esploraEndpointPort
              .getEndpointUrlForNetwork(config.network);

          return await esploraResult.fold((failure) => Left(failure), (
            esploraAddress,
          ) async {
            config.setEsploraAddresses([esploraAddress]);
            return await walletPort.getVtxos(config: config);
          });
        });
      });
    } catch (e) {
      return Left(ServiceFailure(message: 'Failed to get vtxos: $e'));
    }
  }

  Future<Either<Failure, List<TransactionVO>>> getTransactions({
    required int walletId,
  }) async {
    try {
      final walletResult = await _walletsRepository.getWalletById(walletId);

      return await walletResult.fold((failure) => Left(failure), (
        wallet,
      ) async {
        final walletPort = _walletPortRegistry.getPort(wallet.type);
        final configResult = await walletPort.loadWalletConfig(
          walletId: walletId,
        );
        return await configResult.fold((failure) => Left(failure), (
          config,
        ) async {
          // Get Esplora endpoint for the network
          final esploraResult = await _esploraEndpointPort
              .getEndpointUrlForNetwork(config.network);

          return await esploraResult.fold((failure) => Left(failure), (
            esploraAddress,
          ) async {
            config.setEsploraAddresses([esploraAddress]);
            return await walletPort.getTransactions(config: config);
          });
        });
      });
    } catch (e) {
      return Left(ServiceFailure(message: 'Failed to get transactions: $e'));
    }
  }

  Future<Either<Failure, void>> sync({required int walletId}) async {
    try {
      final walletResult = await _walletsRepository.getWalletById(walletId);

      return await walletResult.fold((failure) => Left(failure), (
        wallet,
      ) async {
        final walletPort = _walletPortRegistry.getPort(wallet.type);
        final configResult = await walletPort.loadWalletConfig(
          walletId: walletId,
        );
        return await configResult.fold((failure) => Left(failure), (
          config,
        ) async {
          // Get Esplora endpoint for the network
          final esploraResult = await _esploraEndpointPort
              .getEndpointUrlForNetwork(config.network);

          return await esploraResult.fold((failure) => Left(failure), (
            esploraAddress,
          ) async {
            config.setEsploraAddresses([esploraAddress]);
            return await walletPort.sync(config: config);
          });
        });
      });
    } catch (e) {
      return Left(ServiceFailure(message: 'Failed to sync wallet: $e'));
    }
  }

  Future<Either<Failure, WalletBackupVO>> getWalletBackup(int walletId) async {
    try {
      final walletResult = await _walletsRepository.getWalletById(walletId);

      return await walletResult.fold((failure) => Left(failure), (
        wallet,
      ) async {
        final walletPort = _walletPortRegistry.getPort(wallet.type);
        final configResult = await walletPort.loadWalletConfig(
          walletId: walletId,
        );
        return await configResult.fold((failure) => Left(failure), (
          config,
        ) async {
          // Get Esplora endpoint for the network
          final esploraResult = await _esploraEndpointPort
              .getEndpointUrlForNetwork(config.network);

          return await esploraResult.fold((failure) => Left(failure), (
            esploraAddress,
          ) async {
            config.setEsploraAddresses([esploraAddress]);
            return await walletPort.getBackup(config: config);
          });
        });
      });
    } catch (e) {
      return Left(ServiceFailure(message: 'Failed to get wallet backup: $e'));
    }
  }

  Future<Either<Failure, String>> confirmPayment({
    required int walletId,
    required SendPaymentRequestVO request,
  }) async {
    try {
      final walletResult = await _walletsRepository.getWalletById(walletId);

      return await walletResult.fold((failure) => Left(failure), (
        wallet,
      ) async {
        final walletPort = _walletPortRegistry.getPort(wallet.type);
        final configResult = await walletPort.loadWalletConfig(
          walletId: walletId,
        );
        return await configResult.fold((failure) => Left(failure), (
          config,
        ) async {
          // Get Esplora endpoint for the network
          final esploraResult = await _esploraEndpointPort
              .getEndpointUrlForNetwork(config.network);

          return await esploraResult.fold((failure) => Left(failure), (
            esploraAddress,
          ) async {
            config.setEsploraAddresses([esploraAddress]);
            return await walletPort.confirmPayment(config: config, request: request);
          });
        });
      });
    } catch (e) {
      return Left(ServiceFailure(message: 'Failed to confirm payment: $e'));
    }
  }
}
