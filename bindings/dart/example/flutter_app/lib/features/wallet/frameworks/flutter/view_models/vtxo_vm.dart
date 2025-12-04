import 'package:equatable/equatable.dart';

/// VTXO view model for UI display
// TODO: abstract to a base class named Coins with subtypes for different types of coins like VTXOs, UTXOs, etc.
class VtxoVM extends Equatable {
  final String id;
  final int amountSats;
  final int expiryHeight;
  final String kind;
  final String state;

  const VtxoVM({
    required this.id,
    required this.amountSats,
    required this.expiryHeight,
    required this.kind,
    required this.state,
  });

  String get amountBtc => (amountSats / 100000000).toStringAsFixed(8);

  @override
  List<Object> get props => [id, amountSats, expiryHeight, kind, state];
}
