/// Port for secure seed/mnemonic storage
/// Abstracts the underlying secure storage mechanism
abstract class MnemonicRepositoryPort {
  /// Generate a new mnemonic phrase
  Future<String> generateMnemonic();

  /// Store mnemonic securely using fingerprint as key
  Future<void> storeMnemonic({
    required String fingerprint,
    required String mnemonic,
  });

  /// Retrieve mnemonic by fingerprint
  /// Returns null if not found
  Future<String?> getMnemonic(String fingerprint);

  /// Delete mnemonic by fingerprint
  Future<void> deleteMnemonic(String fingerprint);

  /// Check if mnemonic exists for fingerprint
  Future<bool> hasMnemonic(String fingerprint);
}
