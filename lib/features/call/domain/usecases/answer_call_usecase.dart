import '../repositories/call_repository.dart';
import 'start_call_usecase.dart';

final class AnswerCallUseCase(final CallRepository _repository) {
  Future<CallHandle> call(StartCallParams params) =>
      _repository.answerVoiceCall(params.roomId);
}
