import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/bark_balance_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/vtxo_vo.dart';

/// Port for Bark wallet
/// Abstracts the bark layer from the domain
abstract class WalletPort {
  /// Generate a payment request
  Future<Either<Failure, String>> generatePaymentRequest({
    required WalletEntity wallet,
  });

  /// Get wallet balance
  Future<Either<Failure, BarkBalanceVO>> getBalance({
    required WalletEntity wallet,
  });

  /// Get all VTXOs for a wallet
  Future<Either<Failure, List<VtxoVO>>> getVtxos({
    required WalletEntity wallet,
  });

  /// Sync wallet with server to fetch latest transactions
  Future<Either<Failure, void>> sync({
    required WalletEntity wallet,
  });
}
