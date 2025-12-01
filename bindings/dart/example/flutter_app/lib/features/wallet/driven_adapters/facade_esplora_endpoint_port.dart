import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/features/esplora_settings/driving_adapters/facades/esplora_endpoint_facade.dart';
import 'package:flutter_app/features/wallet/application/ports/esplora_endpoint_port.dart';

/// Adapter implementing EsploraEndpointPort using EsploraEndpointFacade
/// Anti-corruption layer: prevents wallet feature from coupling to esplora_settings internals
class FacadeEsploraEndpointPort implements EsploraEndpointPort {
  final EsploraEndpointFacade _facade;

  FacadeEsploraEndpointPort(this._facade);

  @override
  Future<Either<Failure, String>> getEndpointUrlForNetwork(
    String network,
  ) async {
    final result = await _facade.getEndpointForNetwork(network);
    return result.map((response) => response.baseUrl);
  }
}
