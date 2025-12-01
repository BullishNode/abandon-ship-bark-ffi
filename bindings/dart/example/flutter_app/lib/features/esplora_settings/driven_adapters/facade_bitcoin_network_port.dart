import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/features/esplora_settings/application/ports/bitcoin_network_port.dart';
import 'package:flutter_app/features/settings/driving_adapters/facades/bitcoin_network_facade.dart';

/// Adapter implementing BitcoinNetworkPort using BitcoinNetworkFacade
/// Allows esplora settings to validate networks through the settings feature
class FacadeBitcoinNetworkPort implements BitcoinNetworkPort {
  final BitcoinNetworkFacade _facade;

  FacadeBitcoinNetworkPort(this._facade);

  @override
  Future<Either<Failure, bool>> isValidNetwork(String network) async {
    return await _facade.isValidNetwork(network);
  }
}
