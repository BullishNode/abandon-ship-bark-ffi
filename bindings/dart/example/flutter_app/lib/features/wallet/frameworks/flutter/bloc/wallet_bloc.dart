import 'package:flutter/widgets.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/wallet/application/usecases/create_bark_wallet.dart';
import 'package:flutter_app/features/wallet/application/usecases/generate_payment_request.dart';
import 'package:flutter_app/features/wallet/application/usecases/get_all_wallets.dart';
import 'package:flutter_app/features/wallet/application/usecases/get_wallet_balance.dart';
import 'package:flutter_app/features/wallet/application/usecases/get_wallet_vtxos.dart';
import 'package:flutter_app/features/wallet/application/usecases/sync_wallet.dart';
import 'package:flutter_app/features/wallet/frameworks/flutter/bloc/wallet_event.dart'
    as events;
import 'package:flutter_app/features/wallet/frameworks/flutter/bloc/wallet_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC for managing wallets
/// Transforms data between use cases and UI
class WalletBloc extends Bloc<events.WalletEvent, WalletState> {
  final GetAllWallets _getAllWallets;
  final CreateBarkWallet _createBarkWallet;
  final GetWalletBalance _getWalletBalance;
  final GeneratePaymentRequest _generatePaymentRequest;
  final SyncWallet _syncWallet;
  final GetWalletVtxos _getWalletVtxos;

  WalletBloc({
    required GetAllWallets getAllWallets,
    required CreateBarkWallet createBarkWallet,
    required GetWalletBalance getWalletBalance,
    required GeneratePaymentRequest generatePaymentRequest,
    required SyncWallet syncWallet,
    required GetWalletVtxos getWalletVtxos,
  }) : _getAllWallets = getAllWallets,
       _createBarkWallet = createBarkWallet,
       _getWalletBalance = getWalletBalance,
       _generatePaymentRequest = generatePaymentRequest,
       _syncWallet = syncWallet,
       _getWalletVtxos = getWalletVtxos,
       super(const WalletInitial()) {
    on<events.LoadWallets>(_onLoadWallets);
    on<events.CreateWallet>(_onCreateWallet);
    on<events.LoadWalletBalance>(_onLoadWalletBalance);
    on<events.RefreshWalletBalance>(_onRefreshWalletBalance);
    on<events.GeneratePaymentRequest>(_onGeneratePaymentRequest);
    on<events.SyncWallet>(_onSyncWallet);
    on<events.LoadVtxos>(_onLoadVtxos);
  }

  Future<void> _onLoadWallets(
    events.LoadWallets event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());

    final result = await _getAllWallets(NoParams());

    result.fold((failure) => emit(WalletError(failure.message)), (wallets) {
      final walletSummaries = wallets
          .map(
            (w) => WalletSummary(
              id: w.id,
              name: w.name,
              network: w.network,
              createdAt: w.createdAt,
            ),
          )
          .toList();

      emit(WalletsLoaded(wallets: walletSummaries));

      // Automatically sync wallets and load VTXOs after loading
      add(events.SyncWallet());

      // Load VTXOs for all wallets
      for (final wallet in walletSummaries) {
        add(events.LoadVtxos(wallet.id));
      }
    });
  }

  Future<void> _onCreateWallet(
    events.CreateWallet event,
    Emitter<WalletState> emit,
  ) async {
    emit(const CreatingWallet());

    final result = await _createBarkWallet(
      CreateBarkWalletCommand(
        name: event.name,
        asp: event.asp,
        description: event.description,
        vtxoRefreshExpiryThreshold: event.vtxoRefreshExpiryThreshold,
        vtxoExitMargin: event.vtxoExitMargin,
        htlcRecvClaimDelta: event.htlcRecvClaimDelta,
      ),
    );

    result.fold((failure) => emit(WalletError(failure.message)), (response) {
      emit(
        WalletCreated(walletId: response.wallet.id, name: response.wallet.name),
      );
      // Reload wallets after creation
      add(const events.LoadWallets());
    });
  }

  Future<void> _onLoadWalletBalance(
    events.LoadWalletBalance event,
    Emitter<WalletState> emit,
  ) async {
    if (state is! WalletsLoaded) {
      return;
    }

    // Don't emit loading state to avoid blocking other wallet balance loads
    // Just load in the background
    final result = await _getWalletBalance(
      GetWalletBalanceQuery(walletId: event.walletId),
    );

    result.fold(
      (failure) {
        // Log the error but don't change state - just skip this wallet
        debugPrint(
          'Failed to load balance for wallet ${event.walletId}: ${failure.message}',
        );
      },
      (balance) {
        // Only update if we're still in a WalletsLoaded state
        final currentState = state;
        if (currentState is WalletsLoaded) {
          final updatedBalances = Map<int, WalletBalance>.from(
            currentState.balances,
          );
          updatedBalances[event.walletId] = WalletBalance(
            walletId: event.walletId,
            spendableSats: balance.spendableSats,
            pendingInRoundSats: balance.pendingInRoundSats,
            pendingExitSats: balance.pendingExitSats,
            pendingLightningSendSats: balance.pendingLightningSendSats,
            pendingLightningReceiveTotalSats:
                balance.pendingLightningReceiveTotalSats,
            pendingLightningReceiveClaimableSats:
                balance.pendingLightningReceiveClaimableSats,
            pendingBoardSats: balance.pendingBoardSats,
          );

          emit(currentState.copyWith(balances: updatedBalances));
        }
      },
    );
  }

  Future<void> _onRefreshWalletBalance(
    events.RefreshWalletBalance event,
    Emitter<WalletState> emit,
  ) async {
    // Same as load but can show different UI feedback if needed
    add(events.LoadWalletBalance(event.walletId));
  }

  Future<void> _onGeneratePaymentRequest(
    events.GeneratePaymentRequest event,
    Emitter<WalletState> emit,
  ) async {
    emit(GeneratingPaymentRequest(event.walletId));

    final result = await _generatePaymentRequest(
      GeneratePaymentRequestCommand(walletId: event.walletId),
    );

    result.fold(
      (failure) => emit(WalletError(failure.message)),
      (response) => emit(
        PaymentRequestGenerated(
          walletId: event.walletId,
          paymentRequest: response.paymentRequest,
        ),
      ),
    );
  }

  Future<void> _onSyncWallet(
    events.SyncWallet event,
    Emitter<WalletState> emit,
  ) async {
    // Get current state if it's WalletsLoaded
    if (state is! WalletsLoaded) {
      return;
    }

    final walletsState = state as WalletsLoaded;

    // If walletId is provided, sync only that wallet, otherwise sync all
    final walletsToSync = event.walletId != null
        ? walletsState.wallets.where((w) => w.id == event.walletId).toList()
        : walletsState.wallets;

    // Sync wallets concurrently
    final syncFutures = walletsToSync.map((wallet) async {
      final result = await _syncWallet(SyncWalletCommand(walletId: wallet.id));

      result.fold(
        (failure) => debugPrint(
          'Failed to sync wallet ${wallet.id}: ${failure.message}',
        ),
        (_) {
          // After successful sync, reload balance and VTXOs
          add(events.LoadWalletBalance(wallet.id));
          add(events.LoadVtxos(wallet.id));
        },
      );
    });

    await Future.wait(syncFutures);
  }

  Future<void> _onLoadVtxos(
    events.LoadVtxos event,
    Emitter<WalletState> emit,
  ) async {
    // Get the current WalletsLoaded state
    if (state is! WalletsLoaded) {
      return;
    }

    state as WalletsLoaded;

    // Load VTXOs in the background without changing state
    final result = await _getWalletVtxos(
      GetWalletVtxosQuery(walletId: event.walletId),
    );

    result.fold(
      (failure) {
        debugPrint(
          'Failed to load VTXOs for wallet ${event.walletId}: ${failure.message}',
        );
      },
      (vtxoResponses) {
        // Only update if we're still in a WalletsLoaded state
        final currentState = state;
        if (currentState is WalletsLoaded) {
          final updatedVtxos = Map<int, List<Vtxo>>.from(currentState.vtxos);
          updatedVtxos[event.walletId] = vtxoResponses
              .map(
                (v) => Vtxo(
                  id: v.id,
                  amountSats: v.amountSats,
                  expiryHeight: v.expiryHeight,
                  kind: v.kind,
                  state: v.state,
                ),
              )
              .toList();

          emit(currentState.copyWith(vtxos: updatedVtxos));
        }
      },
    );
  }
}
