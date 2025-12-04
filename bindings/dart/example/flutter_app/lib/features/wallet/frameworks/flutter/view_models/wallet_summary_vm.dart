import 'package:equatable/equatable.dart';

/// Wallet summary view model for UI display
class WalletSummaryVM extends Equatable {
  final int id;
  final String name;
  final String network;
  final DateTime createdAt;

  const WalletSummaryVM({
    required this.id,
    required this.name,
    required this.network,
    required this.createdAt,
  });

  @override
  List<Object> get props => [id, name, network, createdAt];
}
