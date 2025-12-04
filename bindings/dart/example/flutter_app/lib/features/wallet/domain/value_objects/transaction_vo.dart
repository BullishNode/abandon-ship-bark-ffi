import 'package:equatable/equatable.dart';

/// Transaction value object
/// TODO: abstract to a base class with subtypes for different types of transactions
class TransactionVO extends Equatable {
  final int id;
  final String status;
  final String subsystemName;
  final String subsystemKind;
  final int intendedBalanceSats;
  final int effectiveBalanceSats;
  final int offchainFeeSats;
  final String createdAt;
  final String? completedAt;

  const TransactionVO({
    required this.id,
    required this.status,
    required this.subsystemName,
    required this.subsystemKind,
    required this.intendedBalanceSats,
    required this.effectiveBalanceSats,
    required this.offchainFeeSats,
    required this.createdAt,
    this.completedAt,
  });

  /// Intended balance in BTC
  String get intendedBalanceBtc =>
      (intendedBalanceSats / 100000000).toStringAsFixed(8);

  /// Effective balance in BTC
  String get effectiveBalanceBtc =>
      (effectiveBalanceSats / 100000000).toStringAsFixed(8);

  @override
  List<Object?> get props => [
    id,
    status,
    subsystemName,
    subsystemKind,
    intendedBalanceSats,
    effectiveBalanceSats,
    offchainFeeSats,
    createdAt,
    completedAt,
  ];
}
