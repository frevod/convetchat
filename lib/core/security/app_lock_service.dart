import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/settings/domain/repositories/security_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Гейт блокировки приложения.
///
/// `locked == true` — поверх всего UI показывается экран ввода PIN.
/// Блокируется каждый холодный старт и каждый возврат из фона,
/// если в настройках включён app lock. Таймаута нет по требованию.
class AppLockService extends ValueNotifier<bool> {
  AppLockService() : super(false);

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
      getIt<Talker>().error('[app-lock] Не удалось прочитать флаг', e, s);
    }
  }

  /// Перечитать флаг после изменения настроек.
  /// Не блокирует текущую сессию — лок только на следующий запуск/возврат.
  Future<void> refresh() async {
    try {
      _lockEnabled = await getIt<SecurityRepository>().isAppLockEnabled();
      if (!_lockEnabled) value = false;
    } catch (e, s) {
      getIt<Talker>().error('[app-lock] Не удалось обновить флаг', e, s);
    }
  }

  /// Вызывается из lifecycle при возврате в foreground.
  Future<void> onResumed() async {
    try {
      _lockEnabled = await getIt<SecurityRepository>().isAppLockEnabled();
    } catch (e, s) {
      getIt<Talker>().error('[app-lock] Не удалось прочитать флаг', e, s);
      return;
    }
    if (_lockEnabled) value = true;
  }

  void unlock() => value = false;
}
