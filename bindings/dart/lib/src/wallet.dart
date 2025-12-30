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
  Future<ffi.PendingBoard> boardAmount(
    OnchainWallet onchainWallet,
    int amountSats,
  ) async {
    return Isolate.run(
      () => _inner.boardAmount(onchainWallet.ffi, amountSats),
    );
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
  Future<ffi.PendingBoard> boardAll(OnchainWallet onchainWallet) async {
    return Isolate.run(() => _inner.boardAll(onchainWallet.ffi));
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
  Future<ffi.LightningPaymentResult> payLightningInvoice(
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
  Future<ffi.LightningPaymentResult> payLightningAddress(
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
  List<ffi.Movement> movements() {
    return _inner.movements();
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
  Future<void> startExitForEntireWallet(OnchainWallet onchainWallet) async {
    return Isolate.run(
      () => _inner.startExitForEntireWallet(onchainWallet.ffi),
    );
  }

  /// Sync exit state
  ///
  /// Updates the status of pending unilateral exits by checking the blockchain.
  /// Call this periodically after starting an exit to track progress and
  /// complete the exit process.
  ///
  /// Parameters:
  /// - `onchainWallet`: The onchain wallet used for the exit
  Future<void> syncExits(OnchainWallet onchainWallet) async {
    return Isolate.run(() => _inner.syncExits(onchainWallet.ffi));
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

  // ------------------------------------------------------------------------
  // Extended Lightning
  // ------------------------------------------------------------------------

  /// Get all pending lightning sends.
  List<ffi.LightningSendStatus> pendingLightningSends() {
    return _inner.pendingLightningSends();
  }

  /// Get all pending lightning receives.
  List<ffi.LightningReceiveStatus> pendingLightningReceives() {
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
}
