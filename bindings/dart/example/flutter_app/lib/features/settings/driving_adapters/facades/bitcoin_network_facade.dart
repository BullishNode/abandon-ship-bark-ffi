import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/settings/application/usecases/get_all_networks.dart';
import 'package:flutter_app/features/settings/application/usecases/get_current_network.dart';
import 'package:flutter_app/features/settings/application/usecases/set_current_network.dart';
import 'package:flutter_app/features/settings/application/usecases/validate_network.dart';

/// Facade for Bitcoin network operations
/// Exposes network operations to other features through use cases
/// This ensures business logic is always applied
class BitcoinNetworkFacade {
  final GetAllNetworks _getAllNetworks;
  final ValidateNetwork _validateNetwork;
  final GetCurrentNetwork _getCurrentNetwork;
  final SetCurrentNetwork _setCurrentNetwork;

  BitcoinNetworkFacade({
    required GetAllNetworks getAllNetworks,
    required ValidateNetwork validateNetwork,
    required GetCurrentNetwork getCurrentNetwork,
    required SetCurrentNetwork setCurrentNetwork,
  }) : _getAllNetworks = getAllNetworks,
       _validateNetwork = validateNetwork,
       _getCurrentNetwork = getCurrentNetwork,
       _setCurrentNetwork = setCurrentNetwork;

  Future<Either<Failure, List<String>>> getAllNetworks() async {
    final result = await _getAllNetworks(NoParams());
    return result.map((response) => response.networks);
  }

  Future<Either<Failure, bool>> isValidNetwork(String network) async {
    final result = await _validateNetwork(
      ValidateNetworkQuery(network: network),
    );
    return result.map((response) => response.isValid);
  }

  Future<Either<Failure, String>> getCurrentNetwork() async {
    final result = await _getCurrentNetwork(NoParams());
    return result.map((response) => response.network);
  }

  Future<Either<Failure, void>> setCurrentNetwork(String network) async {
    return await _setCurrentNetwork(SetCurrentNetworkCommand(network: network));
  }
}
