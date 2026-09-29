import 'dart:async';
import 'dart:io';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/push/push_service.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/domain/entities/chat_send_restriction.dart';
import 'package:convetchat/features/chat/domain/entities/pending_media.dart';
import 'package:convetchat/features/chat/domain/repositories/chat_repository.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_state.dart';
import 'package:convetchat/features/encryption/domain/repositories/encryption_repository.dart';
import 'package:convetchat/features/encryption/ui/widgets/key_verification_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path_lib;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:record/record.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ChatCubit(
  final ChatRepository _repository, {
  required final String _roomId,
}) extends Cubit<ChatState> {
  this
    : super(
        ChatState(
          roomName: _repository.roomName(_roomId),
          avatarMxc: _repository.roomAvatar(_roomId),
          partnerUserId: _repository.directChatPartner(_roomId),
        ),
      ) {
    _subscription = _repository.watchMessages(_roomId).listen((messages) {
      if (isClosed) return;
      emit(state.copyWith(messages: () => messages, isLoading: () => false));

      if (messages.isNotEmpty) markAsRead();
    });
    _typingSubscription = _repository.watchTypingUsers(_roomId).listen((users) {
      if (isClosed) return;
      emit(state.copyWith(typingUsers: () => users));
    });
    _presenceSubscription = _repository.watchPartnerPresence(_roomId).listen((
      presence,
    ) {
      if (isClosed) return;
      emit(
        state.copyWith(
          partnerOnline: () => presence.online,
          partnerLastActive: () => presence.lastActive,
        ),
      );
    });
    _restrictionSubscription = _repository.watchSendRestriction(_roomId).listen(
      (restriction) {
        if (isClosed) return;
        emit(state.copyWith(sendRestriction: () => restriction));
      },
    );
    inputController.addListener(_onInputChanged);
  }

  late final StreamSubscription<List<ChatMessage>> _subscription;
  late final StreamSubscription<List<({String id, String name})>>
  _typingSubscription;
  late final StreamSubscription<({bool online, DateTime? lastActive})>
  _presenceSubscription;
  late final StreamSubscription<ChatSendRestriction> _restrictionSubscription;

  String get roomId => _roomId;

  final TextEditingController inputController = TextEditingController();
  final FocusNode inputFocus = FocusNode();
  Timer? _highlightTimer;

  Timer? _typingEchoTimer;
  bool _typingSent = false;

  static const _typingCooldown = Duration(seconds: 2);

  AudioRecorder? _recorder;
  Timer? _recordTick;
  Stopwatch? _recordWatch;

  int _recordGeneration = 0;

  int? _pendingLockGeneration;

  static const _recordLevelsCap = 64;

  static const _minVoiceMs = 1000;

  static const _voiceWaveBars = 32;

  static const _maxPendingMedia = 10;

  static const _pendingThumbSize = 320;

  final Map<String, Uint8List> _mediaCache = {};
  final Map<String, Future<Uint8List>> _mediaInflight = {};

  static const _mediaCacheCap = 40;

  @override
  Future<void> close() {
    _subscription.cancel();
    _typingSubscription.cancel();
    unawaited(_presenceSubscription.cancel());
    unawaited(_restrictionSubscription.cancel());
    _highlightTimer?.cancel();
    _recordTick?.cancel();
    unawaited(_recorder?.dispose());
    _recorder = null;
    _typingEchoTimer?.cancel();
    if (_typingSent) {
      unawaited(_repository.setTyping(_roomId, false));
    }
    inputController.removeListener(_onInputChanged);
    inputController.dispose();
    inputFocus.dispose();
    return super.close();
  }

  void _onInputChanged() {
    _typingEchoTimer?.cancel();
    if (inputController.text.trim().isNotEmpty) {
      if (!_typingSent) {
        _typingSent = true;
        unawaited(_repository.setTyping(_roomId, true));
      }
      _typingEchoTimer = Timer(_typingCooldown, () {
        _typingEchoTimer = null;
        if (!_typingSent) return;
        _typingSent = false;
        unawaited(_repository.setTyping(_roomId, false));
      });
    } else if (_typingSent) {
      _typingSent = false;
      _typingEchoTimer = null;
      unawaited(_repository.setTyping(_roomId, false));
    }
  }

  Future<void> sendText() => send();

  Future<void> send() async {
    final text = inputController.text.trim();
    final pending = List<PendingMedia>.of(state.pendingMedia);
    if (text.isEmpty && pending.isEmpty) return;
    final replyToEventId = state.replyTo?.id;
    inputController.clear();
    emit(
      state.copyWith(
        replyTo: () => null,
        pendingMedia: () => const <PendingMedia>[],
      ),
    );
    if (pending.isEmpty) {
      try {
        await _repository.sendText(
          roomId: _roomId,
          text: text,
          inReplyToEventId: replyToEventId,
        );
      } catch (e, s) {
        if (isClosed) return;
        getIt<Talker>().error('Не удалось отправить сообщение', e, s);
        emit(
          state.copyWith(
            errorMessage: () => 'Не удалось отправить. Попробуйте снова',
          ),
        );
      }
      return;
    }
    var failed = 0;
    for (var i = 0; i < pending.length; i++) {
      if (isClosed) return;
      final item = pending[i];
      try {
        await _repository.sendMedia(
          roomId: _roomId,
          filePath: item.filePath,
          fileName: item.fileName,
          isVideo: item.isVideo,
          width: item.width,
          height: item.height,
          durationMs: item.durationMs,
          thumbBytes: item.thumbBytes.isEmpty ? null : item.thumbBytes,
          thumbWidth: item.thumbWidth,
          thumbHeight: item.thumbHeight,
          caption: i == 0 && text.isNotEmpty ? text : null,
          inReplyToEventId: replyToEventId,
        );
      } catch (e, s) {
        if (isClosed) return;
        failed++;
        getIt<Talker>().error('Не удалось отправить медиа', e, s);
      }
    }
    if (failed > 0 && !isClosed) {
      emit(
        state.copyWith(
          errorMessage: () => 'Не отправилось. Нажмите на значок '
              'ошибки, чтобы повторить',
        ),
      );
    }
  }

  Future<void> attachAssets(List<AssetEntity> assets) async {
    if (isClosed || assets.isEmpty) return;
    final space = _maxPendingMedia - state.pendingMedia.length;
    if (space <= 0) {
      emit(
        state.copyWith(
          errorMessage: () => 'Максимум $_maxPendingMedia файлов за раз',
        ),
      );
      return;
    }
    final items = <PendingMedia>[];
    for (final asset in assets.take(space)) {
      if (isClosed) return;
      try {
        final file = await asset.file;
        if (file == null || isClosed) continue;
        final thumb = await asset.thumbnailDataWithSize(
          const ThumbnailSize.square(_pendingThumbSize),
        );
        if (isClosed) return;
        final isVideo = asset.type == .video;
        items.add(
          PendingMedia(
            id: '${DateTime.now().microsecondsSinceEpoch}_${asset.id}',
            filePath: file.path,
            fileName: asset.title ?? (isVideo ? 'video.mp4' : 'photo.jpg'),
            isVideo: isVideo,
            thumbBytes: thumb ?? Uint8List(0),
            width: asset.width,
            height: asset.height,
            durationMs: isVideo ? asset.videoDuration.inMilliseconds : null,
            thumbWidth: _thumbSide(asset.width, asset.height).$1,
            thumbHeight: _thumbSide(asset.width, asset.height).$2,
          ),
        );
      } catch (e, s) {
        getIt<Talker>().error('Не удалось подготовить медиа', e, s);
      }
    }
    if (isClosed || items.isEmpty) return;
    emit(
      state.copyWith(
        pendingMedia: () => [...state.pendingMedia, ...items],
        errorMessage: assets.length > space
            ? () => 'Максимум $_maxPendingMedia файлов за раз'
            : null,
      ),
    );
  }

  Future<void> removePending(String id) async {
    _dropPending(id);
  }

  Future<void> cancelSendMessage(ChatMessage message) async {
    if (!message.isOwn || message.status != .failed) return;
    try {
      await _repository.cancelSend(roomId: _roomId, eventId: message.id);
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('Не удалось отменить отправку', e, s);
      emit(state.copyWith(errorMessage: () => 'Не удалось убрать'));
    }
  }

  Future<void> retrySendMessage(ChatMessage message) async {
    if (!message.isOwn || message.status != .failed || isClosed) return;
    try {
      await _repository.retrySend(roomId: _roomId, eventId: message.id);
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('Не удалось повторить отправку', e, s);
      emit(
        state.copyWith(
          errorMessage: () => 'Не удалось отправить. Попробуйте снова',
        ),
      );
    }
  }

  void _dropPending(String id) {
    if (isClosed) return;
    if (!state.pendingMedia.any((p) => p.id == id)) return;
    emit(
      state.copyWith(
        pendingMedia: () =>
            state.pendingMedia.where((p) => p.id != id).toList(),
      ),
    );
  }

  static (int, int) _thumbSide(int width, int height) {
    if (width <= 0 || height <= 0) {
      return (_pendingThumbSize, _pendingThumbSize);
    }
    if (width >= height) {
      return (
        _pendingThumbSize,
        (_pendingThumbSize * height / width).round().clamp(
          1,
          _pendingThumbSize,
        ),
      );
    }
    return (
      (_pendingThumbSize * width / height).round().clamp(1, _pendingThumbSize),
      _pendingThumbSize,
    );
  }

  Future<Uint8List> mediaBytes({
    required String eventId,
    required bool thumb,
  }) async {
    final key = '$eventId:${thumb ? 't' : 'f'}';
    final cached = _mediaCache[key];
    if (cached != null) return cached;
    final inflight = _mediaInflight[key];
    if (inflight != null) return inflight;
    final future = _loadMedia(key, eventId: eventId, thumb: thumb);
    _mediaInflight[key] = future;
    try {
      return await future;
    } finally {
      _mediaInflight.remove(key);
    }
  }

  Future<Uint8List> _loadMedia(
    String key, {
    required String eventId,
    required bool thumb,
  }) async {
    final bytes = await _repository.mediaBytes(
      roomId: _roomId,
      eventId: eventId,
      thumb: thumb,
    );
    if (!isClosed) {
      if (_mediaCache.length >= _mediaCacheCap) {
        _mediaCache.remove(_mediaCache.keys.first);
      }
      _mediaCache[key] = bytes;
    }
    return bytes;
  }

  Future<File> videoFile({
    required String eventId,
    String? fileName,
    String? mimeType,
  }) async {
    final bytes = await mediaBytes(eventId: eventId, thumb: false);
    if (bytes.isEmpty) throw Exception('Файл видео пустой');
    final dir = Directory(
      path_lib.join((await getTemporaryDirectory()).path, 'video_cache'),
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File(
      path_lib.join(dir.path, _videoFileName(eventId, fileName, mimeType)),
    );
    if (!await file.exists() || await file.length() != bytes.length) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return file;
  }

  static String _videoFileName(
    String eventId,
    String? fileName,
    String? mimeType,
  ) {
    final safe = eventId.replaceAll(RegExp('[^A-Za-z0-9._-]'), '_');
    return '$safe.${_videoExt(fileName, mimeType)}';
  }

  static String _videoExt(String? fileName, String? mimeType) {
    final fromName = path_lib
        .extension(fileName ?? '')
        .replaceFirst('.', '')
        .toLowerCase();
    if (RegExp(r'^[a-z0-9]{1,5}$').hasMatch(fromName)) return fromName;
    return switch (mimeType?.toLowerCase()) {
      'video/quicktime' => 'mov',
      'video/webm' => 'webm',
      'video/x-matroska' => 'mkv',
      'video/3gpp' => '3gp',
      _ => 'mp4',
    };
  }

  Future<void> markAsRead() async {
    try {
      await _repository.markAsRead(_roomId);
    } catch (_, s) {
      getIt<Talker>().handle(s);
    }
    try {
      await getIt<PushService>().dismissForRoom(_roomId);
    } catch (e) {
      getIt<Talker>().warning('[push] Не удалось снять уведомление', e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: () => true));
    try {
      await _repository.loadMore(_roomId);
    } catch (e, s) {
      getIt<Talker>().error('Не удалось загрузить историю', e, s);
    } finally {
      if (!isClosed) emit(state.copyWith(isLoadingMore: () => false));
    }
  }

  Future<void> verifyPartner(BuildContext context) async {
    try {
      final verification = await _repository.verifyDirectPartner(_roomId);
      if (!context.mounted) return;
      final verified = await KeyVerificationDialog.show(context, verification);
      if (verified && !isClosed) {
        try {
          await getIt<EncryptionRepository>().requestMissingSessions();
        } catch (e, s) {
          getIt<Talker>().error('Не удалось запросить ключи', e, s);
        }
      }
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('Не удалось начать проверку', e, s);
      emit(state.copyWith(errorMessage: () => 'Не удалось начать проверку'));
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: () => null));
  }

  void setReply(ChatMessage message) {
    emit(state.copyWith(replyTo: () => message));
    inputFocus.requestFocus();
  }

  void jumpToMessage(String eventId) {
    emit(
      state.copyWith(
        scrollToEventId: () => eventId,
        scrollNonce: () => state.scrollNonce + 1,
        highlightEventId: () => eventId,
      ),
    );
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (isClosed) return;
      if (state.highlightEventId == eventId) {
        emit(state.copyWith(highlightEventId: () => null));
      }
    });
  }

  void cancelReply() {
    emit(state.copyWith(replyTo: () => null));
  }

  void toggleExpandedEvents(String eventId) {
    final messages = state.messages;
    final start = messages.indexWhere((m) => m.id == eventId);
    if (start < 0) return;
    final ids = {...state.expandedEventIds};
    final expand = !ids.contains(eventId);
    for (var i = start; i < messages.length; i++) {
      if (!messages[i].isState) break;
      if (expand) {
        ids.add(messages[i].id);
      } else {
        ids.remove(messages[i].id);
      }
    }
    emit(state.copyWith(expandedEventIds: () => ids));
  }

  void enterSelection(String eventId) {
    if (state.selectedEventIds.contains(eventId)) return;
    emit(state.copyWith(selectedEventIds: () => {eventId}));
  }

  void toggleSelection(String eventId) {
    final ids = {...state.selectedEventIds};
    if (!ids.remove(eventId)) ids.add(eventId);
    emit(state.copyWith(selectedEventIds: () => ids));
  }

  void clearSelection() {
    if (state.selectedEventIds.isEmpty && !state.forwardPickerOpen) return;
    emit(
      state.copyWith(
        selectedEventIds: () => const <String>{},
        forwardTargets: () => const [],
        forwardPickerOpen: () => false,
      ),
    );
  }

  Future<void> copySelected() async {
    final ids = state.selectedEventIds;
    if (ids.isEmpty) return;
    final parts = <String>[];
    for (final message in state.messages) {
      if (!ids.contains(message.id) || message.isState) continue;
      parts.add(message.body);
    }
    if (parts.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: parts.join('\n')));
  }

  Future<void> deleteSelected() async {
    final ids = state.selectedEventIds;
    if (ids.isEmpty) return;
    final mine = state.messages
        .where((m) => ids.contains(m.id) && !m.isState && m.isOwn)
        .map((m) => m.id)
        .toList(growable: false);
    clearSelection();
    if (mine.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: () => 'Можно удалять только свои сообщения',
        ),
      );
      return;
    }
    for (final id in mine) {
      try {
        await _repository.redactMessage(roomId: _roomId, eventId: id);
      } catch (_) {
        emit(
          state.copyWith(errorMessage: () => 'Не удалось удалить сообщение'),
        );
      }
    }
  }

  void closeForwardPicker() {
    emit(
      state.copyWith(
        forwardTargets: () => const [],
        forwardPickerOpen: () => false,
      ),
    );
  }

  Future<void> openForwardPicker() async {
    if (state.selectedEventIds.isEmpty) return;
    try {
      final targets = await _repository.forwardTargets(_roomId);
      if (isClosed) return;
      emit(
        state.copyWith(
          forwardTargets: () => targets,
          forwardPickerOpen: () => targets.isNotEmpty,
        ),
      );
      if (targets.isEmpty) {
        emit(state.copyWith(errorMessage: () => 'Нет доступных чатов'));
      }
    } catch (_) {
      emit(state.copyWith(errorMessage: () => 'Не удалось получить чаты'));
    }
  }

  Future<void> forwardSelectedTo(String targetRoomId) async {
    final ids = state.selectedEventIds;
    if (ids.isEmpty) return;
    final ordered = state.messages
        .where((m) => ids.contains(m.id) && !m.isState)
        .toList(growable: false);
    clearSelection();
    for (final message in ordered) {
      try {
        await _repository.forwardMessage(
          sourceRoomId: _roomId,
          targetRoomId: targetRoomId,
          eventId: message.id,
        );
      } catch (_) {
        emit(
          state.copyWith(errorMessage: () => 'Не удалось переслать сообщение'),
        );
        return;
      }
    }
  }

  Future<void> startRecording() async {
    if (state.isRecording) return;
    final generation = ++_recordGeneration;
    final recorder = AudioRecorder();
    try {
      if (!await recorder.hasPermission()) {
        await recorder.dispose();
        if (!isClosed) {
          emit(state.copyWith(errorMessage: () => 'Нет доступа к микрофону'));
        }
        return;
      }
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      var path = '';
      if (!kIsWeb) {
        path = path_lib.join((await getTemporaryDirectory()).path, fileName);
      }
      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      if (generation != _recordGeneration || isClosed) {
        await recorder.dispose();
        return;
      }
      _recorder = recorder;
      _recordWatch = Stopwatch()..start();
      _recordTick?.cancel();
      _recordTick = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _pollAmplitude(),
      );

      final locked = _pendingLockGeneration == generation;
      if (locked) _pendingLockGeneration = null;
      if (!isClosed) {
        emit(
          state.copyWith(
            isRecording: () => true,
            recordElapsed: () => Duration.zero,
            recordLevels: () => const <double>[],
            recordLocked: () => locked,
          ),
        );
      }
    } catch (e, s) {
      await recorder.dispose();
      if (isClosed) return;
      getIt<Talker>().error('Не удалось начать запись', e, s);
      emit(state.copyWith(errorMessage: () => 'Не удалось начать запись'));
    }
  }

  Future<void> _pollAmplitude() async {
    final recorder = _recorder;
    final watch = _recordWatch;
    if (isClosed || !state.isRecording) return;

    if (recorder == null || watch == null) {
      emit(
        state.copyWith(
          isRecording: () => false,
          recordElapsed: () => Duration.zero,
          recordLevels: () => const <double>[],
          recordLocked: () => false,
        ),
      );
      return;
    }
    try {
      final amplitude = await recorder.getAmplitude();
      final level = ((amplitude.current + 50) / 50).clamp(0.0, 1.0);
      final levels = [...state.recordLevels, level];
      if (levels.length > _recordLevelsCap) {
        levels.removeRange(0, levels.length - _recordLevelsCap);
      }
      emit(
        state.copyWith(
          recordElapsed: () => watch.elapsed,
          recordLevels: () => levels,
        ),
      );
    } catch (_) {}
  }

  Future<void> stopRecordingAndSend() async {
    _recordGeneration++;
    if (!state.isRecording) return;

    inputController.clear();
    final recorder = _recorder;
    _recorder = null;
    _recordTick?.cancel();
    _recordWatch?.stop();
    final elapsed = _recordWatch?.elapsed ?? Duration.zero;
    final levels = List<double>.of(state.recordLevels);
    final replyToEventId = state.replyTo?.id;
    _recordWatch = null;
    if (!isClosed) {
      emit(
        state.copyWith(
          isRecording: () => false,
          recordElapsed: () => Duration.zero,
          recordLevels: () => const <double>[],
          recordLocked: () => false,
          replyTo: replyToEventId != null ? () => null : null,
        ),
      );
    }
    if (recorder == null) return;
    try {
      final path = await recorder.stop();
      await recorder.dispose();
      if (path == null || path.isEmpty) throw Exception('Пустая запись');
      if (elapsed.inMilliseconds < _minVoiceMs) {
        await _deleteRecordFile(path);
        if (!isClosed) {
          emit(state.copyWith(errorMessage: () => 'Слишком короткая запись'));
        }
        return;
      }
      final bytes = kIsWeb
          ? (await http.get(Uri.parse(path))).bodyBytes
          : await File(path).readAsBytes();
      await _deleteRecordFile(path);
      await _repository.sendVoice(
        roomId: _roomId,
        bytes: bytes,
        fileName: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
        mimeType: 'audio/x-m4a',
        durationMs: elapsed.inMilliseconds,
        waveform: _waveform(levels),
        inReplyToEventId: replyToEventId,
      );
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('Не удалось отправить голосовое', e, s);
      emit(
        state.copyWith(errorMessage: () => 'Не удалось отправить голосовое'),
      );
    }
  }

  void lockRecording() {
    if (state.recordLocked || isClosed) return;
    if (state.isRecording) {
      emit(state.copyWith(recordLocked: () => true));
    } else {
      _pendingLockGeneration = _recordGeneration;
    }
  }

  Future<void> cancelRecording() async {
    _recordGeneration++;
    if (!state.isRecording && _recorder == null) return;

    inputController.clear();
    final recorder = _recorder;
    _recorder = null;
    _recordTick?.cancel();
    _recordWatch?.stop();
    _recordWatch = null;
    if (!isClosed) {
      emit(
        state.copyWith(
          isRecording: () => false,
          recordElapsed: () => Duration.zero,
          recordLevels: () => const <double>[],
          recordLocked: () => false,
        ),
      );
    }
    try {
      final path = await recorder?.stop();
      await recorder?.dispose();
      if (path != null && path.isNotEmpty) await _deleteRecordFile(path);
    } catch (_) {}
  }

  static List<int> _waveform(List<double> levels) {
    if (levels.isEmpty) return List.filled(_voiceWaveBars, 1);
    final step = levels.length <= _voiceWaveBars
        ? 1.0
        : levels.length / _voiceWaveBars;
    return List.generate(_voiceWaveBars, (i) {
      final index = (i * step).floor().clamp(0, levels.length - 1);
      return (levels[index] * 1024).round().clamp(1, 1024);
    });
  }

  static Future<void> _deleteRecordFile(String path) async {
    if (kIsWeb) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }
}
