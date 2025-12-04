import 'package:bark/src/generated/bark.dart' as ffi;

/// Utility functions for Bark wallet operations.
class BarkUtils {
  /// Generate a new 12-word BIP39 mnemonic.
  ///
  /// Returns a mnemonic phrase that can be used to create or restore a wallet.
  static String generateMnemonic() {
    return ffi.generateMnemonic();
  }

  /// Validate a BIP39 mnemonic phrase.
  ///
  /// Parameters:
  /// - `mnemonic`: The mnemonic phrase to validate
  ///
  /// Returns `true` if the mnemonic is valid, `false` otherwise.
  static bool validateMnemonic(String mnemonic) {
    return ffi.validateMnemonic(mnemonic);
  }

  /// Validate an Ark address.
  ///
  /// Parameters:
  /// - `address`: The Ark address to validate
  ///
  /// Returns `true` if the address is valid, `false` otherwise.
  static bool validateArkAddress(String address) {
    return ffi.validateArkAddress(address);
  }
}
