import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/settings/domain/value_objects/bitcoin_network_vo.dart';

/// Query for validating network
class ValidateNetworkQuery extends Equatable {
  final String network;

  const ValidateNetworkQuery({required this.network});

  @override
  List<Object> get props => [network];
}

/// Response for network validation
class ValidateNetworkResponse {
  final bool isValid;
  final String network;

  const ValidateNetworkResponse({
    required this.isValid,
    required this.network,
  });
}

/// Use case for validating if a network string is supported
/// Pure business logic - no repository needed
class ValidateNetwork implements UseCase<ValidateNetworkResponse, ValidateNetworkQuery> {
  ValidateNetwork();

  @override
  Future<Either<Failure, ValidateNetworkResponse>> call(ValidateNetworkQuery query) async {
    final isValid = BitcoinNetworkVO.isValid(query.network);

    return Right(ValidateNetworkResponse(
      isValid: isValid,
      network: query.network,
    ));
  }
}
