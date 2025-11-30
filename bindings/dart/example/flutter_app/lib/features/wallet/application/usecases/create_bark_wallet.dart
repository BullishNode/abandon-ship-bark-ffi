import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/wallet/application/dtos/bark_wallet_dto.dart';
import 'package:flutter_app/features/wallet/application/ports/bitcoin_network_port.dart';
import 'package:flutter_app/features/wallet/application/services/wallet_service.dart';
import 'package:flutter_app/features/wallet/domain/entities/wallet_config.dart';

/// Command for creating a Bark wallet
class CreateBarkWalletCommand {
  final String name;
  final String asp;
  final String? description;
  final int? vtxoRefreshExpiryThreshold;
  final int? vtxoExitMargin;
  final int? htlcRecvClaimDelta;

  const CreateBarkWalletCommand({
    required this.name,
    required this.asp,
    this.description,
    this.vtxoRefreshExpiryThreshold,
    this.vtxoExitMargin,
    this.htlcRecvClaimDelta,
  });
}

/// Response DTO for created Bark wallet
class CreateBarkWalletResponse {
  final BarkWalletDto wallet;

  const CreateBarkWalletResponse({required this.wallet});
}

/// Use case for creating a new Bark wallet
/// Orchestrates: mnemonic generation, wallet creation, secure storage
/// Network and Esplora endpoint are obtained from settings via ports
class CreateBarkWallet
    implements UseCase<CreateBarkWalletResponse, CreateBarkWalletCommand> {
  final BitcoinNetworkPort _bitcoinNetworkPort;
  final WalletService _walletService;

  CreateBarkWallet({
    required WalletService walletService,
    required BitcoinNetworkPort bitcoinNetworkPort,
  }) : _walletService = walletService,
       _bitcoinNetworkPort = bitcoinNetworkPort;

  @override
  Future<Either<Failure, CreateBarkWalletResponse>> call(
    CreateBarkWalletCommand command,
  ) async {
    try {
      // Get current network from settings
      final networkResult = await _bitcoinNetworkPort.getCurrentNetwork();
      return await networkResult.fold((failure) => Left(failure), (
        network,
      ) async {
        // Create wallet using wallet service
        final walletResult = await _walletService.createBarkWallet(
          name: command.name,
          description: command.description,
          network: network,
          asp: command.asp,
          vtxoRefreshExpiryThreshold: command.vtxoRefreshExpiryThreshold,
          vtxoExitMargin: command.vtxoExitMargin,
          htlcRecvClaimDelta: command.htlcRecvClaimDelta,
        );

        return await walletResult.fold((failure) => Left(failure), (
          wallet,
        ) async {
          final config = wallet.config;
          if (config is! BarkWalletConfig) {
            return const Left(
              ServiceFailure(message: 'Invalid wallet configuration type'),
            );
          }
          return Right(
            CreateBarkWalletResponse(
              wallet: BarkWalletDto(
                id: wallet.id,
                name: wallet.name,
                network: wallet.network,
                description: wallet.description,
                fingerprint: config.fingerprint,
                asp: config.asp,
                vtxoRefreshExpiryThreshold: config.vtxoRefreshExpiryThreshold,
                vtxoExitMargin: config.vtxoExitMargin,
                htlcRecvClaimDelta: config.htlcRecvClaimDelta,
              ),
            ),
          );
        });
      });
    } catch (e) {
      return Left(ServiceFailure(message: 'Failed to create wallet: $e'));
    }
  }
}
