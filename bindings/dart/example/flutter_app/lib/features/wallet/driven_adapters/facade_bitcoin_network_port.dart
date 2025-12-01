import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/features/settings/driving_adapters/facades/bitcoin_network_facade.dart';
import 'package:flutter_app/features/wallet/application/ports/bitcoin_network_port.dart';

/// Adapter implementing BitcoinNetworkPort using BitcoinNetworkFacade
/// Anti-corruption layer between wallet and settings features
class FacadeBitcoinNetworkPort implements BitcoinNetworkPort {
  final BitcoinNetworkFacade _facade;

  FacadeBitcoinNetworkPort(this._facade);

  @override
  Future<Either<Failure, String>> getCurrentNetwork() async {
    final result = await _facade.getCurrentNetwork();
    return result.map((response) => response);
  }

  @override
  Future<Either<Failure, bool>> isValidNetwork(String network) async {
    return await _facade.isValidNetwork(network);
  }
}
