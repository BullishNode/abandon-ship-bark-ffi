import 'package:equatable/equatable.dart';

/// Wallet type value object
class WalletTypeVO extends Equatable {
  final String value;

  const WalletTypeVO._(this.value);

  static const WalletTypeVO bark = WalletTypeVO._('bark');

  static const List<WalletTypeVO> all = [bark];

  static WalletTypeVO fromString(String value) {
    final type = all.where((type) => type.value == value).firstOrNull;
    if (type == null) {
      throw Exception("Invalid wallet type");
    }
    return type;
  }

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
}
