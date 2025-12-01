class BarkWalletDto {
  final int id;
  String name;
  final String network;
  String? description;
  final String fingerprint;
  final String asp;
  final int? vtxoRefreshExpiryThreshold;
  final int? vtxoExitMargin;
  final int? htlcRecvClaimDelta;

  BarkWalletDto({
    required this.id,
    required this.name,
    required this.network,
    this.description,
    required this.fingerprint,
    required this.asp,
    this.vtxoRefreshExpiryThreshold,
    this.vtxoExitMargin,
    this.htlcRecvClaimDelta,
  });
}
