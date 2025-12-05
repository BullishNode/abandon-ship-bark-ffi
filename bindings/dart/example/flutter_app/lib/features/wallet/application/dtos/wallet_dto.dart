class WalletDto {
  final int id;
  String name;
  final String network;
  String? description;

  WalletDto({
    required this.id,
    required this.name,
    required this.network,
    this.description,
  });
}
