/// Base class for wallet configurations
sealed class WalletConfigEntity {
  final int _walletId;
  final String _network;

  // Runtime fields - not persisted, loaded on demand
  // Assuming all wallet types (bark, bdk, ldk, etc.) will all use esplora
  //  for on-chain data
  List<String>? _esploraAddresses;

  WalletConfigEntity({required int walletId, required String network})
    : _walletId = walletId,
      _network = network;

  int get walletId => _walletId;
  String get network => _network;
  List<String>? get esploraAddresses => _esploraAddresses;

  void setEsploraAddresses(List<String> esploraAddresses) {
    _esploraAddresses = esploraAddresses;
  }
}

/// Bark wallet configuration
class BarkWalletConfigEntity extends WalletConfigEntity {
  final String _fingerprint;
  final String _dbPath;
  String _asp;
  int? _vtxoRefreshExpiryThreshold;
  int? _vtxoExitMargin;
  int? _htlcRecvClaimDelta;

  BarkWalletConfigEntity({
    required super.walletId,
    required super.network,
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
}
