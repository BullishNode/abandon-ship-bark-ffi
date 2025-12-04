import 'package:equatable/equatable.dart';

/// Base class for wallet events
abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all wallets
class LoadWallets extends WalletEvent {
  const LoadWallets();
}

/// Event to create a new Bark wallet
class CreateWallet extends WalletEvent {
  final String name;
  final String asp;
  final String? description;
  final int? vtxoRefreshExpiryThreshold;
  final int? vtxoExitMargin;
  final int? htlcRecvClaimDelta;

  const CreateWallet({
    required this.name,
    required this.asp,
    this.description,
    this.vtxoRefreshExpiryThreshold,
    this.vtxoExitMargin,
    this.htlcRecvClaimDelta,
  });

  @override
  List<Object?> get props => [
    name,
    asp,
    description,
    vtxoRefreshExpiryThreshold,
    vtxoExitMargin,
    htlcRecvClaimDelta,
  ];
}

/// Event to load balance for a specific wallet
class LoadWalletBalance extends WalletEvent {
  final int walletId;

  const LoadWalletBalance(this.walletId);

  @override
  List<Object> get props => [walletId];
}

/// Event to refresh wallet balance
class RefreshWalletBalance extends WalletEvent {
  final int walletId;

  const RefreshWalletBalance(this.walletId);

  @override
  List<Object> get props => [walletId];
}

/// Event to generate a new receive address
class GeneratePaymentRequest extends WalletEvent {
  final int walletId;

  const GeneratePaymentRequest(this.walletId);

  @override
  List<Object> get props => [walletId];
}

/// Event to sync wallet(s) with server and refresh balance
/// If walletId is null, syncs all wallets
class SyncWallet extends WalletEvent {
  final int? walletId;

  const SyncWallet([this.walletId]);

  @override
  List<Object?> get props => [walletId];
}

/// Event to load VTXOs for a wallet
class LoadVtxos extends WalletEvent {
  final int walletId;

  const LoadVtxos(this.walletId);

  @override
  List<Object> get props => [walletId];
}

/// Event to load transactions for a wallet
class LoadTransactions extends WalletEvent {
  final int walletId;

  const LoadTransactions(this.walletId);

  @override
  List<Object> get props => [walletId];
}
