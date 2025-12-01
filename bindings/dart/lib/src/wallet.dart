import 'dart:isolate';
import 'package:bark/src/generated/bark_ffi.dart' as ffi;
import 'package:bark/src/errors.dart';

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
  String newAddress() {
    return _inner.newAddress();
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
  Future<void> sendArkoorPayment(String arkAddress, int amountSats) async {
    return Isolate.run(() => _inner.sendArkoorPayment(arkAddress, amountSats));
  }
}
