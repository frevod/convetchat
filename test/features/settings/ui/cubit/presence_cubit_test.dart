import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/presence/presence_mode.dart';
import 'package:convetchat/features/settings/domain/repositories/presence_repository.dart';
import 'package:convetchat/features/settings/ui/cubit/presence_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

class FakePresenceRepository() implements PresenceRepository {
  PresenceMode mode = PresenceMode.online;
  bool? supported = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<PresenceMode> ownMode() async => mode;

  @override
  Future<void> setOwnMode(PresenceMode value) async {
    mode = value;
  }

  @override
  Stream<PresenceMode> watchOwnMode() => Stream.value(mode);

  @override
  Future<bool?> busySupported() async => supported;
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

  group('PresenceMode', () {
    test('maps to matrix presence types', () {
      expect(PresenceMode.online.presenceType, PresenceType.online);
      expect(PresenceMode.busy.presenceType, PresenceType.unavailable);
      expect(PresenceMode.offline.presenceType, PresenceType.offline);
    });

    test('parses stored names with online fallback', () {
      expect(PresenceMode.fromName('busy'), PresenceMode.busy);
      expect(PresenceMode.fromName('offline'), PresenceMode.offline);
      expect(PresenceMode.fromName(null), PresenceMode.online);
      expect(PresenceMode.fromName('unknown'), PresenceMode.online);
    });
  });

  group('PresenceCubit', () {
    test('loads mode and support flag', () async {
      final repository = FakePresenceRepository()..mode = PresenceMode.busy;
      final cubit = PresenceCubit(repository);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.supported, isTrue);
      expect(cubit.state.mode, PresenceMode.busy);
      await cubit.close();
    });

    test('hides selector on explicit server refusal', () async {
      final repository = FakePresenceRepository()..supported = false;
      final cubit = PresenceCubit(repository);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.supported, isFalse);
      await cubit.close();
    });

    test('setMode persists through repository', () async {
      final repository = FakePresenceRepository();
      final cubit = PresenceCubit(repository);
      await Future<void>.delayed(Duration.zero);
      await cubit.setMode(PresenceMode.offline);
      expect(cubit.state.mode, PresenceMode.offline);
      expect(repository.mode, PresenceMode.offline);
      await cubit.close();
    });
  });
}
