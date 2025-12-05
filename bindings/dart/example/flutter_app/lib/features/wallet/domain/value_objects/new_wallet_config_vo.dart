/// Base class for a new wallet configuration
sealed class NewWalletConfigVO {
  final int _walletId;
  final String _network;

  const NewWalletConfigVO({required int walletId, required String network})
    : _walletId = walletId,
      _network = network;

  int get walletId => _walletId;
  String get network => _network;
}

/// Bark wallet configuration for new wallet creation
class NewBarkWalletConfigVO extends NewWalletConfigVO {
  final String _asp;
  final List<String> _esploraAddresses;
  final int? _vtxoRefreshExpiryThreshold;
  final int? _vtxoExitMargin;
  final int? _htlcRecvClaimDelta;

  NewBarkWalletConfigVO({
    required super.walletId,
    required super.network,
    required String asp,
    required List<String> esploraAddresses,
    int? vtxoRefreshExpiryThreshold,
    int? vtxoExitMargin,
    int? htlcRecvClaimDelta,
  }) : _asp = asp,
       _esploraAddresses = esploraAddresses,
       _vtxoRefreshExpiryThreshold = vtxoRefreshExpiryThreshold,
       _vtxoExitMargin = vtxoExitMargin,
       _htlcRecvClaimDelta = htlcRecvClaimDelta;

  String get asp => _asp;
  List<String> get esploraAddresses => _esploraAddresses;
  int? get vtxoRefreshExpiryThreshold => _vtxoRefreshExpiryThreshold;
  int? get vtxoExitMargin => _vtxoExitMargin;
  int? get htlcRecvClaimDelta => _htlcRecvClaimDelta;
}
