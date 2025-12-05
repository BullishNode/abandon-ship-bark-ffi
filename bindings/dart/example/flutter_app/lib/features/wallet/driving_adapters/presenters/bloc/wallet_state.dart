import 'package:equatable/equatable.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/view_models/transaction_vm.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/view_models/vtxo_vm.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/view_models/wallet_backup_vm.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/view_models/wallet_balance_vm.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/view_models/wallet_summary_vm.dart';

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

/// Wallets loaded state
class WalletsLoaded extends WalletState {
  final List<WalletSummaryVM> wallets;
  final Map<int, WalletBalanceVM> balances;
  final Map<int, List<VtxoVM>> vtxos;
  final Map<int, List<TransactionVM>> transactions;

  const WalletsLoaded({
    required this.wallets,
    this.balances = const {},
    this.vtxos = const {},
    this.transactions = const {},
  });

  @override
  List<Object> get props => [wallets, balances, vtxos, transactions];

  WalletsLoaded copyWith({
    List<WalletSummaryVM>? wallets,
    Map<int, WalletBalanceVM>? balances,
    Map<int, List<VtxoVM>>? vtxos,
    Map<int, List<TransactionVM>>? transactions,
  }) {
    return WalletsLoaded(
      wallets: wallets ?? this.wallets,
      balances: balances ?? this.balances,
      vtxos: vtxos ?? this.vtxos,
      transactions: transactions ?? this.transactions,
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

/// Loading wallet backup
class LoadingBackup extends WalletState {
  final int walletId;

  const LoadingBackup(this.walletId);

  @override
  List<Object> get props => [walletId];
}

/// Wallet backup loaded successfully
class BackupLoaded extends WalletState {
  final int walletId;
  final WalletBackupVM backup;

  const BackupLoaded({
    required this.walletId,
    required this.backup,
  });

  @override
  List<Object> get props => [walletId, backup];
}

/// Sending payment state
class SendingPayment extends WalletState {
  final int walletId;

  const SendingPayment(this.walletId);

  @override
  List<Object> get props => [walletId];
}

/// Payment sent successfully
class PaymentSent extends WalletState {
  final int walletId;
  final String txid;
  final int amountSats;

  const PaymentSent({
    required this.walletId,
    required this.txid,
    required this.amountSats,
  });

  @override
  List<Object> get props => [walletId, txid, amountSats];
}
