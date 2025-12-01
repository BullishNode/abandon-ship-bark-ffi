import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/wallet/application/services/wallet_service.dart';

/// Query for getting wallet VTXOs
class GetWalletVtxosQuery {
  final int walletId;

  const GetWalletVtxosQuery({required this.walletId});
}

/// Response DTO for wallet VTXO
class VtxoResponse {
  final String id;
  final int amountSats;
  final int expiryHeight;
  final String kind;
  final String state;

  const VtxoResponse({
    required this.id,
    required this.amountSats,
    required this.expiryHeight,
    required this.kind,
    required this.state,
  });

  String get amountBtc => (amountSats / 100000000).toStringAsFixed(8);
}

/// Use case for getting wallet VTXOs
class GetWalletVtxos
    implements UseCase<List<VtxoResponse>, GetWalletVtxosQuery> {
  final WalletService _walletService;

  GetWalletVtxos(this._walletService);

  @override
  Future<Either<Failure, List<VtxoResponse>>> call(
    GetWalletVtxosQuery query,
  ) async {
    final result = await _walletService.getVtxos(walletId: query.walletId);

    return result.map(
      (vtxos) => vtxos
          .map(
            (vtxo) => VtxoResponse(
              id: vtxo.id,
              amountSats: vtxo.amountSats,
              expiryHeight: vtxo.expiryHeight,
              kind: vtxo.kind,
              state: vtxo.state,
            ),
          )
          .toList(),
    );
  }
}
