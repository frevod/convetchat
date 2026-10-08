import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/domain/entities/notification_mode.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:convetchat/features/chats/ui/cubit/notification_mode_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';

class FakeChatsRepository() implements ChatsRepository {
  Set<String> mentionsOnly = {};
  bool supported = true;
  bool muted = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> setNotificationMode(String roomId, NotificationMode mode) async {
    if (mode == NotificationMode.mentions) {
      mentionsOnly.add(roomId);
    } else {
      mentionsOnly.remove(roomId);
    }
  }

  @override
  Stream<Set<String>> watchMentionsOnlyRooms() => Stream.value(mentionsOnly);

  @override
  Stream<({List<ChatRoom> rooms, List<ChatRoom> invites})> watchRooms() =>
      Stream.value((rooms: [], invites: []));

  @override
  Future<bool> mentionsOnlySupported() async => supported;

  @override
  Future<bool> isRoomMuted(String roomId) async => muted;

  @override
  Future<void> setMuted(String roomId, bool value) async {
    muted = value;
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

  group('NotificationModeCubit', () {
    test('loads mode and support flag', () async {
      final repository = FakeChatsRepository()..mentionsOnly = {'!room:server'};
      final cubit = NotificationModeCubit(repository, roomId: '!room:server');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.supported, isTrue);
      expect(cubit.state.mode, NotificationMode.mentions);
      await cubit.close();
    });

    test('defaults to all messages', () async {
      final repository = FakeChatsRepository();
      final cubit = NotificationModeCubit(repository, roomId: '!room:server');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.mode, NotificationMode.all);
      await cubit.close();
    });

    test('setMode persists through repository', () async {
      final repository = FakeChatsRepository();
      final cubit = NotificationModeCubit(repository, roomId: '!room:server');
      await Future<void>.delayed(Duration.zero);
      await cubit.setMode(NotificationMode.mentions);
      expect(cubit.state.mode, NotificationMode.mentions);
      expect(repository.mentionsOnly, contains('!room:server'));
      await cubit.close();
    });

    test('off mutes room, back to all unmutes', () async {
      final repository = FakeChatsRepository();
      final cubit = NotificationModeCubit(repository, roomId: '!room:server');
      await Future<void>.delayed(Duration.zero);
      await cubit.setMode(NotificationMode.off);
      expect(cubit.state.mode, NotificationMode.off);
      expect(repository.muted, isTrue);
      await cubit.setMode(NotificationMode.all);
      expect(cubit.state.mode, NotificationMode.all);
      expect(repository.muted, isFalse);
      await cubit.close();
    });

    test('muted room loads as off', () async {
      final repository = FakeChatsRepository()..muted = true;
      final cubit = NotificationModeCubit(repository, roomId: '!room:server');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.mode, NotificationMode.off);
      await cubit.close();
    });
  });
}
