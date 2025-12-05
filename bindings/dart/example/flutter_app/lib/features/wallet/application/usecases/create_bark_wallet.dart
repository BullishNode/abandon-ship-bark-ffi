import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/wallet/application/dtos/wallet_dto.dart';
import 'package:flutter_app/features/wallet/application/ports/bitcoin_network_port.dart';
import 'package:flutter_app/features/wallet/application/services/wallet_service.dart';

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
  final WalletDto wallet;

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
          return Right(
            CreateBarkWalletResponse(
              wallet: WalletDto(
                id: wallet.id,
                name: wallet.name,
                network: wallet.network,
                description: wallet.description,
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
