import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chat/ui/cubit/invite_picker_cubit.dart';
import 'package:convetchat/features/chats/domain/entities/searched_user.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';

class FakeChatsRepository() implements ChatsRepository {
  List<SearchedUser> partners = const [
    SearchedUser(userId: '@alice:server', displayName: 'Алиса'),
  ];
  List<SearchedUser> found = const [
    SearchedUser(userId: '@bob:server', displayName: 'Боб'),
  ];
  List<String> invited = [];
  String? lastReason;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<SearchedUser>> directChatPartners() async => partners;

  @override
  Future<List<SearchedUser>> searchUsers(String query) async => found;

  @override
  Future<void> inviteUser(
    String roomId,
    String userId, {
    String? reason,
  }) async {
    invited.add(userId);
    lastReason = reason;
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

  group('InvitePickerCubit', () {
    test('loads candidates and merges search results', () async {
      final repository = FakeChatsRepository();
      final cubit = InvitePickerCubit(repository);
      await Future<void>.delayed(Duration.zero);
      expect(
        cubit.state.candidates.map((user) => user.userId),
        contains('@alice:server'),
      );
      cubit.setQuery('боб');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(
        cubit.state.visible.map((user) => user.userId),
        contains('@bob:server'),
      );
      await cubit.close();
    });

    test('toggles selection', () async {
      final repository = FakeChatsRepository();
      final cubit = InvitePickerCubit(repository);
      await Future<void>.delayed(Duration.zero);
      cubit.toggle('@alice:server');
      expect(cubit.state.selected, contains('@alice:server'));
      cubit.toggle('@alice:server');
      expect(cubit.state.selected, isEmpty);
      await cubit.close();
    });

    test('invites all selected with reason', () async {
      final repository = FakeChatsRepository();
      final cubit = InvitePickerCubit(repository);
      await Future<void>.delayed(Duration.zero);
      cubit.toggle('@alice:server');
      cubit.toggle('@bob:server');
      final ok = await cubit.inviteAll('!room:server', 'соседи');
      expect(ok, isTrue);
      expect(repository.invited, containsAll(['@alice:server', '@bob:server']));
      expect(repository.lastReason, 'соседи');
      await cubit.close();
    });

    test('manualUserId accepts full ids only', () {
      expect(InvitePickerCubit.manualUserId('@bob:server'), '@bob:server');
      expect(InvitePickerCubit.manualUserId('боб'), isNull);
      expect(InvitePickerCubit.manualUserId('@bob'), isNull);
    });
  });
}
