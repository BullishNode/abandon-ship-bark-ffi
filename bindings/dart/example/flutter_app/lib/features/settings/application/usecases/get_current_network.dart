import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/settings/application/ports/settings_repository.dart';

/// Response DTO for current network
class CurrentNetworkResponse {
  final String network;

  const CurrentNetworkResponse({required this.network});
}

/// Use case for getting current network setting
/// Returns 'signet' as default if no network is set
class GetCurrentNetwork implements UseCase<CurrentNetworkResponse, NoParams> {
  static const String _defaultNetwork = 'signet';

  final SettingsRepository _repository;

  GetCurrentNetwork(this._repository);

  @override
  Future<Either<Failure, CurrentNetworkResponse>> call(NoParams params) async {
    try {
      final network = await _repository.getCurrentNetwork();
      // Business logic: return default if no network is set
      return Right(CurrentNetworkResponse(network: network ?? _defaultNetwork));
    } catch (e) {
      return Left(CacheFailure('Failed to get current network: $e'));
    }
  }
}
