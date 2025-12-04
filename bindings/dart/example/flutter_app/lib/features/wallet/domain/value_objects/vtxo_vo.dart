import 'package:equatable/equatable.dart';

/// VTXO (Virtual Transaction Output) value object
/// TODO: abstract to a base class named Coins with subtypes for different types of coins like VTXOs, UTXOs, etc.
class VtxoVO extends Equatable {
  final String id;
  final int amountSats;
  final int expiryHeight;
  final String kind;
  final String state;

  const VtxoVO({
    required this.id,
    required this.amountSats,
    required this.expiryHeight,
    required this.kind,
    required this.state,
  });

  @override
  List<Object> get props => [id, amountSats, expiryHeight, kind, state];
}
