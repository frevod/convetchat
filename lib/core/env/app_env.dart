import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class AppEnv() {
  static String? _get(String name) {
    if (!dotenv.isInitialized) return null;
    return dotenv.maybeGet(name)?.trim();
  }

  static String? get telegramBotToken => _get('TELEGRAM_BOT_TOKEN');

  static String? get telegramChatId => _get('TELEGRAM_CHAT_ID');

  static bool get isTelegramFeedbackConfigured =>
      (telegramBotToken?.isNotEmpty ?? false) &&
      (telegramChatId?.isNotEmpty ?? false);
}
