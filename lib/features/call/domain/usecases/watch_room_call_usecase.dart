import '../entities/room_call_info.dart';
import '../repositories/call_repository.dart';

final class WatchRoomCallUseCase(final CallRepository _repository) {
  Stream<RoomCallInfo> call(String roomId) =>
      _repository.watchRoomCall(roomId);
}
