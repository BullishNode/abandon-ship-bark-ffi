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

  /// Extract a signed transaction from a PSBT.
  ///
  /// Takes a base64-encoded PSBT and extracts the final signed transaction.
  /// This is useful after signing a PSBT (e.g., from drainExits) before broadcasting.
  ///
  /// Parameters:
  /// - `psbtBase64`: Base64-encoded PSBT string
  ///
  /// Returns hex-encoded signed transaction ready for broadcasting.
  ///
  /// Throws [BarkException] if the PSBT is invalid or extraction fails.
  static String extractTxFromPsbt(String psbtBase64) {
    return ffi.extractTxFromPsbt(psbtBase64);
  }
}
