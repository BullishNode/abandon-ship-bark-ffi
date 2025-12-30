import 'package:equatable/equatable.dart';

/// Bark wallet balance value object (no ID, immutable)
/// TODO: abstract to a base class named Balance with subtypes for different types of balances like BarkBalance, BitcoinBalance, etc.
class BarkBalanceVO extends Equatable {
  final int spendableSats;
  final int pendingInRoundSats;
  final int pendingExitSats;
  final int pendingLightningSendSats;
  final int claimableLightningReceiveSats;
  final int pendingBoardSats;

  const BarkBalanceVO({
    required this.spendableSats,
    required this.pendingInRoundSats,
    required this.pendingExitSats,
    required this.pendingLightningSendSats,
    required this.claimableLightningReceiveSats,
    required this.pendingBoardSats,
  });

  /// Total balance in satoshis (all pending + spendable)
  int get totalSats =>
      spendableSats +
      pendingInRoundSats +
      pendingExitSats +
      pendingLightningSendSats +
      claimableLightningReceiveSats +
      pendingBoardSats;

  @override
  List<Object> get props => [
    spendableSats,
    pendingInRoundSats,
    pendingExitSats,
    pendingLightningSendSats,
    claimableLightningReceiveSats,
    pendingBoardSats,
  ];
}
