import '../repositories/call_repository.dart';

final class StartCallParams({required final String roomId});

final class StartCallUseCase(final CallRepository _repository) {
  Future<CallHandle> call(StartCallParams params) =>
      _repository.startVoiceCall(params.roomId);
}
