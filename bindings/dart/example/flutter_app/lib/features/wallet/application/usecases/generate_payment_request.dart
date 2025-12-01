import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/wallet/application/services/wallet_service.dart';

/// Command for generating a new receive address
class GeneratePaymentRequestCommand {
  final int walletId;

  const GeneratePaymentRequestCommand({required this.walletId});
}

/// Response containing the generated address
class GeneratePaymentRequestResponse {
  final String paymentRequest;

  const GeneratePaymentRequestResponse({required this.paymentRequest});
}

/// Use case for generating a new Ark receive address
class GeneratePaymentRequest
    implements
        UseCase<GeneratePaymentRequestResponse, GeneratePaymentRequestCommand> {
  final WalletService _walletService;

  GeneratePaymentRequest({required WalletService walletService})
    : _walletService = walletService;

  @override
  Future<Either<Failure, GeneratePaymentRequestResponse>> call(
    GeneratePaymentRequestCommand command,
  ) async {
    try {
      // 1. Get the bark wallet entity from repository
      final paymentRequestResult = await _walletService.generatePaymentRequest(
        walletId: command.walletId,
      );

      return paymentRequestResult.fold((failure) => Left(failure), (
        request,
      ) async {
        return Right(GeneratePaymentRequestResponse(paymentRequest: request));
      });
    } catch (e) {
      return Left(
        ServiceFailure(message: 'Failed to generate payment request: $e'),
      );
    }
  }
}
