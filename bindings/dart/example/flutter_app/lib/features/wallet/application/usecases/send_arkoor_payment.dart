import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/wallet/application/dtos/send_payment_dto.dart';
import 'package:flutter_app/features/wallet/application/services/wallet_service.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/send_payment_request_vo.dart';

/// Command for sending an Arkoor payment
class SendArkoorPaymentCommand {
  final int walletId;
  final String arkAddress;
  final int amountSats;

  const SendArkoorPaymentCommand({
    required this.walletId,
    required this.arkAddress,
    required this.amountSats,
  });
}

/// Response containing the payment result
class SendPaymentResponse {
  final SendPaymentDto result;

  const SendPaymentResponse({required this.result});
}

/// Use case for sending Arkoor payments
class SendArkoorPayment
    implements UseCase<SendPaymentResponse, SendArkoorPaymentCommand> {
  final WalletService _walletService;

  SendArkoorPayment({required WalletService walletService})
      : _walletService = walletService;

  @override
  Future<Either<Failure, SendPaymentResponse>> call(
    SendArkoorPaymentCommand command,
  ) async {
    try {
      final request = ArkoorSendPaymentRequestVO(
        arkAddress: command.arkAddress,
        amountSats: command.amountSats,
      );

      final result = await _walletService.confirmPayment(
        walletId: command.walletId,
        request: request,
      );

      return result.fold(
        (failure) => Left(failure),
        (txid) => Right(
          SendPaymentResponse(
            result: ArkoorSendPaymentDto(
              txid: txid,
              amountSats: command.amountSats,
            ),
          ),
        ),
      );
    } catch (e) {
      return Left(
        ServiceFailure(message: 'Failed to send Arkoor payment: $e'),
      );
    }
  }
}
