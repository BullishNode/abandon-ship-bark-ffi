import 'package:equatable/equatable.dart';

/// Wallet balance view model for UI display
/// TODO: abstract to a base class with subtypes for different types of wallet balances
class WalletBalanceVM extends Equatable {
  final int walletId;
  final int spendableSats;
  final int pendingInRoundSats;
  final int pendingExitSats;
  final int pendingLightningSendSats;
  final int pendingLightningReceiveTotalSats;
  final int pendingLightningReceiveClaimableSats;
  final int pendingBoardSats;

  const WalletBalanceVM({
    required this.walletId,
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

  @override
  List<Object> get props => [
    walletId,
    spendableSats,
    pendingInRoundSats,
    pendingExitSats,
    pendingLightningSendSats,
    pendingLightningReceiveTotalSats,
    pendingLightningReceiveClaimableSats,
    pendingBoardSats,
  ];
}
