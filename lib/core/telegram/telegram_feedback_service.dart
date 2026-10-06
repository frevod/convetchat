import 'dart:io' as io;
import 'dart:typed_data';

import 'package:convetchat/core/env/app_env.dart';
import 'package:convetchat/core/logging/talker_file_sink.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:televerse/telegram.dart';
import 'package:televerse/televerse.dart';

typedef TelegramSendResult = ({bool ok, String? error});

final class FeedbackAttachment({
  required final String name,
  final String? path,
  final List<int>? bytes,
});

final class TelegramFeedbackService(final Talker _talker) {
  static const _photoExts = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
  };
  static const _videoExts = {'mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v'};
  static const _albumLimit = 10;

  RawAPI? _apiInstance;

  bool get isConfigured => AppEnv.isTelegramFeedbackConfigured;

  RawAPI? _getApi() {
    if (!AppEnv.isTelegramFeedbackConfigured) return null;
    return _apiInstance ??= Bot(AppEnv.telegramBotToken!).api;
  }

  Future<TelegramSendResult> sendBugReport(
    String message, {
    String? userId,
    List<FeedbackAttachment> attachments = const [],
    bool includeLogs = false,
  }) async {
    final api = _getApi();
    if (api == null) return (ok: false, error: 'Отправка недоступна');
    final chatId = ID.create(AppEnv.telegramChatId!);
    final text = _compose(message, userId: userId);

    try {
      final album = <InputMedia>[];
      for (final attachment in attachments) {
        final caption = album.isEmpty && text.trim().isNotEmpty ? text : null;
        album.add(_mediaEntry(attachment, caption: caption));
      }

      if (album.isNotEmpty) {
        for (final chunk in _chunks(album, _albumLimit)) {
          await api.sendMediaGroup(chatId, chunk);
        }
      }

      if (includeLogs) {
        final logFile = TalkerFileSink.logFile;
        if (logFile == null || !await logFile.exists()) {
          return (ok: false, error: 'Не удалось собрать логи');
        }
        final caption = album.isEmpty && text.trim().isNotEmpty ? text : null;
        await api.sendDocument(
          chatId,
          InputFile.fromFile(logFile, name: 'talker.log'),
          caption: caption,
        );
      } else if (album.isEmpty && text.trim().isNotEmpty) {
        await api.sendMessage(chatId, text);
      }

      return (ok: true, error: null);
    } on TelegramException catch (e) {
      _talker.error('[feedback] Telegram ${e.code}: ${e.description}', e);
      return (ok: false, error: e.description ?? 'Ошибка ${e.code}');
    } catch (e, s) {
      _talker.error('[feedback] sendBugReport failed', e, s);
      return (ok: false, error: 'Нет соединения');
    }
  }

  InputMedia _mediaEntry(FeedbackAttachment attachment, {String? caption}) {
    final file = _inputFile(attachment);
    if (_isPhoto(attachment.name)) {
      return InputMedia.photo(media: file, caption: caption);
    }
    if (_isVideo(attachment.name)) {
      return InputMedia.video(media: file, caption: caption);
    }
    return InputMedia.document(media: file, caption: caption);
  }

  InputFile _inputFile(FeedbackAttachment attachment) {
    final path = attachment.path;
    if (path != null) {
      return InputFile.fromFile(io.File(path), name: attachment.name);
    }
    return InputFile.fromBytes(
      Uint8List.fromList(attachment.bytes ?? const []),
      name: attachment.name,
    );
  }

  List<List<T>> _chunks<T>(List<T> list, int size) => [
    for (var i = 0; i < list.length; i += size)
      list.sublist(i, (i + size).clamp(0, list.length)),
  ];
  bool _isPhoto(String name) => _photoExts.contains(_extensionOf(name));

  bool _isVideo(String name) => _videoExts.contains(_extensionOf(name));

  String _extensionOf(String name) => name.split('.').last.toLowerCase();

  String _compose(String message, {String? userId}) {
    final body = message.trim().isEmpty ? 'Отчёт ConvetChat' : message.trim();
    final footer = userId == null ? '' : '\n\n— $userId';
    return body + footer;
  }
}
