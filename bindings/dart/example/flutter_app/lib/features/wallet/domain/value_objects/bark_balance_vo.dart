import 'package:equatable/equatable.dart';

/// Bark wallet balance value object (no ID, immutable)
class BarkBalanceVO extends Equatable {
  final int spendableSats;
  final int pendingInRoundSats;
  final int pendingExitSats;
  final int pendingLightningSendSats;
  final int pendingLightningReceiveTotalSats;
  final int pendingLightningReceiveClaimableSats;
  final int pendingBoardSats;

  const BarkBalanceVO({
    required this.spendableSats,
    required this.pendingInRoundSats,
    required this.pendingExitSats,
    required this.pendingLightningSendSats,
    required this.pendingLightningReceiveTotalSats,
    required this.pendingLightningReceiveClaimableSats,
    required this.pendingBoardSats,
  });

  /// Total balance in satoshis (all pending + spendable)
  int get totalSats =>
      spendableSats +
      pendingInRoundSats +
      pendingExitSats +
      pendingLightningSendSats +
      pendingLightningReceiveTotalSats +
      pendingBoardSats;

  /// Total balance in BTC
  String get totalBtc => (totalSats / 100000000).toStringAsFixed(8);

  @override
  List<Object> get props => [
        spendableSats,
        pendingInRoundSats,
        pendingExitSats,
        pendingLightningSendSats,
        pendingLightningReceiveTotalSats,
        pendingLightningReceiveClaimableSats,
        pendingBoardSats,
      ];
}
