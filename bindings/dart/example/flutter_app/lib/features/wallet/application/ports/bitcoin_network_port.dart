import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';

/// Port for accessing Bitcoin network settings
/// This is what the wallet feature needs from the settings feature
abstract class BitcoinNetworkPort {
  /// Get the currently selected Bitcoin network
  Future<Either<Failure, String>> getCurrentNetwork();

  /// Validate if a network string is valid
  Future<Either<Failure, bool>> isValidNetwork(String network);
}
