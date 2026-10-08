import 'package:convetchat/core/errors/failure.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:dartz/dartz.dart';

final class const DeclineInviteParams({required final String roomId});

final class DeclineInviteUseCase(final ChatsRepository _repository) {
  Future<Either<Failure, void>> call(DeclineInviteParams params) async {
    if (params.roomId.isEmpty) {
      return const Left(ValidationFailure('Не указан чат'));
    }
    try {
      await _repository.declineInvite(params.roomId);
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure('Не удалось отклонить приглашение'));
    }
  }
}
