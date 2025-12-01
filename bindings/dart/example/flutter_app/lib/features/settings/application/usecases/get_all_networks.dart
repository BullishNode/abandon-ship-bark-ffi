import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/settings/domain/value_objects/bitcoin_network_vo.dart';

/// Response DTO for all networks
class AllNetworksResponse {
  final List<String> networks;

  const AllNetworksResponse({required this.networks});
}

/// Use case for getting all supported networks
/// Pure business logic - no repository needed
class GetAllNetworks implements UseCase<AllNetworksResponse, NoParams> {
  GetAllNetworks();

  @override
  Future<Either<Failure, AllNetworksResponse>> call(NoParams params) async {
    final networks = BitcoinNetworkVO.all.map((n) => n.value).toList();

    return Right(AllNetworksResponse(networks: networks));
  }
}
