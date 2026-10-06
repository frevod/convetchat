import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/matrix/matrix_call_failure.dart';
import 'package:convetchat/core/storage/media_disk_cache.dart';
import 'package:convetchat/core/storage/storage_quota_store.dart';
import 'package:convetchat/core/utils/image_thumb.dart';
import 'package:convetchat/core/platform_info.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/core/push/push_service.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/domain/entities/chat_send_restriction.dart';
import 'package:convetchat/features/chat/domain/entities/circle_video.dart';
import 'package:convetchat/features/chat/domain/entities/pending_media.dart';
import 'package:convetchat/features/chat/domain/entities/record_mode.dart';
import 'package:convetchat/features/chat/domain/repositories/chat_repository.dart';
import 'package:convetchat/features/chat/domain/services/circle_playback_coordinator.dart';
import 'package:convetchat/features/chat/domain/services/circle_video_service.dart';
import 'package:convetchat/features/chat/domain/services/voice_playback_service.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_state.dart';
import 'package:convetchat/features/encryption/domain/repositories/encryption_repository.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/verification_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart' as matrix;
import 'package:path/path.dart' as path_lib;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:record/record.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

class ChatCubit(
  final ChatRepository _repository, {
  required final String _roomId,
}) extends Cubit<ChatState> with WidgetsBindingObserver {
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
    _pinnedSubscription = _repository.watchPinnedEvents(_roomId).listen((ids) {
      if (isClosed) return;
      emit(state.copyWith(pinnedEventIds: () => ids));
    });
    _voiceCompletedSubscription = getIt<VoicePlaybackService>().completed
        .listen((eventId) {
          if (isClosed) return;
          unawaited(playNextAfter(eventId));
        });
    inputController.addListener(_onInputChanged);
    _wasKeyboardVisible = _keyboardVisibleNow;
    WidgetsBinding.instance.addObserver(this);
    _loadInteractionSettings();
  }

  bool _wasKeyboardVisible = false;

  bool get _keyboardVisibleNow {
    try {
      return WidgetsBinding.instance.platformDispatcher.views.any(
        (v) => v.viewInsets.bottom > 0,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  void didChangeMetrics() {
    final nowVisible = _keyboardVisibleNow;
    if (_wasKeyboardVisible && !nowVisible) {
      try {
        if (inputFocus.hasFocus) inputFocus.unfocus();
      } catch (_) {}
    }
    _wasKeyboardVisible = nowVisible;
  }

  Future<void> _loadInteractionSettings() async {
    try {
      final sendOnEnter = await _repository.isSendOnEnterEnabled();
      final swipe = await _repository.isSwipeToReplyEnabled();
      final quick = await _repository.isQuickReactionEnabled();
      final emoji = await _repository.getQuickReactionEmoji();
      if (isClosed) return;
      emit(
        state.copyWith(
          sendOnEnter: () => sendOnEnter,
          swipeToReplyEnabled: () => swipe,
          quickReactionEnabled: () => quick,
          quickReactionEmoji: () => emoji,
        ),
      );
    } catch (e, s) {
      getIt<Talker>().error('[chat] load input settings failed', e, s);
    }
  }

  Future<void> refreshInteractionSettings() => _loadInteractionSettings();

  late final StreamSubscription<List<ChatMessage>> _subscription;
  late final StreamSubscription<List<({String id, String name})>>
  _typingSubscription;
  late final StreamSubscription<({bool online, DateTime? lastActive})>
  _presenceSubscription;
  late final StreamSubscription<ChatSendRestriction> _restrictionSubscription;
  late final StreamSubscription<List<String>> _pinnedSubscription;
  late final StreamSubscription<String> _voiceCompletedSubscription;

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

  Timer? _circleAutoStop;

  int _circleStopsInFlight = 0;

  bool get _circleStopping => _circleStopsInFlight > 0;

  Future<XFile?> _stopCircleVideo() async {
    _circleStopsInFlight++;
    try {
      return await getIt<CircleVideoService>().stopVideoRecording().timeout(
        const Duration(seconds: 3),
      );
    } catch (_) {
      return null;
    } finally {
      _circleStopsInFlight--;
    }
  }

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
  Future<void> close() async {
    WidgetsBinding.instance.removeObserver(this);
    _recordGeneration++;
    _subscription.cancel();
    _typingSubscription.cancel();
    unawaited(_presenceSubscription.cancel());
    unawaited(_restrictionSubscription.cancel());
    unawaited(_pinnedSubscription.cancel());
    unawaited(_voiceCompletedSubscription.cancel());
    _highlightTimer?.cancel();
    _recordTick?.cancel();
    _circleAutoStop?.cancel();
    _recordTick = null;
    _circleAutoStop = null;
    _recordWatch?.stop();
    _recordWatch = null;
    try {
      final circleFile = await _stopCircleVideo();
      if (circleFile != null && circleFile.path.isNotEmpty) {
        await _deleteRecordFile(circleFile.path);
      }
    } catch (_) {}
    try {
      await getIt<CircleVideoService>().disposePreview();
    } catch (_) {}
    try {
      final voicePath = await _recorder?.stop().timeout(
        const Duration(seconds: 3),
      );
      if (voicePath != null && voicePath.isNotEmpty) {
        await _deleteRecordFile(voicePath);
      }
    } catch (_) {}
    try {
      await _recorder?.dispose();
    } catch (_) {}
    _recorder = null;
    _typingEchoTimer?.cancel();
    if (_typingSent) {
      unawaited(_repository.setTyping(_roomId, false));
    }
    inputController.removeListener(_onInputChanged);
    inputController.dispose();
    inputFocus.dispose();
    await super.close();
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
    final editing = state.editing;
    final pending = List<PendingMedia>.of(state.pendingMedia);
    if (text.isEmpty && pending.isEmpty && editing == null) return;

    if (editing != null) {
      if (text.isEmpty || pending.isNotEmpty) return;
      inputController.clear();
      emit(state.copyWith(editing: () => null));
      try {
        await _repository.editText(
          roomId: _roomId,
          eventId: editing.id,
          text: text,
        );
      } catch (e, s) {
        if (isClosed) return;
        getIt<Talker>().error('[chat] edit message failed', e, s);
        emit(
          state.copyWith(
            errorMessage: () => 'Не удалось изменить. Попробуйте снова',
          ),
        );
      }
      return;
    }

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
        getIt<Talker>().error('[chat] send message failed', e, s);
        emit(
          state.copyWith(
            errorMessage: () => 'Не удалось отправить. Попробуйте снова',
          ),
        );
      }
      return;
    }
    var failed = 0;
    MatrixCallFailure? reason;
    Future<void> sendOne(int index, PendingMedia item) async {
      var attempt = 0;
      while (true) {
        try {
          if (item.isFile) {
            await _repository.sendFile(
              roomId: _roomId,
              filePath: item.filePath,
              fileName: item.fileName,
              size: item.size,
              caption: index == 0 && text.isNotEmpty ? text : null,
              inReplyToEventId: replyToEventId,
            );
          } else {
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
              caption: index == 0 && text.isNotEmpty ? text : null,
              inReplyToEventId: replyToEventId,
            );
          }
          return;
        } on matrix.MatrixException catch (e) {
          final waitMs = e.retryAfterMs;
          if (e.error != matrix.MatrixError.M_LIMIT_EXCEEDED ||
              waitMs == null ||
              attempt >= 2 ||
              isClosed) {
            rethrow;
          }
          attempt++;
          await Future.delayed(Duration(milliseconds: waitMs + 500 * attempt));
        }
      }
    }

    await Future.wait(
      pending.asMap().entries.map((entry) async {
        if (isClosed) return;
        try {
          await sendOne(entry.key, entry.value);
        } catch (e, s) {
          if (isClosed) return;
          failed++;
          if (e is MatrixCallFailure) reason ??= e;
          getIt<Talker>().error(
            '[chat] send media failed${e is MatrixCallFailure ? ': $e' : ''}',
            e,
            s,
          );
        }
      }),
    );
    if (failed > 0 && !isClosed) {
      emit(
        state.copyWith(
          errorMessage: () =>
              reason?.userMessage ??
              'Не отправилось. Нажмите на значок ошибки, чтобы повторить',
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
        getIt<Talker>().error('[chat] prepare media failed', e, s);
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

  static const _videoExtensions = {
    'mp4',
    'mov',
    'mkv',
    'webm',
    '3gp',
    'avi',
    'm4v',
  };

  static const _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
  };

  Future<void> attachLocalFiles(
    List<({String path, String name, int? size})> files,
  ) async {
    if (isClosed || files.isEmpty) return;
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
    for (final entry in files.take(space)) {
      if (isClosed) return;
      try {
        final file = File(entry.path);
        if (!await file.exists()) continue;
        final ext = path_lib
            .extension(entry.name)
            .replaceFirst('.', '')
            .toLowerCase();
        final isVideo = _videoExtensions.contains(ext);
        final isImage = _imageExtensions.contains(ext);
        final isFile = !isVideo && !isImage;
        Uint8List thumb = Uint8List(0);
        int? width;
        int? height;
        int? size = entry.size;
        if (isImage) {
          try {
            final bytes = await file.readAsBytes();
            size ??= bytes.length;
            final small = makeImageThumb(bytes);
            if (small != null) {
              thumb = small.bytes;
              width = small.width;
              height = small.height;
            }
          } catch (_) {}
        } else if (isVideo) {
          try {
            final frame = await FcNativeVideoThumbnail().saveThumbnailToBytes(
              srcFile: file.path,
              width: 320,
              height: 320,
              quality: 75,
            );
            if (frame != null && frame.isNotEmpty) {
              final small = makeImageThumb(frame);
              if (small != null) {
                thumb = small.bytes;
                width = small.width;
                height = small.height;
              }
            }
          } catch (_) {}
        }
        size ??= await file.length().then((v) => v, onError: (_) => 0);
        final side = _thumbSide(width ?? 0, height ?? 0);
        items.add(
          PendingMedia(
            id: '${DateTime.now().microsecondsSinceEpoch}_${entry.path.hashCode}',
            filePath: entry.path,
            fileName: entry.name,
            isVideo: isVideo,
            thumbBytes: thumb,
            width: width,
            height: height,
            thumbWidth: side.$1,
            thumbHeight: side.$2,
            isFile: isFile,
            size: size,
          ),
        );
      } catch (e, s) {
        getIt<Talker>().error('[chat] prepare file failed', e, s);
      }
    }
    if (isClosed || items.isEmpty) return;
    emit(
      state.copyWith(
        pendingMedia: () => [...state.pendingMedia, ...items],
        errorMessage: files.length > space
            ? () => 'Максимум $_maxPendingMedia файлов за раз'
            : null,
      ),
    );
  }

  Future<void> pickFiles() async {
    if (isClosed) return;
    try {
      final picked = await FilePicker.pickFiles();
      if (isClosed) return;
      final files = picked
          .where((f) => f.path != null && f.path!.isNotEmpty)
          .map((f) => (path: f.path!, name: f.name, size: f.lengthSync()))
          .toList(growable: false);
      if (files.isEmpty) return;
      await attachLocalFiles(files);
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[chat] pick files failed', e, s);
      emit(state.copyWith(errorMessage: () => 'Не удалось выбрать файлы'));
    }
  }

  Future<void> openFileMessage(ChatMessage message) async {
    final media = message.media;
    if (media == null || media.kind != .file || isClosed) return;
    try {
      final bytes = await mediaBytes(eventId: message.id, thumb: false);
      if (isClosed) return;
      if (bytes.isEmpty) throw Exception('Пустой файл');
      final dir = await getTemporaryDirectory();
      final safeName = _safeFileName(media.fileName ?? message.body);
      final file = File('${dir.path}${Platform.pathSeparator}$safeName');
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != .done && !isClosed) {
        emit(
          state.copyWith(
            errorMessage: () => 'Не удалось открыть файл: ${result.message}',
          ),
        );
      }
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[chat] open file failed', e, s);
      emit(state.copyWith(errorMessage: () => 'Не удалось открыть файл'));
    }
  }

  static String _safeFileName(String name) {
    final trimmed = name.trim();
    final base = trimmed.isEmpty ? 'file' : trimmed;
    final safe = base.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return '${DateTime.now().microsecondsSinceEpoch}_$safe';
  }

  Future<void> removePending(String id) async {
    _dropPending(id);
  }

  Future<void> cancelSendMessage(ChatMessage message) async {
    if (!message.isOwn) return;
    if (message.status != .failed && message.status != .sending) return;
    try {
      await _repository.cancelSend(roomId: _roomId, eventId: message.id);
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[chat] cancel send failed', e, s);
      emit(state.copyWith(errorMessage: () => 'Не удалось убрать'));
    }
  }

  Future<void> retrySendMessage(ChatMessage message) async {
    if (!message.isOwn || message.status != .failed || isClosed) return;
    try {
      await _repository.retrySend(roomId: _roomId, eventId: message.id);
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[chat] retry send failed', e, s);
      emit(
        state.copyWith(
          errorMessage: () => 'Не удалось отправить. Попробуйте снова',
        ),
      );
    }
  }

  Future<void> playNextAfter(String eventId) async {
    if (isClosed) return;
    try {
      if (!await _repository.isAutoplayEnabled()) return;
      final voiceOn = await _repository.isVoiceAutoplayEnabled();
      final videoOn = await _repository.isVideoAutoplayEnabled();
      if (!voiceOn && !videoOn) return;
      final voiceService = getIt<VoicePlaybackService>();
      final current = voiceService.state;
      if (current.eventId == eventId && current.playing) return;
      final messages = state.messages;
      final index = messages.indexWhere((m) => m.id == eventId);
      if (index < 0 || isClosed) return;
      final inlineCircles = !getIt<PlatformStyle>().isCupertino;
      for (var j = index - 1; j >= 0; j--) {
        if (isClosed) return;
        final candidate = messages[j];
        if (candidate.isDeleted ||
            candidate.isUndecryptable ||
            candidate.isState) {
          continue;
        }
        if (candidate.status == .sending || candidate.status == .failed) {
          continue;
        }
        final voice = candidate.voice;
        if (voice != null && voiceOn) {
          await voiceService.toggle(voice.eventId, voice.duration);
          return;
        }
        final media = candidate.media;
        if (media != null &&
            media.kind == .video &&
            media.isCircle &&
            videoOn &&
            inlineCircles) {
          getIt<CirclePlaybackCoordinator>().requestAutoplay(candidate.id);
          return;
        }
      }
    } catch (e, s) {
      getIt<Talker>().error('[chat] autoplay next failed', e, s);
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

  Uint8List? cachedMediaBytes({required String eventId, bool thumb = true}) =>
      _mediaCache['$eventId:${thumb ? 't' : 'f'}'];

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
    if (!isClosed && thumb) {
      if (_mediaCache.length >= _mediaCacheCap) {
        _mediaCache.remove(_mediaCache.keys.first);
      }
      _mediaCache[key] = bytes;
    }
    return bytes;
  }

  Future<bool> isFullCached(String eventId) async {
    try {
      return await _repository.isMediaCached(
        roomId: _roomId,
        eventId: eventId,
        thumb: false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<File> videoFile({
    required String eventId,
    String? fileName,
    String? mimeType,
  }) async {
    final bytes = await mediaBytes(eventId: eventId, thumb: false);
    if (bytes.isEmpty) throw Exception('Файл видео пустой');
    final dir = await getIt<MediaDiskCache>().directory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}${_videoFileName(eventId, fileName, mimeType)}',
    );
    if (!await file.exists() || await file.length() != bytes.length) {
      await file.writeAsBytes(bytes, flush: true);
      try {
        final quota = await getIt<StorageQuotaStore>().getMaxBytes();
        await getIt<MediaDiskCache>().enforceQuota(quota);
      } catch (_) {}
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
      getIt<Talker>().warning('[push] dismiss notification failed', e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: () => true));
    try {
      await _repository.loadMore(_roomId);
    } catch (e, s) {
      getIt<Talker>().error('[chat] load history failed', e, s);
    } finally {
      if (!isClosed) emit(state.copyWith(isLoadingMore: () => false));
    }
  }

  Future<void> verifyPartner(BuildContext context) async {
    try {
      final verification = await _repository.verifyDirectPartner(_roomId);
      if (!context.mounted) return;
      final verified = await VerificationSheet.show(context, verification);
      if (verified && !isClosed) {
        try {
          await getIt<EncryptionRepository>().requestMissingSessions();
        } catch (e, s) {
          getIt<Talker>().error('[e2ee] request keys failed', e, s);
        }
      }
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[chat] start verification failed', e, s);
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

  Future<void> copyMessage(ChatMessage message) async {
    if (message.body.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: message.body));
  }

  Future<void> editMessage(ChatMessage message) async {
    if (!message.isOwn || message.isState) return;
    if (!message.isBody) return;
    if (message.status == MessageStatus.sending) return;

    inputController.text = message.body;
    inputController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: message.body.length,
    );
    emit(state.copyWith(editing: () => message, replyTo: () => null));
    inputFocus.requestFocus();
  }

  void cancelEdit() {
    if (state.editing == null) return;
    inputController.clear();
    emit(state.copyWith(editing: () => null));
  }

  Future<void> toggleReaction(ChatMessage message, String emoji) async {
    if (!message.canReact || isClosed) return;
    if (emoji.isEmpty) return;
    try {
      await _repository.toggleReaction(
        roomId: _roomId,
        eventId: message.id,
        emoji: emoji,
      );
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[chat] toggle reaction failed', e, s);
      emit(state.copyWith(errorMessage: () => 'Не удалось поставить реакцию'));
    }
  }

  Future<void> toggleHeart(ChatMessage message) => toggleQuickReaction(message);

  Future<void> toggleQuickReaction(ChatMessage message) {
    if (!state.quickReactionEnabled) return Future.value();
    final emoji = state.quickReactionEmoji.isEmpty
        ? '❤️'
        : state.quickReactionEmoji;
    return toggleReaction(message, emoji);
  }

  Future<void> deleteMessage(ChatMessage message) async {
    if (message.isState) return;
    if (message.isDeleted) return;
    if (message.isUndecryptable) {
      await _deleteUndecryptable(message);
      return;
    }
    if (!message.isOwn) {
      emit(
        state.copyWith(
          errorMessage: () => 'Можно удалять только свои сообщения',
        ),
      );
      return;
    }
    try {
      await _repository.redactMessage(roomId: _roomId, eventId: message.id);
    } catch (e, s) {
      getIt<Talker>().error('[chat] delete message failed', e, s);
      emit(state.copyWith(errorMessage: () => 'Не удалось удалить сообщение'));
    }
  }

  Future<void> _deleteUndecryptable(ChatMessage message) async {
    if (message.isOwn) {
      try {
        await _repository.redactMessage(roomId: _roomId, eventId: message.id);
      } catch (e, s) {
        if (isClosed) return;
        getIt<Talker>().error('[chat] delete message failed', e, s);
        emit(
          state.copyWith(errorMessage: () => 'Не удалось удалить сообщение'),
        );
        return;
      }
    }
    try {
      await _repository.hideEvent(roomId: _roomId, eventId: message.id);
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(errorMessage: () => 'Не удалось удалить сообщение'));
      return;
    }
    if (isClosed) return;
    emit(
      state.copyWith(
        messages: () =>
            state.messages.where((m) => m.id != message.id).toList(),
      ),
    );
  }

  Future<void> deleteSelected() async {
    final ids = state.selectedEventIds;
    if (ids.isEmpty) return;
    final selected = state.messages
        .where((m) => ids.contains(m.id) && !m.isState)
        .toList(growable: false);
    clearSelection();
    final undecryptable = selected
        .where((m) => m.isUndecryptable)
        .toList(growable: false);
    final mine = selected
        .where((m) => !m.isDeleted && !m.isUndecryptable && m.isOwn)
        .map((m) => m.id)
        .toList(growable: false);
    if (undecryptable.isEmpty && mine.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: () => 'Можно удалять только свои сообщения',
        ),
      );
      return;
    }
    for (final message in undecryptable) {
      await _deleteUndecryptable(message);
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

  Future<void> pinMessage(ChatMessage message) async {
    if (message.isState || message.status == MessageStatus.sending) return;
    final previous = state.pinnedEventIds;
    emit(state.copyWith(pinnedEventIds: () => [message.id]));
    try {
      await _repository.pinMessage(roomId: _roomId, eventId: message.id);
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[chat] pin message failed', e, s);
      emit(
        state.copyWith(
          pinnedEventIds: () => previous,
          errorMessage: () => 'Не удалось закрепить сообщение',
        ),
      );
    }
  }

  Future<void> pinSelected() async {
    final ids = state.selectedEventIds;
    if (ids.length != 1) return;
    final id = ids.single;
    final message = state.messages
        .where((m) => m.id == id)
        .cast<ChatMessage?>();
    final target = message.isEmpty ? null : message.first;
    if (target == null) return;
    clearSelection();
    await pinMessage(target);
  }

  Future<void> unpinMessage() async {
    if (state.pinnedEventIds.isEmpty) return;
    final previous = state.pinnedEventIds;
    emit(state.copyWith(pinnedEventIds: () => const <String>[]));
    try {
      await _repository.unpinMessage(roomId: _roomId);
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[chat] unpin message failed', e, s);
      emit(
        state.copyWith(
          pinnedEventIds: () => previous,
          errorMessage: () => 'Не удалось открепить сообщение',
        ),
      );
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

  Future<void> toggleRecordMode() async {
    if (state.isRecording || _circleStopping) return;
    if (!PlatformInfos.supportsCamera) return;
    if (state.recordMode == .circle) {
      emit(state.copyWith(recordMode: () => RecordMode.voice));
      unawaited(getIt<CircleVideoService>().disposePreview());
      return;
    }
    emit(state.copyWith(recordMode: () => RecordMode.circle));
  }

  Future<void> _ensureCirclePreview() async {
    if (state.recordMode != .circle || isClosed) return;
    if (!PlatformInfos.supportsCamera) {
      emit(state.copyWith(errorMessage: () => 'Кружки недоступны на десктопе'));
      return;
    }
    try {
      final status = await Permission.camera.request();
      if (isClosed || state.recordMode != .circle) return;
      if (!status.isGranted) {
        emit(state.copyWith(errorMessage: () => 'Нет доступа к камере'));
        return;
      }
      final quality = await _repository.getCircleVideoQuality();
      final controller = await getIt<CircleVideoService>().ensureFrontPreview(
        preset: CircleVideoService.qualityPreset(quality),
      );
      if (isClosed || state.recordMode != .circle || !state.isRecording) {
        await getIt<CircleVideoService>().disposePreview();
        return;
      }
      if (controller == null) {
        emit(state.copyWith(errorMessage: () => 'Передняя камера недоступна'));
      }
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[chat] start camera preview failed', e, s);
      emit(state.copyWith(errorMessage: () => 'Не удалось включить камеру'));
    }
  }

  Future<void> startRecording() {
    if (state.recordMode == .circle) return startCircleRecording();
    return _startVoiceRecording();
  }

  Future<void> startCircleRecording() async {
    if (state.isRecording) return;
    final generation = ++_recordGeneration;
    final pendingLock = _pendingLockGeneration == generation;
    if (pendingLock) _pendingLockGeneration = null;
    if (!isClosed) {
      emit(
        state.copyWith(
          isRecording: () => true,
          recordElapsed: () => Duration.zero,
          recordLevels: () => const <double>[],
          recordLocked: () => pendingLock,
        ),
      );
    }
    var waits = 0;
    while (_circleStopping &&
        waits < 40 &&
        generation == _recordGeneration &&
        !isClosed) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      waits++;
    }
    if (isClosed || generation != _recordGeneration) return;
    try {
      var controller = getIt<CircleVideoService>().controller;
      if (controller == null || !controller.value.isInitialized) {
        await _ensureCirclePreview();
        if (isClosed || generation != _recordGeneration) return;
        controller = getIt<CircleVideoService>().controller;
      }
      if (controller == null || !controller.value.isInitialized) {
        if (!isClosed && generation == _recordGeneration) {
          _resetRecordFlags();
        }
        return;
      }
      if (!isClosed && generation == _recordGeneration) {
        emit(state.copyWith(circleReady: () => true));
      }
      await getIt<CircleVideoService>().startVideoRecording();
      if (generation != _recordGeneration || isClosed) {
        await _stopCircleVideo();
        return;
      }
      _recordWatch = Stopwatch()..start();
      _recordTick?.cancel();
      _recordTick = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _pollCircle(),
      );
      _circleAutoStop?.cancel();
      _circleAutoStop = Timer(
        const Duration(milliseconds: maxCircleVideoMs),
        () {
          if (!isClosed && state.isRecording && state.recordMode == .circle) {
            unawaited(stopCircleAndSend());
          }
        },
      );
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[chat] start circle recording failed', e, s);
      if (generation == _recordGeneration) _resetRecordFlags();
      emit(state.copyWith(errorMessage: () => 'Не удалось начать запись'));
    }
  }

  void _resetRecordFlags() {
    if (isClosed) return;
    emit(
      state.copyWith(
        isRecording: () => false,
        recordElapsed: () => Duration.zero,
        recordLevels: () => const <double>[],
        recordLocked: () => false,
        circleReady: () => false,
      ),
    );
  }

  void _pollCircle() {
    final watch = _recordWatch;
    if (isClosed || !state.isRecording || state.recordMode != .circle) return;
    if (watch == null) {
      emit(
        state.copyWith(
          isRecording: () => false,
          recordElapsed: () => Duration.zero,
          recordLevels: () => const <double>[],
          recordLocked: () => false,
          circleReady: () => false,
        ),
      );
      return;
    }
    final t = watch.elapsed.inMilliseconds / 1000.0;
    final level = 0.45 + 0.35 * (0.5 + 0.5 * math.sin(t * 6.0));
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
  }

  Future<void> _startVoiceRecording() async {
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
      getIt<Talker>().error('[chat] start voice recording failed', e, s);
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

  Future<void> stopRecordingAndSend() {
    if (state.recordMode == .circle) return stopCircleAndSend();
    return _stopVoiceAndSend();
  }

  Future<void> stopCircleAndSend() async {
    _recordGeneration++;
    if (!state.isRecording || state.recordMode != .circle) return;

    inputController.clear();
    _recordTick?.cancel();
    _circleAutoStop?.cancel();
    _recordWatch?.stop();
    final elapsed = _recordWatch?.elapsed ?? Duration.zero;
    final replyToEventId = state.replyTo?.id;
    _recordWatch = null;
    if (!isClosed) {
      emit(
        state.copyWith(
          isRecording: () => false,
          recordElapsed: () => Duration.zero,
          recordLevels: () => const <double>[],
          recordLocked: () => false,
          circleReady: () => false,
          replyTo: replyToEventId != null ? () => null : null,
        ),
      );
    }
    try {
      final file = await _stopCircleVideo();
      await getIt<CircleVideoService>().disposePreview();
      if (file == null || file.path.isEmpty) {
        if (elapsed.inMilliseconds < minCircleVideoMs) {
          if (!isClosed) {
            emit(state.copyWith(errorMessage: () => 'Слишком короткий кружок'));
          }
          return;
        }
        throw Exception('Пустая запись');
      }
      if (elapsed.inMilliseconds < minCircleVideoMs) {
        await _deleteRecordFile(file.path);
        if (!isClosed) {
          emit(state.copyWith(errorMessage: () => 'Слишком короткий кружок'));
        }
        return;
      }
      try {
        final thumb = await _circleThumb(file.path);
        await _repository.sendMedia(
          roomId: _roomId,
          filePath: file.path,
          fileName: 'circle_${DateTime.now().millisecondsSinceEpoch}.mp4',
          isVideo: true,
          isCircle: true,
          durationMs: elapsed.inMilliseconds,
          thumbBytes: thumb?.bytes,
          thumbWidth: thumb?.width,
          thumbHeight: thumb?.height,
          inReplyToEventId: replyToEventId,
        );
      } finally {
        await _deleteRecordFile(file.path);
      }
    } catch (e, s) {
      if (isClosed) return;
      getIt<Talker>().error('[chat] send circle video failed', e, s);
      emit(state.copyWith(errorMessage: () => 'Не удалось отправить кружок'));
    }
  }

  static Future<({Uint8List bytes, int width, int height})?> _circleThumb(
    String path,
  ) async {
    try {
      final frame = await FcNativeVideoThumbnail().saveThumbnailToBytes(
        srcFile: path,
        width: 320,
        height: 320,
        quality: 75,
      );
      if (frame == null || frame.isEmpty) return null;
      return makeImageThumb(frame);
    } catch (_) {
      return null;
    }
  }

  Future<void> _stopVoiceAndSend() async {
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
      getIt<Talker>().error('[chat] send voice message failed', e, s);
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

  Future<void> cancelRecording() {
    if (state.recordMode == .circle) return cancelCircleRecording();
    return _cancelVoiceRecording();
  }

  Future<void> cancelCircleRecording() async {
    _recordGeneration++;
    final service = getIt<CircleVideoService>();
    if (!state.isRecording && !service.isVideoRecording) return;

    inputController.clear();
    _recordTick?.cancel();
    _circleAutoStop?.cancel();
    _recordWatch?.stop();
    _recordWatch = null;
    if (!isClosed) {
      emit(
        state.copyWith(
          isRecording: () => false,
          recordElapsed: () => Duration.zero,
          recordLevels: () => const <double>[],
          recordLocked: () => false,
          circleReady: () => false,
        ),
      );
    }
    try {
      final file = await _stopCircleVideo();
      await getIt<CircleVideoService>().disposePreview();
      if (file != null && file.path.isNotEmpty) {
        await _deleteRecordFile(file.path);
      }
    } catch (_) {}
  }

  Future<void> _cancelVoiceRecording() async {
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
