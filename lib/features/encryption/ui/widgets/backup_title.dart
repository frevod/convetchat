import 'package:convetchat/features/encryption/ui/cubit/encryption_state.dart';

String backupTitle(EncryptionState state) {
  if (state.step == .loading) return 'Загрузка…';
  if (state.step == .restore) return 'Восстановление ключей';
  if (state.reset) {
    return state.recoveryKey != null ? 'Всё готово' : 'Сброс ключей';
  }
  return 'Настройка шифрования';
}
