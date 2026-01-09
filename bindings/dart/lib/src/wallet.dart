import 'dart:isolate';
import 'package:bark/src/generated/bark.dart' as ffi;
import 'package:bark/src/errors.dart';
import 'package:bark/src/onchain_wallet.dart' show OnchainWallet;

/// The central entry point for using Bark as an Ark wallet.
///
/// This Dart wrapper provides an interface over the blocking FFI layer.
/// Long-running operations run in isolates to avoid blocking the main thread.
///
/// ## Overview
///
/// Wallet encapsulates the complete Ark client implementation:
/// - Address generation (Ark addresses/keys)
/// - Boarding onchain funds into Ark from an onchain wallet
/// - Offboarding Ark funds to move them back onchain
/// - Sending and receiving over the Lightning Network
/// - Out-of-round (arkoor) payments directly to other Ark users
///
/// ## Architecture
///
/// The Rust FFI layer uses a global Tokio runtime that handles all async operations
/// internally. Blocking FFI methods are wrapped in `Isolate.run()` to prevent blocking
/// the Dart main isolate.
class Wallet {
  final ffi.Wallet _inner;

  Wallet._(this._inner);

  // ------------------------------------------------------------------------
  // Factory methods
  // ------------------------------------------------------------------------

  /// Create a new Bark wallet.
  ///
  /// The user experience of setting up an Ark wallet is similar to setting up
  /// an onchain wallet. You need to provide a mnemonic which can be used to
  /// recover funds.
  ///
  /// You will also need a place to store all VTXOs on the user's device.
  /// The `datadir` parameter specifies where the SQLite database will be created.
  static Future<Wallet> create(
    String mnemonic,
    ffi.Config config,
    String datadir,
    bool forceRescan,
  ) async {
    try {
      final inner = await Isolate.run(() {
        return ffi.Wallet.create(mnemonic, config, datadir, forceRescan);
      });
      return Wallet._(inner);
    } on ffi.BarkException catch (e) {
      assert(() {
        print('BarkException in Wallet.create: ${e.message}');
        return true;
      }());
      rethrow;
    }
  }

  /// Open an existing Bark wallet.
  ///
  /// The wallet can be opened again by providing the mnemonic and database path.
  static Future<Wallet> open(
    String mnemonic,
    ffi.Config config,
    String datadir,
  ) async {
    try {
      final inner = await Isolate.run(() {
        return ffi.Wallet.open(mnemonic, config, datadir);
      });
      return Wallet._(inner);
    } on ffi.BarkException catch (e) {
      assert(() {
        print('BarkException in Wallet.open: ${e.message}');
        return true;
      }());
      rethrow;
    }
  }

  /// Create a new Bark wallet with onchain capabilities.
  ///
  /// This enables full Ark functionality including boarding and unilateral exits.
  ///
  /// Parameters:
  /// - `mnemonic`: BIP39 mnemonic for wallet recovery
  /// - `config`: Wallet configuration
  /// - `datadir`: Directory for wallet database
  /// - `onchainWallet`: Onchain wallet for boarding and exits
  /// - `forceRescan`: Force wallet rescan
  static Future<Wallet> createWithOnchain(
    String mnemonic,
    ffi.Config config,
    String datadir,
    OnchainWallet onchainWallet,
    bool forceRescan,
  ) async {
    // IMPORTANT: This method does NOT run in an isolate because it may invoke
    // callbacks if using a custom onchain wallet. Callbacks cannot cross isolate boundaries.
    try {
      final inner = ffi.Wallet.createWithOnchain(
        mnemonic,
        config,
        datadir,
        onchainWallet.ffi,
        forceRescan,
      );
      return Wallet._(inner);
    } on ffi.BarkException catch (e) {
      assert(() {
        print('BarkException in Wallet.createWithOnchain: ${e.message}');
        return true;
      }());
      rethrow;
    }
  }

  /// Open an existing Bark wallet with onchain capabilities.
  ///
  /// Similar to [open] but also loads unilateral exit state using the
  /// provided onchain wallet.
  ///
  /// Parameters:
  /// - `mnemonic`: BIP39 mnemonic for wallet recovery
  /// - `config`: Wallet configuration
  /// - `datadir`: Directory for wallet database
  /// - `onchainWallet`: Onchain wallet for boarding and exits
  static Future<Wallet> openWithOnchain(
    String mnemonic,
    ffi.Config config,
    String datadir,
    OnchainWallet onchainWallet,
  ) async {
    // IMPORTANT: This method does NOT run in an isolate because it may invoke
    // callbacks if using a custom onchain wallet. Callbacks cannot cross isolate boundaries.
    try {
      final inner = ffi.Wallet.openWithOnchain(
        mnemonic,
        config,
        datadir,
        onchainWallet.ffi,
      );
      return Wallet._(inner);
    } on ffi.BarkException catch (e) {
      assert(() {
        print('BarkException in Wallet.openWithOnchain: ${e.message}');
        return true;
      }());
      rethrow;
    }
  }

  // ------------------------------------------------------------------------
  // Wallet Properties
  // ------------------------------------------------------------------------

  /// Retrieves the read-only properties of the current Bark wallet.
  ///
  /// Returns network and fingerprint information.
  ffi.WalletProperties properties() {
    return _inner.properties();
  }

  // ------------------------------------------------------------------------
  // Synchronization & Maintenance
  // ------------------------------------------------------------------------

  /// Sync offchain wallet and update onchain fees.
  ///
  /// This is a much more lightweight alternative to [maintenance] as it will
  /// not refresh VTXOs or sync the onchain wallet.
  ///
  /// Notes:
  /// - The exit system will not be synced as doing so requires the onchain wallet.
  /// - This method blocks but the FFI layer uses a global Tokio runtime that
  ///   handles async operations internally.
  Future<void> sync() async {
    return Isolate.run(() => _inner.sync_());
  }

  /// Performs maintenance tasks on the offchain wallet.
  ///
  /// This can take a long period of time due to syncing rounds, arkoors,
  /// checking pending payments and refreshing VTXOs if necessary.
  ///
  /// Note: This method blocks but the FFI layer uses a global Tokio runtime
  /// that handles async operations internally.
  Future<void> maintenance() {
    return Isolate.run(() => _inner.maintenance());
  }

  // ------------------------------------------------------------------------
  // Address Generation
  // ------------------------------------------------------------------------

  /// Generate a new Ark address for receiving payments.
  Future<String> newAddress() {
    return Isolate.run(() => _inner.newAddress());
  }

  // ------------------------------------------------------------------------
  // Balance & VTXOs
  // ------------------------------------------------------------------------

  /// Return the balance of the wallet.
  ///
  /// Make sure you sync before calling this method.
  ffi.Balance balance() {
    return _inner.balance();
  }

  /// Returns all not spent VTXOs.
  ///
  /// An Ark wallet contains VTXOs. These are just like normal UTXOs in a
  /// bitcoin wallet. They just haven't been confirmed on chain (yet).
  /// However, the user remains in full control of the funds and can perform
  /// a unilateral exit at any time.
  List<ffi.Vtxo> vtxos() {
    return _inner.vtxos();
  }

  // ------------------------------------------------------------------------
  // Boarding (requires onchain wallet)
  // ------------------------------------------------------------------------

  /// Board a specific amount from onchain wallet into Ark
  ///
  /// Moves Bitcoin from your onchain wallet into Ark, allowing you to use
  /// Ark features like instant payments and Lightning support.
  ///
  /// Parameters:
  /// - `onchainWallet`: The onchain wallet to board from
  /// - `amountSats`: Amount to board in satoshis
  ///
  /// Returns a [ffi.PendingBoard] with the boarding transaction details.
  ///
  /// Note: You must call [syncPendingBoards] after this to complete the boarding.
  ///
  /// IMPORTANT: This method does NOT run in an isolate because it may invoke
  /// callbacks if using a custom onchain wallet. Callbacks cannot cross isolate boundaries.
  Future<ffi.PendingBoard> boardAmount(
    OnchainWallet onchainWallet,
    int amountSats,
  ) async {
    return _inner.boardAmount(onchainWallet.ffi, amountSats);
  }

  /// Board all funds from onchain wallet into Ark
  ///
  /// Moves all available Bitcoin from your onchain wallet into Ark.
  ///
  /// Parameters:
  /// - `onchainWallet`: The onchain wallet to board from
  ///
  /// Returns a [ffi.PendingBoard] with the boarding transaction details.
  ///
  /// Note: You must call [syncPendingBoards] after this to complete the boarding.
  ///
  /// IMPORTANT: This method does NOT run in an isolate because it may invoke
  /// callbacks if using a custom onchain wallet. Callbacks cannot cross isolate boundaries.
  Future<ffi.PendingBoard> boardAll(OnchainWallet onchainWallet) async {
    return _inner.boardAll(onchainWallet.ffi);
  }

  /// Sync pending board transactions
  ///
  /// Checks the status of pending boarding transactions and updates the
  /// wallet state when they are confirmed onchain.
  ///
  /// Call this periodically after boarding to track progress.
  Future<void> syncPendingBoards() async {
    return Isolate.run(() => _inner.syncPendingBoards());
  }

  // ------------------------------------------------------------------------
  // Offboarding
  // ------------------------------------------------------------------------

  /// Offboard all VTXOs to a given Bitcoin address.
  ///
  /// Moves funds from offchain (Ark) back to onchain in a collaborative
  /// exit with the Ark server.
  Future<ffi.OffboardResult> offboardAll(String bitcoinAddress) async {
    return Isolate.run(() => _inner.offboardAll(bitcoinAddress));
  }

  // ------------------------------------------------------------------------
  // Lightning Payments (Send)
  // ------------------------------------------------------------------------

  /// Pays a Lightning invoice using Ark VTXOs.
  ///
  /// This is an out-of-round payment so the same [sendArkoorPayment] rules apply.
  ///
  /// Parameters:
  /// - `invoice`: The BOLT11 invoice string to pay
  /// - `amountSats`: Optional amount override for invoices without amounts
  Future<ffi.LightningSend> payLightningInvoice(
    String invoice, [
    int? amountSats,
  ]) async {
    return Isolate.run(() => _inner.payLightningInvoice(invoice, amountSats));
  }

  /// Same as [payLightningInvoice] but instead it pays a Lightning Address (LNURL).
  ///
  /// Parameters:
  /// - `lightningAddress`: The Lightning Address (e.g., "user@domain.com")
  /// - `amountSats`: Amount to send in satoshis
  /// - `comment`: Optional comment to include with the payment
  Future<ffi.LightningSend> payLightningAddress(
    String lightningAddress,
    int amountSats, [
    String? comment,
  ]) async {
    return Isolate.run(
      () => _inner.payLightningAddress(lightningAddress, amountSats, comment),
    );
  }

  // ------------------------------------------------------------------------
  // Lightning Payments (Receive)
  // ------------------------------------------------------------------------

  /// Create, store and return a BOLT11 invoice for offchain boarding.
  ///
  /// The invoice can be paid by any Lightning Network wallet. Once paid,
  /// the funds will appear in your Ark balance after claiming.
  ///
  /// Parameters:
  /// - `amountSats`: The amount to request in satoshis
  ///
  /// Note: This method blocks but the FFI layer uses a global Tokio runtime
  /// that handles async operations internally.
  Future<ffi.LightningInvoice> bolt11Invoice(int amountSats) async {
    return Isolate.run(() => _inner.bolt11Invoice(amountSats));
  }

  /// Try to claim all pending Lightning receives.
  ///
  /// Processes all pending Lightning invoice payments and attempts to claim
  /// the HTLCs by revealing the preimage to the server.
  ///
  /// Parameters:
  /// - `wait`: Whether to wait for each payment to be received.
  Future<void> tryClaimAllLightningReceives(bool wait) async {
    return Isolate.run(() => _inner.tryClaimAllLightningReceives(wait));
  }

  // ------------------------------------------------------------------------
  // Arkoor Payments
  // ------------------------------------------------------------------------

  /// Send an out-of-round payment to an Ark address.
  ///
  /// Out-of-round (arkoor) payments allow instant transfers between Ark users
  /// without waiting for a round to complete. If the amount doesn't match
  /// existing VTXO amounts exactly, multiple VTXOs will be chained together,
  /// resulting in the recipient receiving multiple VTXOs.
  ///
  /// Note that a change VTXO may be created as a result of this call. With each
  /// payment these will become more uneconomical to unilaterally exit, so you
  /// should eventually refresh them or periodically call [maintenance].
  ///
  /// Parameters:
  /// - `arkAddress`: The recipient's Ark address
  /// - `amountSats`: The amount to send in satoshis
  Future<String> sendArkoorPayment(String arkAddress, int amountSats) async {
    return Isolate.run(() => _inner.sendArkoorPayment(arkAddress, amountSats));
  }

  // ------------------------------------------------------------------------
  // Extended Address Management
  // ------------------------------------------------------------------------

  /// Generate a new address and return it with its derivation index.
  ffi.AddressWithIndex newAddressWithIndex() {
    return _inner.newAddressWithIndex();
  }

  /// Peek at an address at a specific index without incrementing.
  String peakAddress(int index) {
    return _inner.peakAddress(index);
  }

  // ------------------------------------------------------------------------
  // Movement History
  // ------------------------------------------------------------------------

  /// Get all wallet movements (transaction history).
  ///
  /// Returns a list of movements ordered from newest to oldest.
  List<ffi.Movement> history() {
    return _inner.history();
  }

  // ------------------------------------------------------------------------
  // Extended VTXO Queries
  // ------------------------------------------------------------------------

  /// Get a specific VTXO by ID.
  ffi.Vtxo getVtxoById(String vtxoId) {
    return _inner.getVtxoById(vtxoId);
  }

  /// Get all spendable VTXOs.
  List<ffi.Vtxo> spendableVtxos() {
    return _inner.spendableVtxos();
  }

  /// Get all VTXOs (including spent).
  List<ffi.Vtxo> allVtxos() {
    return _inner.allVtxos();
  }

  /// Get VTXOs expiring within threshold blocks.
  ///
  /// Parameters:
  /// - `thresholdBlocks`: Number of blocks before expiry
  Future<List<ffi.Vtxo>> getExpiringVtxos(int thresholdBlocks) async {
    return Isolate.run(() => _inner.getExpiringVtxos(thresholdBlocks));
  }

  /// Get VTXOs that should be refreshed.
  Future<List<ffi.Vtxo>> getVtxosToRefresh() async {
    return Isolate.run(() => _inner.getVtxosToRefresh());
  }

  // ------------------------------------------------------------------------
  // Extended Offboarding
  // ------------------------------------------------------------------------

  /// Offboard specific VTXOs to a Bitcoin address.
  ///
  /// Parameters:
  /// - `vtxoIds`: List of VTXO IDs to offboard
  /// - `bitcoinAddress`: Destination Bitcoin address
  Future<String> offboardVtxos(
    List<String> vtxoIds,
    String bitcoinAddress,
  ) async {
    return Isolate.run(() => _inner.offboardVtxos(vtxoIds, bitcoinAddress));
  }

  // ------------------------------------------------------------------------
  // Unilateral Exits (requires onchain wallet)
  // ------------------------------------------------------------------------

  /// Start unilateral exit for the entire wallet
  ///
  /// Initiates a trustless exit from Ark without requiring server cooperation.
  /// This broadcasts exit transactions to the Bitcoin network, allowing you
  /// to recover your funds even if the Ark server is offline or uncooperative.
  ///
  /// Parameters:
  /// - `onchainWallet`: The onchain wallet to receive the exited funds
  ///
  /// Note: You must call [syncExits] after this to track the exit progress.
  ///
  /// Note: Requires an onchain wallet to have been configured when creating/opening
  /// the wallet for the exit to succeed.
  Future<void> startExitForEntireWallet() async {
    return _inner.startExitForEntireWallet();
  }

  /// Sync exit state
  ///
  /// Updates the status of pending unilateral exits by checking the blockchain.
  /// Call this periodically after starting an exit to track progress and
  /// complete the exit process.
  ///
  /// This does NOT progress exits (broadcast, fee bump, etc.). Use [progressExits] for that.
  ///
  /// Parameters:
  /// - `onchainWallet`: The onchain wallet used for the exit
  ///
  /// IMPORTANT: This method does NOT run in an isolate because it may invoke
  /// callbacks if using a custom onchain wallet. Callbacks cannot cross isolate boundaries.
  Future<void> syncExits(OnchainWallet onchainWallet) async {
    return _inner.syncExits(onchainWallet.ffi);
  }

  // ------------------------------------------------------------------------
  // Extended Exit Methods
  // ------------------------------------------------------------------------

  /// Get detailed exit status for a specific VTXO
  ///
  /// Parameters:
  /// - `vtxoId`: The VTXO ID to check
  /// - `includeHistory`: Include state transition history
  /// - `includeTransactions`: Include transaction details
  ///
  /// Returns detailed exit status or null if VTXO is not in exit
  Future<ffi.ExitTransactionStatus?> getExitStatus(
    String vtxoId,
    bool includeHistory,
    bool includeTransactions,
  ) async {
    return Isolate.run(
      () => _inner.getExitStatus(vtxoId, includeHistory, includeTransactions),
    );
  }

  /// Progress unilateral exits (broadcast, fee bump, advance state machine)
  ///
  /// This is THE CRITICAL METHOD for actually moving exits forward!
  /// It will:
  /// - Broadcast exit transactions to the Bitcoin network
  /// - Perform CPFP fee bumping when needed
  /// - Advance the exit state machine until exits become claimable
  ///
  /// Call this periodically after starting exits.
  ///
  /// Parameters:
  /// - `onchainWallet`: Onchain wallet for building exit transactions
  /// - `feeRateSatPerVb`: Optional fee rate override in sats per vbyte
  ///
  /// Returns a list of exit progress statuses
  ///
  /// IMPORTANT: This method does NOT run in an isolate because it may invoke
  /// callbacks if using a custom onchain wallet. Callbacks cannot cross isolate boundaries.
  Future<List<ffi.ExitProgressStatus>> progressExits(
    OnchainWallet onchainWallet, [
    int? feeRateSatPerVb,
  ]) async {
    return _inner.progressExits(onchainWallet.ffi, feeRateSatPerVb);
  }

  /// Start unilateral exit for specific VTXOs
  ///
  /// Initiates the emergency exit process for the specified VTXOs.
  /// You must call [progressExits] periodically to actually advance the exit.
  ///
  /// Parameters:
  /// - `vtxoIds`: List of VTXO IDs to exit
  Future<void> startExitForVtxos(List<String> vtxoIds) async {
    return _inner.startExitForVtxos(vtxoIds);
  }

  /// List all exits that are claimable
  ///
  /// Returns all exits ready to be drained to an onchain wallet.
  List<ffi.ExitVtxo> listClaimableExits() {
    return _inner.listClaimableExits();
  }

  /// Get all VTXOs currently in the exit process
  List<ffi.ExitVtxo> getExitVtxos() {
    return _inner.getExitVtxos();
  }

  /// Check if there are any pending exits
  bool hasPendingExits() {
    return _inner.hasPendingExits();
  }

  /// Get total amount in pending exits (in satoshis)
  int pendingExitsTotalSats() {
    return _inner.pendingExitsTotalSats();
  }

  /// Get earliest block height when all exits will be claimable
  ///
  /// Returns null if no exits are tracked or if any exit has undetermined claimability.
  int? allExitsClaimableAtHeight() {
    return _inner.allExitsClaimableAtHeight();
  }

  /// Drain claimable exits to an address
  ///
  /// Builds a signed PSBT that claims exited funds and sends them to the specified address.
  /// The PSBT can be broadcast directly or modified before broadcasting.
  ///
  /// Parameters:
  /// - `vtxoIds`: List of claimable VTXO IDs to drain (empty list = drain all claimable)
  /// - `address`: Bitcoin address to send claimed funds to
  /// - `feeRateSatPerVb`: Optional fee rate override in sats per vbyte
  ///
  /// Returns a signed exit claim transaction with PSBT and fee information
  Future<ffi.ExitClaimTransaction> drainExits(
    List<String> vtxoIds,
    String address, [
    int? feeRateSatPerVb,
  ]) async {
    return Isolate.run(
      () => _inner.drainExits(vtxoIds, address, feeRateSatPerVb),
    );
  }

  // ------------------------------------------------------------------------
  // Round Management
  // ------------------------------------------------------------------------

  /// Get all pending round states
  List<ffi.RoundState> pendingRoundStates() {
    return _inner.pendingRoundStates();
  }

  /// Cancel a specific pending round
  ///
  /// Parameters:
  /// - `roundId`: The ID of the round to cancel
  Future<void> cancelPendingRound(int roundId) async {
    return Isolate.run(() => _inner.cancelPendingRound(roundId));
  }

  /// Cancel all pending rounds
  Future<void> cancelAllPendingRounds() async {
    return Isolate.run(() => _inner.cancelAllPendingRounds());
  }

  /// Progress pending rounds
  ///
  /// Advances the state of all pending rounds. Call this periodically.
  Future<void> progressPendingRounds() async {
    return Isolate.run(() => _inner.progressPendingRounds());
  }

  // ------------------------------------------------------------------------
  // Extended Maintenance & Validation
  // ------------------------------------------------------------------------

  /// Refresh the Ark server connection
  ///
  /// Re-establishes connection to the Ark server if it was lost.
  Future<void> refreshServer() async {
    return Isolate.run(() => _inner.refreshServer());
  }

  /// Validate an Ark address against the connected server
  ///
  /// This performs full validation including checking if the address
  /// belongs to the currently connected Ark server.
  ///
  /// For basic format validation only, use the standalone `validateArkAddress()` function.
  ///
  /// Parameters:
  /// - `address`: The Ark address to validate
  Future<bool> validateArkoorAddress(String address) async {
    return Isolate.run(() => _inner.validateArkoorAddress(address));
  }

  /// Full maintenance including onchain wallet sync
  ///
  /// More thorough than [maintenance] - also syncs the onchain wallet and exit system.
  ///
  /// Parameters:
  /// - `onchainWallet`: The onchain wallet to sync
  ///
  /// IMPORTANT: This method does NOT run in an isolate because it may invoke
  /// callbacks if using a custom onchain wallet. Callbacks cannot cross isolate boundaries.
  Future<void> maintenanceWithOnchain(OnchainWallet onchainWallet) async {
    return _inner.maintenanceWithOnchain(onchainWallet.ffi);
  }

  // ------------------------------------------------------------------------
  // VTXO Refresh
  // ------------------------------------------------------------------------

  /// Refresh specific VTXOs.
  ///
  /// Parameters:
  /// - `vtxoIds`: List of VTXO IDs to refresh
  ///
  /// Returns the round status if refresh occurred, null otherwise.
  Future<String?> refreshVtxos(List<String> vtxoIds) async {
    return Isolate.run(() => _inner.refreshVtxos(vtxoIds));
  }

  /// Perform automatic maintenance refresh.
  ///
  /// Returns the round status if refresh occurred, null otherwise.
  Future<String?> maintenanceRefresh() async {
    return Isolate.run(() => _inner.maintenanceRefresh());
  }

  /// Get the block height of the first expiring VTXO
  ///
  /// Returns the block height when the first VTXO will expire, or null if no VTXOs.
  Future<int?> getFirstExpiringVtxoBlockheight() async {
    return Isolate.run(() => _inner.getFirstExpiringVtxoBlockheight());
  }

  /// Get the next required refresh block height
  ///
  /// Returns the block height when a refresh should be performed, or null if no refresh needed.
  Future<int?> getNextRequiredRefreshBlockheight() async {
    return Isolate.run(() => _inner.getNextRequiredRefreshBlockheight());
  }

  /// Schedule maintenance refresh if needed
  ///
  /// Determines if a maintenance refresh should be scheduled and returns the target round ID.
  ///
  /// Returns the round ID if refresh was scheduled, null otherwise.
  Future<int?> maybeScheduleMaintenanceRefresh() async {
    return Isolate.run(() => _inner.maybeScheduleMaintenanceRefresh());
  }

  // ------------------------------------------------------------------------
  // Extended Lightning
  // ------------------------------------------------------------------------

  /// Pay a BOLT12 Lightning offer
  ///
  /// Parameters:
  /// - `offer`: BOLT12 offer string
  /// - `amountSats`: Optional amount override for offers without amounts
  Future<ffi.LightningSend> payLightningOffer(
    String offer, [
    int? amountSats,
  ]) async {
    return Isolate.run(() => _inner.payLightningOffer(offer, amountSats));
  }

  /// Check the status of a Lightning payment by payment hash
  ///
  /// Parameters:
  /// - `paymentHash`: The payment hash as hex string
  /// - `wait`: Whether to wait for the payment to complete
  ///
  /// Returns the preimage as hex string if payment succeeded, null otherwise
  Future<String?> checkLightningPayment(
    String paymentHash,
    bool wait,
  ) async {
    return Isolate.run(
      () => _inner.checkLightningPayment(paymentHash, wait),
    );
  }

  /// Get status of a specific Lightning receive by payment hash
  ///
  /// Parameters:
  /// - `paymentHash`: The payment hash as hex string
  ///
  /// Returns the receive status or null if not found
  Future<ffi.LightningReceive?> lightningReceiveStatus(
    String paymentHash,
  ) async {
    return Isolate.run(() => _inner.lightningReceiveStatus(paymentHash));
  }

  /// Try to claim a specific Lightning receive by payment hash
  ///
  /// Parameters:
  /// - `paymentHash`: The payment hash as hex string
  /// - `wait`: Whether to wait for the payment to be received
  Future<void> tryClaimLightningReceive(
    String paymentHash,
    bool wait,
  ) async {
    return Isolate.run(
      () => _inner.tryClaimLightningReceive(paymentHash, wait),
    );
  }

  /// Get all pending lightning sends.
  List<ffi.LightningSend> pendingLightningSends() {
    return _inner.pendingLightningSends();
  }

  /// Get all pending lightning receives.
  List<ffi.LightningReceive> pendingLightningReceives() {
    return _inner.pendingLightningReceives();
  }

  /// Get claimable lightning receive balance in satoshis.
  int claimableLightningReceiveBalanceSats() {
    return _inner.claimableLightningReceiveBalanceSats();
  }

  // ------------------------------------------------------------------------
  // Onchain Payments
  // ------------------------------------------------------------------------

  /// Send an onchain payment during a round.
  ///
  /// Parameters:
  /// - `address`: Bitcoin address to send to
  /// - `amountSats`: Amount in satoshis
  Future<String> sendRoundOnchainPayment(String address, int amountSats) async {
    return Isolate.run(
      () => _inner.sendRoundOnchainPayment(address, amountSats),
    );
  }

  // ------------------------------------------------------------------------
  // Connection & Info
  // ------------------------------------------------------------------------

  /// Get Ark server info (null if not connected).
  ffi.ArkInfo? arkInfo() {
    return _inner.arkInfo();
  }

  /// Get wallet config.
  ffi.Config config() {
    return _inner.config();
  }

  // ------------------------------------------------------------------------
  // Advanced Methods
  // ------------------------------------------------------------------------

  /// Sign exit claim inputs in a PSBT
  ///
  /// Used for external PSBT workflows where you need to sign the exit claim inputs
  /// without broadcasting immediately.
  ///
  /// Parameters:
  /// - `psbtBase64`: Base64-encoded PSBT to sign
  ///
  /// Returns the signed PSBT as base64 string
  Future<String> signExitClaimInputs(String psbtBase64) async {
    return Isolate.run(() => _inner.signExitClaimInputs(psbtBase64));
  }

  // ------------------------------------------------------------------------
  // Transaction Broadcasting
  // ------------------------------------------------------------------------

  /// Broadcast a signed transaction to the Bitcoin network
  ///
  /// Takes a hex-encoded transaction and broadcasts it via the wallet's chain source.
  /// This is useful after extracting a transaction from a PSBT using
  /// [BarkUtils.extractTxFromPsbt].
  ///
  /// Parameters:
  /// - `txHex`: Hex-encoded signed transaction
  ///
  /// Example:
  /// ```dart
  /// final exitClaim = await wallet.drainExits(vtxoIds, address, null);
  /// final txHex = BarkUtils.extractTxFromPsbt(exitClaim.psbtBase64);
  /// final txid = await wallet.broadcastTx(txHex);
  /// ```
  ///
  /// Returns the transaction ID (txid) of the broadcasted transaction.
  ///
  /// Throws [BarkException] if the transaction is invalid or broadcast fails.
  Future<String> broadcastTx(String txHex) async {
    return Isolate.run(() => _inner.broadcastTx(txHex));
  }
}
