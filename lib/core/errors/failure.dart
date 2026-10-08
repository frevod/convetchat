import 'package:equatable/equatable.dart';

sealed class const Failure(final String message) extends Equatable {
  @override
  List<Object?> get props => [message];
}

final class const ServerFailure(super.message) extends Failure;

final class const NetworkFailure(super.message) extends Failure;

final class const ValidationFailure(super.message) extends Failure;

final class const CacheFailure(super.message) extends Failure;
