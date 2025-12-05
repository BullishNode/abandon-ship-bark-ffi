import 'package:equatable/equatable.dart';

/// Value object representing a send payment request
sealed class SendPaymentRequestVO extends Equatable {
  const SendPaymentRequestVO();
}

/// Arkoor payment request (out-of-round payment to another Ark user)
class ArkoorSendPaymentRequestVO extends SendPaymentRequestVO {
  final String arkAddress;
  final int amountSats;

  const ArkoorSendPaymentRequestVO({
    required this.arkAddress,
    required this.amountSats,
  });

  @override
  List<Object> get props => [arkAddress, amountSats];
}
