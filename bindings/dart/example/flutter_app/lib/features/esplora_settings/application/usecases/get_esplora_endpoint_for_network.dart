import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/esplora_settings/application/ports/bitcoin_network_port.dart';
import 'package:flutter_app/features/esplora_settings/application/ports/esplora_settings_repository.dart';

/// Query for getting Esplora endpoint for a specific network
class GetEsploraEndpointForNetworkQuery extends Equatable {
  final String network;

  const GetEsploraEndpointForNetworkQuery({required this.network});

  @override
  List<Object> get props => [network];
}

/// Response DTO for Esplora endpoint
class EsploraEndpointResponse extends Equatable {
  final int id;
  final String baseUrl;
  final String label;
  final String network;
  final int priority;
  final bool isDefault;

  const EsploraEndpointResponse({
    required this.id,
    required this.baseUrl,
    required this.label,
    required this.network,
    required this.priority,
    required this.isDefault,
  });

  @override
  List<Object> get props => [id, baseUrl, label, network, priority, isDefault];
}

/// Use case for getting Esplora endpoint for a specific network
/// Uses SettingsFacade to validate network through business logic
class GetEsploraEndpointForNetwork
    implements
        UseCase<EsploraEndpointResponse, GetEsploraEndpointForNetworkQuery> {
  final EsploraSettingsRepository _repository;
  final BitcoinNetworkPort _bitcoinNetworkPort;

  GetEsploraEndpointForNetwork(this._repository, this._bitcoinNetworkPort);

  @override
  Future<Either<Failure, EsploraEndpointResponse>> call(
    GetEsploraEndpointForNetworkQuery query,
  ) async {
    // Validate network using settings facade (goes through use case)
    final validationResult = await _bitcoinNetworkPort.isValidNetwork(
      query.network,
    );

    return await validationResult.fold((failure) => Left(failure), (
      isValid,
    ) async {
      if (!isValid) {
        return Left(ValidationFailure('Invalid network: ${query.network}'));
      }

      final endpoint = await _repository.getEsploraEndpointByNetwork(
        query.network,
      );

      // Business logic: If no endpoint configured, return default
      if (endpoint == null) {
        return Right(_getDefaultEndpoint(query.network));
      }

      return Right(
        EsploraEndpointResponse(
          id: endpoint.id,
          baseUrl: endpoint.baseUrl,
          label: endpoint.label ?? endpoint.baseUrl,
          network: endpoint.network,
          priority: endpoint.priority,
          isDefault: false,
        ),
      );
    });
  }

  /// Default endpoints (business logic, not data access)
  EsploraEndpointResponse _getDefaultEndpoint(String network) {
    switch (network) {
      case 'mainnet':
        return const EsploraEndpointResponse(
          id: -1,
          baseUrl: 'https://blockstream.info/api',
          label: 'Blockstream (Default)',
          network: 'mainnet',
          priority: 0,
          isDefault: true,
        );
      case 'testnet3':
        return const EsploraEndpointResponse(
          id: -1,
          baseUrl: 'https://blockstream.info/testnet/api',
          label: 'Blockstream Testnet (Default)',
          network: 'testnet3',
          priority: 0,
          isDefault: true,
        );
      case 'testnet4':
        return const EsploraEndpointResponse(
          id: -1,
          baseUrl: 'https://mempool.space/testnet4/api',
          label: 'Mempool Testnet4 (Default)',
          network: 'testnet4',
          priority: 0,
          isDefault: true,
        );
      case 'signet':
        return const EsploraEndpointResponse(
          id: -1,
          baseUrl: 'https://esplora.signet.2nd.dev',
          label: '2nd Signet (Default)',
          network: 'signet',
          priority: 0,
          isDefault: true,
        );
      default:
        return const EsploraEndpointResponse(
          id: -1,
          baseUrl: 'https://blockstream.info/api',
          label: 'Blockstream (Default)',
          network: 'mainnet',
          priority: 0,
          isDefault: true,
        );
    }
  }
}
