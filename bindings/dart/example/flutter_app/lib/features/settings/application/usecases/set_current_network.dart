import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/settings/application/ports/settings_repository.dart';
import 'package:flutter_app/features/settings/domain/value_objects/bitcoin_network_vo.dart';

/// Command for setting current network
class SetCurrentNetworkCommand extends Equatable {
  final String network;

  const SetCurrentNetworkCommand({required this.network});

  @override
  List<Object> get props => [network];
}

/// Use case for setting current network
/// Contains business logic for validation
class SetCurrentNetwork implements UseCase<void, SetCurrentNetworkCommand> {
  final SettingsRepository _repository;

  SetCurrentNetwork(this._repository);

  @override
  Future<Either<Failure, void>> call(SetCurrentNetworkCommand command) async {
    // Business logic: validate network
    if (!BitcoinNetworkVO.isValid(command.network)) {
      return Left(ValidationFailure('Invalid network: ${command.network}'));
    }

    try {
      await _repository.setCurrentNetwork(command.network);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to set current network: $e'));
    }
  }
}
