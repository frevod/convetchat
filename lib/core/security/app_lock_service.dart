import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/settings/domain/repositories/security_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AppLockService() extends ValueNotifier<bool> {
  this : super(false);

  bool _initialized = false;
  bool _lockEnabled = false;

  bool get isLockEnabled => _lockEnabled;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _lockEnabled = await getIt<SecurityRepository>().isAppLockEnabled();
      if (_lockEnabled) value = true;
    } catch (e, s) {
      getIt<Talker>().error('[app-lock] read flag failed', e, s);
    }
  }

  Future<void> refresh() async {
    try {
      _lockEnabled = await getIt<SecurityRepository>().isAppLockEnabled();
      if (!_lockEnabled) value = false;
    } catch (e, s) {
      getIt<Talker>().error('[app-lock] refresh flag failed', e, s);
    }
  }

  void unlock() => value = false;
}
