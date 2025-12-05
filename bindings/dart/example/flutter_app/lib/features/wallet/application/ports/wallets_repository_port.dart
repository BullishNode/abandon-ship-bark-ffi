import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/wallet_type_vo.dart';

abstract class WalletsRepositoryPort {
  Future<Either<Failure, WalletEntity>> createWallet({
    required String name,
    required String network,
    required WalletTypeVO type,
    String? description,
  });
  Future<Either<Failure, WalletEntity>> getWalletById(int walletId);
  Future<Either<Failure, List<WalletEntity>>> getAllWallets();
}
