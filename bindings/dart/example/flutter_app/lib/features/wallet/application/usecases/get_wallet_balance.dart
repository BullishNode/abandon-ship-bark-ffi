import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/wallet/application/services/wallet_service.dart';

/// Query for getting wallet balance
class GetWalletBalanceQuery {
  final int walletId;

  const GetWalletBalanceQuery({required this.walletId});
}

/// Response DTO for wallet balance
class WalletBalanceResponse {
  final int spendableSats;
  final int pendingInRoundSats;
  final int pendingExitSats;
  final int pendingLightningSendSats;
  final int pendingLightningReceiveTotalSats;
  final int pendingLightningReceiveClaimableSats;
  final int pendingBoardSats;

  const WalletBalanceResponse({
    required this.spendableSats,
    required this.pendingInRoundSats,
    required this.pendingExitSats,
    required this.pendingLightningSendSats,
    required this.pendingLightningReceiveTotalSats,
    required this.pendingLightningReceiveClaimableSats,
    required this.pendingBoardSats,
  });

  int get totalSats =>
      spendableSats +
      pendingInRoundSats +
      pendingExitSats +
      pendingLightningSendSats +
      pendingLightningReceiveTotalSats +
      pendingBoardSats;

  String get totalBtc => (totalSats / 100000000).toStringAsFixed(8);
}

/// Use case for getting wallet balance
class GetWalletBalance
    implements UseCase<WalletBalanceResponse, GetWalletBalanceQuery> {
  final WalletService _walletService;

  GetWalletBalance(this._walletService);

  @override
  Future<Either<Failure, WalletBalanceResponse>> call(
    GetWalletBalanceQuery query,
  ) async {
    final result = await _walletService.getBalance(walletId: query.walletId);

    return result.map(
      (balance) => WalletBalanceResponse(
        spendableSats: balance.spendableSats,
        pendingInRoundSats: balance.pendingInRoundSats,
        pendingExitSats: balance.pendingExitSats,
        pendingLightningSendSats: balance.pendingLightningSendSats,
        pendingLightningReceiveTotalSats:
            balance.pendingLightningReceiveTotalSats,
        pendingLightningReceiveClaimableSats:
            balance.pendingLightningReceiveClaimableSats,
        pendingBoardSats: balance.pendingBoardSats,
      ),
    );
  }
}
