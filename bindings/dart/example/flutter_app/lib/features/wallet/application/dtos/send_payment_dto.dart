import 'package:equatable/equatable.dart';

/// Data transfer object for send payment result
sealed class SendPaymentDto extends Equatable {
  const SendPaymentDto();
}

/// Arkoor payment result
class ArkoorSendPaymentDto extends SendPaymentDto {
  final String txid;
  final int amountSats;

  const ArkoorSendPaymentDto({
    required this.txid,
    required this.amountSats,
  });

  @override
  List<Object> get props => [txid, amountSats];
}
