import 'package:equatable/equatable.dart';

/// Value object representing supported Bitcoin networks
class BitcoinNetworkVO extends Equatable {
  final String value;

  const BitcoinNetworkVO._(this.value);

  static const BitcoinNetworkVO mainnet = BitcoinNetworkVO._('mainnet');
  static const BitcoinNetworkVO testnet3 = BitcoinNetworkVO._('testnet3');
  static const BitcoinNetworkVO testnet4 = BitcoinNetworkVO._('testnet4');
  static const BitcoinNetworkVO signet = BitcoinNetworkVO._('signet');

  /// All supported networks
  static const List<BitcoinNetworkVO> all = [
    mainnet,
    testnet3,
    testnet4,
    signet,
  ];

  /// Create from string value
  /// Returns null if invalid network
  static BitcoinNetworkVO? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'mainnet':
        return mainnet;
      case 'testnet3':
        return testnet3;
      case 'testnet4':
        return testnet4;
      case 'signet':
        return signet;
      default:
        return null;
    }
  }

  /// Check if string is valid network
  static bool isValid(String value) {
    return fromString(value) != null;
  }

  @override
  String toString() => value;

  @override
  List<Object> get props => [value];
}
