import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/wallet/application/services/wallet_service.dart';

/// Command for syncing a wallet
class SyncWalletCommand {
  final int walletId;

  const SyncWalletCommand({required this.walletId});
}

/// Use case for syncing wallet with server
class SyncWallet implements UseCase<void, SyncWalletCommand> {
  final WalletService _walletService;

  SyncWallet(this._walletService);

  @override
  Future<Either<Failure, void>> call(SyncWalletCommand command) async {
    return await _walletService.sync(walletId: command.walletId);
  }
}
