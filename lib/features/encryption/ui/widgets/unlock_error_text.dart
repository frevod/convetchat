import 'package:matrix/encryption.dart';

String unlockErrorText(Object error) {
  if (error is InvalidPassphraseException) {
    return 'Неверный ключ или кодовая фраза';
  }
  return 'Неожиданная ошибка: $error';
}
