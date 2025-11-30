import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';

/// Port for Bitcoin network operations needed by esplora settings feature
abstract class BitcoinNetworkPort {
  /// Validate if network string is supported
  Future<Either<Failure, bool>> isValidNetwork(String network);
}
