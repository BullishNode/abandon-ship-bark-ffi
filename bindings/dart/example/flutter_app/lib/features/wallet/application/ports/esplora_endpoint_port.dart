import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';

/// Port for accessing Esplora endpoint information
/// Wallet feature defines what it needs, adapter implements using facade
abstract class EsploraEndpointPort {
  /// Get Esplora endpoint URL for the given network
  /// Returns default endpoint if none is configured by user
  Future<Either<Failure, String>> getEndpointUrlForNetwork(String network);
}
