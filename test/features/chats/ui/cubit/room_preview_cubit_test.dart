import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chats/domain/entities/join_rule.dart';
import 'package:convetchat/features/chats/domain/entities/public_room.dart';
import 'package:convetchat/features/chats/domain/entities/room_preview.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:convetchat/features/chats/ui/cubit/room_preview_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';

class FakeChatsRepository() implements ChatsRepository {
  RoomPreview preview = const RoomPreview(
    roomId: '!room:server',
    name: 'Комната',
    topic: 'Топик',
    avatarMxc: null,
    memberCount: 7,
    joinRule: JoinRule.knock,
    knocked: false,
  );
  int knockCalls = 0;
  int cancelCalls = 0;
  int joinCalls = 0;
  Object? failure;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<RoomPreview> fetchRoomPreview(String roomIdOrAlias) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    return preview;
  }

  @override
  Future<String> knockRoom(String roomId) async {
    knockCalls++;
    preview = preview.copyWith(knocked: () => true);
    return roomId;
  }

  @override
  Future<void> cancelKnock(String roomId) async {
    cancelCalls++;
    preview = preview.copyWith(knocked: () => false);
  }

  @override
  Future<String> joinRoom(String roomId) async {
    joinCalls++;
    return roomId;
  }
}

void main() {
  setUp(() {
    if (!getIt.isRegistered<Talker>()) {
      getIt.registerSingleton<Talker>(Talker());
    }
  });

  tearDown(() {
    if (getIt.isRegistered<Talker>()) {
      getIt.unregister<Talker>();
    }
  });

  group('RoomPreviewCubit', () {
    test('loads preview from summary', () async {
      final repository = FakeChatsRepository();
      final cubit = RoomPreviewCubit(
        repository,
        summarySupported: () async => true,
      );
      await cubit.load('!room:server');
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.preview?.roomId, '!room:server');
      expect(cubit.state.preview?.joinRule, JoinRule.knock);
      await cubit.close();
    });

    test('builds preview from fallback without summary', () async {
      final repository = FakeChatsRepository();
      final cubit = RoomPreviewCubit(
        repository,
        summarySupported: () async => false,
      );
      const fallback = PublicRoom(
        roomId: '!room:server',
        name: 'Из каталога',
        topic: '',
        avatarMxc: null,
        memberCount: 3,
      );
      await cubit.load('!room:server', fallback: fallback);
      expect(cubit.state.preview?.name, 'Из каталога');
      expect(cubit.state.preview?.knocked, isFalse);
      await cubit.close();
    });

    test('knock and cancel flip knocked flag', () async {
      final repository = FakeChatsRepository();
      final cubit = RoomPreviewCubit(
        repository,
        summarySupported: () async => true,
      );
      await cubit.load('!room:server');
      await cubit.knock();
      expect(cubit.state.preview?.knocked, isTrue);
      await cubit.cancelKnock();
      expect(cubit.state.preview?.knocked, isFalse);
      await cubit.close();
    });

    test('join returns room id', () async {
      final repository = FakeChatsRepository();
      final cubit = RoomPreviewCubit(
        repository,
        summarySupported: () async => true,
      );
      await cubit.load('!room:server');
      final roomId = await cubit.join();
      expect(roomId, '!room:server');
      expect(repository.joinCalls, 1);
      await cubit.close();
    });

    test('load failure sets error message', () async {
      final repository = FakeChatsRepository()..failure = Exception('nope');
      final cubit = RoomPreviewCubit(
        repository,
        summarySupported: () async => true,
      );
      await cubit.load('!room:server');
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.isLoading, isFalse);
      await cubit.close();
    });
  });
}
