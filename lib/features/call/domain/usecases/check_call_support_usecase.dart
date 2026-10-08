import '../entities/call_support.dart';
import '../repositories/call_repository.dart';

final class CheckCallSupportUseCase(final CallRepository _repository) {
  Future<CallSupportResult> call() => _repository.checkSupport();
}
