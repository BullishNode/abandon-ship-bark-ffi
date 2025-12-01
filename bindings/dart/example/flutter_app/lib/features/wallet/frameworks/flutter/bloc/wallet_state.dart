import 'package:equatable/equatable.dart';

/// Wallet summary for UI display
class WalletSummary extends Equatable {
  final int id;
  final String name;
  final String network;
  final DateTime createdAt;

  const WalletSummary({
    required this.id,
    required this.name,
    required this.network,
    required this.createdAt,
  });

  @override
  List<Object> get props => [id, name, network, createdAt];
}

/// Wallet balance for UI display
class WalletBalance extends Equatable {
  final int walletId;
  final int spendableSats;
  final int pendingInRoundSats;
  final int pendingExitSats;
  final int pendingLightningSendSats;
  final int pendingLightningReceiveTotalSats;
  final int pendingLightningReceiveClaimableSats;
  final int pendingBoardSats;

  const WalletBalance({
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

/// Base class for wallet states
abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class WalletInitial extends WalletState {
  const WalletInitial();
}

/// Loading state
class WalletLoading extends WalletState {
  const WalletLoading();
}

/// VTXO for UI display
class Vtxo extends Equatable {
  final String id;
  final int amountSats;
  final int expiryHeight;
  final String kind;
  final String state;

  const Vtxo({
    required this.id,
    required this.amountSats,
    required this.expiryHeight,
    required this.kind,
    required this.state,
  });

  String get amountBtc => (amountSats / 100000000).toStringAsFixed(8);

  @override
  List<Object> get props => [id, amountSats, expiryHeight, kind, state];
}

/// Wallets loaded state
class WalletsLoaded extends WalletState {
  final List<WalletSummary> wallets;
  final Map<int, WalletBalance> balances;
  final Map<int, List<Vtxo>> vtxos;

  const WalletsLoaded({
    required this.wallets,
    this.balances = const {},
    this.vtxos = const {},
  });

  @override
  List<Object> get props => [wallets, balances, vtxos];

  WalletsLoaded copyWith({
    List<WalletSummary>? wallets,
    Map<int, WalletBalance>? balances,
    Map<int, List<Vtxo>>? vtxos,
  }) {
    return WalletsLoaded(
      wallets: wallets ?? this.wallets,
      balances: balances ?? this.balances,
      vtxos: vtxos ?? this.vtxos,
    );
  }
}

/// Creating wallet state
class CreatingWallet extends WalletState {
  const CreatingWallet();
}

/// Wallet created successfully
class WalletCreated extends WalletState {
  final int walletId;
  final String name;

  const WalletCreated({required this.walletId, required this.name});

  @override
  List<Object> get props => [walletId, name];
}

/// Loading balance state
class LoadingBalance extends WalletState {
  final int walletId;

  const LoadingBalance(this.walletId);

  @override
  List<Object> get props => [walletId];
}

/// Error state
class WalletError extends WalletState {
  final String message;

  const WalletError(this.message);

  @override
  List<Object> get props => [message];
}

/// Generating receive address state
class GeneratingPaymentRequest extends WalletState {
  final int walletId;

  const GeneratingPaymentRequest(this.walletId);

  @override
  List<Object> get props => [walletId];
}

/// Receive address generated successfully
class PaymentRequestGenerated extends WalletState {
  final int walletId;
  final String paymentRequest;

  const PaymentRequestGenerated({
    required this.walletId,
    required this.paymentRequest,
  });

  @override
  List<Object> get props => [walletId, paymentRequest];
}
