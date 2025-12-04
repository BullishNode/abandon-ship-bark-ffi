import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/wallet/application/services/wallet_service.dart';

/// Query for getting wallet transactions
class GetWalletTransactionsQuery {
  final int walletId;

  const GetWalletTransactionsQuery({required this.walletId});
}

/// Response DTO for wallet transaction
class TransactionResponse {
  final int id;
  final String status;
  final String subsystemName;
  final String subsystemKind;
  final int intendedBalanceSats;
  final int effectiveBalanceSats;
  final int offchainFeeSats;
  final String createdAt;
  final String? completedAt;

  const TransactionResponse({
    required this.id,
    required this.status,
    required this.subsystemName,
    required this.subsystemKind,
    required this.intendedBalanceSats,
    required this.effectiveBalanceSats,
    required this.offchainFeeSats,
    required this.createdAt,
    this.completedAt,
  });
}

/// Use case for getting wallet transactions
class GetWalletTransactions
    implements UseCase<List<TransactionResponse>, GetWalletTransactionsQuery> {
  final WalletService _walletService;

  GetWalletTransactions(this._walletService);

  @override
  Future<Either<Failure, List<TransactionResponse>>> call(
    GetWalletTransactionsQuery query,
  ) async {
    final result =
        await _walletService.getTransactions(walletId: query.walletId);

    return result.map(
      (transactions) => transactions
          .map(
            (tx) => TransactionResponse(
              id: tx.id,
              status: tx.status,
              subsystemName: tx.subsystemName,
              subsystemKind: tx.subsystemKind,
              intendedBalanceSats: tx.intendedBalanceSats,
              effectiveBalanceSats: tx.effectiveBalanceSats,
              offchainFeeSats: tx.offchainFeeSats,
              createdAt: tx.createdAt,
              completedAt: tx.completedAt,
            ),
          )
          .toList(),
    );
  }
}
