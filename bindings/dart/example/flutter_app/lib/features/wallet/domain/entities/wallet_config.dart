/// Base class for wallet configuration
/// Part of the WalletEntity aggregate
sealed class WalletConfig {
  const WalletConfig();
}

/// Bark wallet configuration
/// Mutable fields that are part of the WalletEntity aggregate
class BarkWalletConfig extends WalletConfig {
  final String _fingerprint;
  final String _dbPath;
  String _asp;
  int? _vtxoRefreshExpiryThreshold;
  int? _vtxoExitMargin;
  int? _htlcRecvClaimDelta;

  // Runtime fields - not persisted, loaded on demand
  String? _mnemonic;
  List<String>? _esploraAddresses;

  BarkWalletConfig({
    required String fingerprint,
    required String dbPath,
    required String asp,
    int? vtxoRefreshExpiryThreshold,
    int? vtxoExitMargin,
    int? htlcRecvClaimDelta,
  }) : _fingerprint = fingerprint,
       _dbPath = dbPath,
       _asp = asp,
       _vtxoRefreshExpiryThreshold = vtxoRefreshExpiryThreshold,
       _vtxoExitMargin = vtxoExitMargin,
       _htlcRecvClaimDelta = htlcRecvClaimDelta;

  String get fingerprint => _fingerprint;
  String get dbPath => _dbPath;
  String get asp => _asp;
  int? get vtxoRefreshExpiryThreshold => _vtxoRefreshExpiryThreshold;
  int? get vtxoExitMargin => _vtxoExitMargin;
  int? get htlcRecvClaimDelta => _htlcRecvClaimDelta;
  String? get mnemonic => _mnemonic;
  List<String>? get esploraAddresses => _esploraAddresses;

  // Note: ASP is part of identity, so updating it effectively creates a different wallet
  // This method exists for flexibility but should be used with caution
  void updateAsp(String newAsp) {
    _asp = newAsp;
  }

  void updateVtxoRefreshExpiryThreshold(int? threshold) {
    _vtxoRefreshExpiryThreshold = threshold;
  }

  void updateVtxoExitMargin(int? margin) {
    _vtxoExitMargin = margin;
  }

  void updateHtlcRecvClaimDelta(int? delta) {
    _htlcRecvClaimDelta = delta;
  }

  void setMnemonic(String mnemonic) {
    _mnemonic = mnemonic;
  }

  void setEsploraAddresses(List<String> esploraAddresses) {
    _esploraAddresses = esploraAddresses;
  }

  /// Config instances are identified by fingerprint + ASP combination
  /// (same key can be used with different ASP servers)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarkWalletConfig &&
          runtimeType == other.runtimeType &&
          fingerprint == other.fingerprint &&
          asp == other.asp;

  @override
  int get hashCode => Object.hash(fingerprint, asp);
}
