import 'package:equatable/equatable.dart';

/// VTXO (Virtual Transaction Output) value object
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

  /// Amount in BTC
  String get amountBtc => (amountSats / 100000000).toStringAsFixed(8);

  @override
  List<Object> get props => [id, amountSats, expiryHeight, kind, state];
}
