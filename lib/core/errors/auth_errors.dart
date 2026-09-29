import 'dart:async';

import 'package:convetchat/features/auth/domain/exceptions/sso_cancelled_exception.dart';
import 'package:http/http.dart';
import 'package:matrix/matrix.dart';

String authErrorMessage(Object error, {required bool isLogin}) {
  if (error is SsoCancelledException) {
    return 'Вход через браузер отменён';
  }
  if (error is MatrixException) {
    return _matrixMessage(error, isLogin: isLogin);
  }
  if (error is BadServerLoginTypesException) {
    return 'Этот сервер не поддерживает вход по паролю';
  }
  if (error is SyncConnectionException ||
      error is TimeoutException ||
      error is ClientException) {
    return 'Нет соединения с сервером. Проверьте интернет и попробуйте снова';
  }
  if (error is FormatException) {
    return isLogin
        ? 'Некорректные данные для входа'
        : 'Похоже, это не адрес homeserver. Проверьте написание';
  }
  return 'Что-то пошло не так. Попробуйте позже';
}

String _matrixMessage(MatrixException error, {required bool isLogin}) {
  if (error.error == .M_FORBIDDEN &&
      error.errorMessage.toLowerCase().contains('device')) {
    return 'Достигнут лимит устройств. Удалите неиспользуемые сессии '
        'в настройках аккаунта и попробуйте снова';
  }
  switch (error.error) {
    case .M_FORBIDDEN:
      return isLogin
          ? 'Неверный логин или пароль'
          : 'Нет доступа. Проверьте адрес сервера';
    case .M_USER_DEACTIVATED:
      return 'Этот аккаунт деактивирован';
    case .M_INVALID_USERNAME:
      return 'Некорректное имя пользователя';
    case .M_USER_IN_USE:
      return 'Это имя пользователя уже занято';
    case .M_LIMIT_EXCEEDED:
      return 'Слишком много попыток. Подождите и попробуйте снова';
    case .M_SERVER_NOT_TRUSTED:
      return 'Сервер не прошёл проверку. Проверьте адрес';
    case .M_NOT_FOUND:
      return 'Сервер не найден. Проверьте адрес';
    case .M_UNAUTHORIZED:
      return isLogin
          ? 'Неверный логин или пароль'
          : 'Сервер отклонил запрос. Проверьте адрес';
    case .M_UNKNOWN_TOKEN:
      return 'Сессия истекла. Войдите снова';
    case .M_MISSING_PARAM:
    case .M_INVALID_PARAM:
    case .M_BAD_JSON:
      return 'Сервер не понял запрос. Обновите приложение и попробуйте снова';
    case .M_RESOURCE_LIMIT_EXCEEDED:
      return 'Сервер перегружен. Попробуйте позже';
    case .M_CAPTCHA_NEEDED:
    case .M_CAPTCHA_INVALID:
      return 'Сервер требует подтверждение, что вы не робот. Попробуйте через браузер';
    case .M_UNKNOWN:
    case .M_THREEPID_IN_USE:
    case .M_THREEPID_DENIED:
    case .M_THREEPID_NOT_FOUND:
    case .M_THREEPID_AUTH_FAILED:
    case .M_TOO_LARGE:
    case .M_UNSUPPORTED_ROOM_VERSION:
    case .M_UNRECOGNIZED:
    case .M_NOT_JSON:
    case .M_ROOM_IN_USE:
    case .M_INVALID_ROOM_STATE:
    case .M_INCOMPATIBLE_ROOM_VERSION:
    case .M_BAD_STATE:
    case .M_GUEST_ACCESS_FORBIDDEN:
    case .M_EXCLUSIVE:
    case .M_CANNOT_LEAVE_SERVER_NOTICE_ROOM:
      return isLogin
          ? 'Не удалось войти. Попробуйте позже'
          : 'Сервер вернул ошибку. Проверьте адрес и попробуйте снова';
  }
}
