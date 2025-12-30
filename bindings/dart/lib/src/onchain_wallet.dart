import 'dart:isolate';
import 'generated/bark.dart' as generated;

/// Onchain Bitcoin wallet for boarding and exits
///
/// Provides two implementations:
/// - Default BDK-based wallet (recommended for most use cases)
/// - Custom callback-based wallet (for advanced use cases with existing wallet infrastructure)
class OnchainWallet {
  final generated.OnchainWallet _inner;

  OnchainWallet._(this._inner);

  /// Create or load an onchain wallet using the default BDK implementation
  ///
  /// This is the recommended approach for most use cases. The wallet is created
  /// or loaded from persistent storage using the provided mnemonic.
  ///
  /// # Arguments
  ///
  /// * `mnemonic` - BIP39 mnemonic phrase (12 or 24 words)
  /// * `config` - Wallet configuration (network, chain source, etc.)
  /// * `datadir` - Directory for wallet data (shares database with Bark wallet)
  ///
  /// # Example
  ///
  /// ```dart
  /// final onchain = OnchainWallet.default(
  ///   'word1 word2 ... word12',
  ///   config,
  ///   '/path/to/datadir',
  /// );
  /// ```
  factory OnchainWallet.default_(
    String mnemonic,
    generated.Config config,
    String datadir,
  ) {
    return OnchainWallet._(
      generated.OnchainWallet.default_(mnemonic, config, datadir),
    );
  }

  /// Create an onchain wallet using custom callback implementation
  ///
  /// Use this when you have an existing wallet implementation and want to integrate
  /// it with Bark for boarding and exits. Your custom implementation must handle
  /// all wallet operations (balance, transactions, signing, etc.).
  ///
  /// # Arguments
  ///
  /// * `callbacks` - Your implementation of [generated.CustomOnchainWalletCallbacks]
  ///
  /// # Example
  ///
  /// ```dart
  /// class MyWallet implements generated.CustomOnchainWalletCallbacks {
  ///   @override
  ///   int getBalance() { ... }
  ///
  ///   @override
  ///   String prepareTx(List<generated.Destination> destinations, int feeRateSatPerVb) { ... }
  ///
  ///   // Implement all other required methods...
  /// }
  ///
  /// final onchain = OnchainWallet.custom(MyWallet());
  /// ```
  factory OnchainWallet.custom(
    generated.CustomOnchainWalletCallbacks callbacks,
  ) {
    return OnchainWallet._(generated.OnchainWallet.custom(callbacks));
  }

  /// Sync the onchain wallet with the blockchain
  ///
  /// Runs in a background isolate to avoid blocking the main thread.
  ///
  /// # Returns
  ///
  /// The number of satoshis synced
  Future<int> sync() async {
    return await Isolate.run(() => _inner.sync_());
  }

  /// Get the current wallet balance
  ///
  /// # Returns
  ///
  /// [generated.OnchainBalance] with confirmed, unconfirmed, and total amounts
  generated.OnchainBalance balance() {
    return _inner.balance();
  }

  /// Generate a new receiving address
  ///
  /// Runs in a background isolate to avoid blocking the main thread.
  ///
  /// # Returns
  ///
  /// A new Bitcoin address as a string
  Future<String> newAddress() async {
    return await Isolate.run(() => _inner.newAddress());
  }

  /// Send Bitcoin to an address
  ///
  /// Runs in a background isolate to avoid blocking the main thread.
  ///
  /// # Arguments
  ///
  /// * `address` - Destination Bitcoin address
  /// * `amountSats` - Amount to send in satoshis
  /// * `feeRateSatPerVb` - Fee rate in satoshis per virtual byte
  ///
  /// # Returns
  ///
  /// Transaction ID (txid) as a hex string
  Future<String> send(
    String address,
    int amountSats,
    int feeRateSatPerVb,
  ) async {
    return await Isolate.run(
      () => _inner.send(address, amountSats, feeRateSatPerVb),
    );
  }

  /// Get the underlying FFI object
  ///
  /// This is used internally by the Bark wallet for boarding and exit operations.
  /// You typically don't need to use this directly.
  generated.OnchainWallet get ffi => _inner;
}
