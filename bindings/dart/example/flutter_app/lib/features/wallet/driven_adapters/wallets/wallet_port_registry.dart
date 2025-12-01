import 'package:flutter_app/features/wallet/application/ports/wallet_port.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/wallet_type_vo.dart';
import 'package:flutter_app/features/wallet/driven_adapters/wallets/bark_wallet.dart';

class WalletPortRegistry {
  final Map<WalletTypeVO, WalletPort> _ports;

  WalletPortRegistry({required BarkWallet barkwallet})
    : _ports = {WalletTypeVO.bark: barkwallet};

  WalletPort getPort(WalletTypeVO type) {
    return _ports[type]!;
  }
}
