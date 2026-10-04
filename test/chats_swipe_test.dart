import 'dart:async';
import 'dart:typed_data';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chats/domain/entities/chat_room.dart';
import 'package:convetchat/features/chats/domain/entities/connection_status.dart';
import 'package:convetchat/features/chats/domain/entities/public_room.dart';
import 'package:convetchat/features/chats/domain/entities/searched_message.dart';
import 'package:convetchat/features/chats/domain/entities/searched_user.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_cubit.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_state.dart';
import 'package:convetchat/features/chats/ui/widgets/chats_list_andr.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeChatsRepository implements ChatsRepository {
  FakeChatsRepository(List<ChatRoom> rooms)
    : _rooms = rooms,
      _controller = StreamController<
        ({List<ChatRoom> rooms, List<ChatRoom> invites})
      >.broadcast();

  List<ChatRoom> _rooms;
  final StreamController<({List<ChatRoom> rooms, List<ChatRoom> invites})>
  _controller;

  int setPinnedCalls = 0;
  String? lastPinnedId;
  bool? lastPinnedValue;

  void emitRooms(List<ChatRoom> rooms) {
    _rooms = rooms;
    _controller.add((rooms: List.of(rooms), invites: const []));
  }

  @override
  Stream<({List<ChatRoom> rooms, List<ChatRoom> invites})> watchRooms() async* {
    yield (rooms: List.of(_rooms), invites: const []);
    yield* _controller.stream;
  }

  @override
  Stream<ConnectionStatus> watchConnectionStatus() =>
      Stream.value(ConnectionStatus.connected);

  @override
  Future<void> firstSync() async {}

  @override
  Future<void> setPinned(String roomId, bool pinned) async {
    setPinnedCalls++;
    lastPinnedId = roomId;
    lastPinnedValue = pinned;
  }

  @override
  Future<void> leaveRoom(String roomId) async {}

  @override
  Future<void> setMuted(String roomId, bool muted) async {}

  @override
  Future<void> acceptInvite(String roomId) async {}

  @override
  Future<void> declineInvite(String roomId) async {}

  @override
  Future<List<SearchedUser>> searchUsers(String query) async => [];

  @override
  Future<List<SearchedMessage>> searchMessages(String query) async => [];

  @override
  Future<List<PublicRoom>> searchPublicRooms(String query) async => [];

  @override
  Future<String> joinRoom(String roomId) async => roomId;

  @override
  Future<String> createDirectChat(String userId) async => '!x:y';

  @override
  Future<String> createGroup({
    String? name,
    required bool isPublic,
    required bool showInDirectory,
    Uint8List? avatarBytes,
    String? avatarFilename,
  }) async => '!x:y';
}

ChatRoom room(String id, String name, {bool pinned = false}) => ChatRoom(
  id: id,
  displayName: name,
  lastMessage: 'hi',
  lastTime: DateTime(2026, 1, 1),
  unreadCount: 0,
  avatarMxc: null,
  isDirect: false,
  online: false,
  isPinned: pinned,
);

Future<void> pumpList(WidgetTester tester, ChatsCubit cubit) {
  return tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        // ignore: deprecated_member_use
        child: MaterialUiCompatibilityBridge(
          child: Scaffold(
            body: BlocBuilder<ChatsCubit, ChatsState>(
              bloc: cubit,
              builder: (context, state) => ChatsListAndr(state: state),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    if (!getIt.isRegistered<PlatformStyle>()) {
      getIt.registerSingleton<PlatformStyle>(PlatformStyle.material);
    }
  });

  testWidgets('reveal pin by swipe right and tap pins the room', (
    tester,
  ) async {
    final repo = FakeChatsRepository([
      room('!a:s', 'Alpha'),
      room('!b:s', 'Beta'),
    ]);
    final cubit = ChatsCubit(repo);
    addTearDown(cubit.close);

    await pumpList(tester, cubit);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Короткий свайп вправо по первой строке.
    final first = find.text('Alpha');
    expect(first, findsOneWidget);
    await tester.drag(first, const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Кнопка закрепа должна быть видна и тапабельна.
    final pinBtn = find.byIcon(Icons.push_pin_rounded);
    expect(pinBtn, findsWidgets);
    await tester.tap(pinBtn.first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(repo.setPinnedCalls, 1);
    expect(repo.lastPinnedId, '!a:s');
    expect(repo.lastPinnedValue, isTrue);
  });

  testWidgets('leave/remove + re-add snapshot does not duplicate GlobalKey', (
    tester,
  ) async {
    final repo = FakeChatsRepository([
      room('!a:s', 'Alpha'),
      room('!b:s', 'Beta'),
    ]);
    final cubit = ChatsCubit(repo);
    addTearDown(cubit.close);

    await pumpList(tester, cubit);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Оптимистичное удаление как при leave, затем возврат снепшота с комнатой
    // (синк ещё не догнал) — ключи не должны задвоиться.
    repo.emitRooms([room('!b:s', 'Beta')]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    repo.emitRooms([room('!a:s', 'Alpha'), room('!b:s', 'Beta')]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('leave via swipe button + confirm removes the swiped room', (
    tester,
  ) async {
    final repo = FakeChatsRepository([
      room('!a:s', 'Alpha'),
      room('!b:s', 'Beta'),
    ]);
    final cubit = ChatsCubit(repo);
    addTearDown(cubit.close);

    await pumpList(tester, cubit);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Свайп влево по первой строке открывает кнопку выхода.
    await tester.drag(find.text('Alpha'), const Offset(-160, 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.logout_rounded).first);
    await tester.pumpAndSettle();

    // Диалог подтверждения — строка всё ещё в списке.
    expect(find.text('Покинуть комнату?'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);

    // Подтверждаем — уходит именно Alpha, Beta остаётся.
    await tester.tap(find.text('Покинуть'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('leave cancel keeps the room, lagging sync does not resurrect', (
    tester,
  ) async {
    final repo = FakeChatsRepository([
      room('!a:s', 'Alpha'),
      room('!b:s', 'Beta'),
    ]);
    final cubit = ChatsCubit(repo);
    addTearDown(cubit.close);

    await pumpList(tester, cubit);
    await tester.pumpAndSettle();

    await tester.drag(find.text('Alpha'), const Offset(-160, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.logout_rounded).first);
    await tester.pumpAndSettle();

    // Отмена — ничего не убирается.
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Подтверждённый выход + отставший снепшот с комнатой:
    // строка не появляется заново.
    await tester.drag(find.text('Alpha'), const Offset(-160, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.logout_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Покинуть'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsNothing);

    repo.emitRooms([room('!a:s', 'Alpha'), room('!b:s', 'Beta')]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
