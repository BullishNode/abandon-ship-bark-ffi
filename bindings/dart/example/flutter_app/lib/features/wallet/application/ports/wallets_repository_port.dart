import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter_app/features/wallet/domain/entities/wallet_config.dart';

abstract class WalletsRepositoryPort {
  Future<Either<Failure, WalletEntity>> createBarkWallet({
    required String name,
    required String network,
    String? description,
    required BarkWalletConfig config,
  });
  Future<Either<Failure, WalletEntity>> getWalletById(int walletId);
  Future<Either<Failure, List<WalletEntity>>> getAllWallets();
}
