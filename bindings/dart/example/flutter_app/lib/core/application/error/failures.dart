import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({required String message}) : super(message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({required String message}) : super(message);
}

class ServiceFailure extends Failure {
  const ServiceFailure({required String message}) : super(message);
}

// Wallet specific failures
class WalletFailure extends Failure {
  const WalletFailure(super.message);
}

class InsufficientBalanceFailure extends Failure {
  const InsufficientBalanceFailure(super.message);
}

class TransactionFailure extends Failure {
  const TransactionFailure(super.message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required String message}) : super(message);
}
