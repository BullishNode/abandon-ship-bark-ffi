import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/features/wallet/domain/entities/wallet_config_entity.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/bark_balance_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/new_wallet_config_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/transaction_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/vtxo_vo.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/wallet_backup_vo.dart';

/// Port for Bark wallet
/// Abstracts the bark layer from the domain
abstract class WalletPort {
  /// Create a new wallet with the given configuration
  Future<Either<Failure, WalletConfigEntity>> createWallet(
    NewWalletConfigVO config,
  );

  /// Recover a wallet from backup data
  Future<Either<Failure, WalletConfigEntity>> recoverWallet({
    required WalletBackupVO backup,
    required NewWalletConfigVO config,
  });

  Future<Either<Failure, WalletConfigEntity>> loadWalletConfig({
    required int walletId,
  });

  /// Generate a payment request
  Future<Either<Failure, String>> generatePaymentRequest({
    required WalletConfigEntity config,
  });

  /// Get wallet balance
  Future<Either<Failure, BarkBalanceVO>> getBalance({
    required WalletConfigEntity config,
  });

  /// Get all VTXOs for a wallet
  Future<Either<Failure, List<VtxoVO>>> getVtxos({
    required WalletConfigEntity config,
  });

  /// Get all transactions for a wallet
  Future<Either<Failure, List<TransactionVO>>> getTransactions({
    required WalletConfigEntity config,
  });

  /// Sync wallet with server to fetch latest transactions
  Future<Either<Failure, void>> sync({required WalletConfigEntity config});

  /// Get wallet backup data
  Future<Either<Failure, WalletBackupVO>> getBackup({
    required WalletConfigEntity config,
  });
}
