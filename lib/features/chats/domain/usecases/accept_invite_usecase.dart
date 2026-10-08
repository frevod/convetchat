import 'package:convetchat/core/errors/failure.dart';
import 'package:convetchat/core/matrix/matrix_call_failure.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:dartz/dartz.dart';

final class const AcceptInviteParams({required final String roomId});

final class AcceptInviteUseCase(final ChatsRepository _repository) {
  Future<Either<Failure, void>> call(AcceptInviteParams params) async {
    if (params.roomId.isEmpty) {
      return const Left(ValidationFailure('Не указан чат'));
    }
    try {
      await _repository.acceptInvite(params.roomId);
      return const Right(null);
    } on MatrixCallFailure catch (e) {
      return Left(ServerFailure(e.userMessage));
    } catch (_) {
      return const Left(ServerFailure('Не удалось принять приглашение'));
    }
  }
}
