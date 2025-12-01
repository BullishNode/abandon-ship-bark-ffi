import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/features/esplora_settings/application/usecases/get_esplora_endpoint_for_network.dart';

/// Facade exposing esplora_settings functionality to other features
/// Other features depend on this facade, not on internal use cases
class EsploraEndpointFacade {
  final GetEsploraEndpointForNetwork _getEsploraEndpointForNetwork;

  EsploraEndpointFacade(this._getEsploraEndpointForNetwork);

  /// Get Esplora endpoint for the given network
  /// Returns default endpoint if none is configured
  Future<Either<Failure, EsploraEndpointResponse>> getEndpointForNetwork(
    String network,
  ) async {
    return await _getEsploraEndpointForNetwork(
      GetEsploraEndpointForNetworkQuery(network: network),
    );
  }
}
