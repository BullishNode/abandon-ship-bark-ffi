import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/wallet/application/ports/wallets_repository_port.dart';

/// Response DTO for wallet summary
class WalletSummaryResponse {
  final int id;
  final String name;
  final String? description;
  final String type;
  final String network;
  final DateTime createdAt;

  const WalletSummaryResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.network,
    required this.createdAt,
  });
}

/// Use case for getting all wallets
class GetAllWallets implements UseCase<List<WalletSummaryResponse>, NoParams> {
  final WalletsRepositoryPort _repository;

  GetAllWallets(this._repository);

  @override
  Future<Either<Failure, List<WalletSummaryResponse>>> call(
    NoParams params,
  ) async {
    final result = await _repository.getAllWallets();

    return result.map(
      (wallets) => wallets
          .map(
            (wallet) => WalletSummaryResponse(
              id: wallet.id,
              name: wallet.name,
              description: wallet.description,
              type: wallet.type.value,
              network: wallet.network,
              createdAt: wallet.createdAt,
            ),
          )
          .toList(),
    );
  }
}
