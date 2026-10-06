import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chat/domain/repositories/chat_repository.dart';
import 'package:just_audio/just_audio.dart';
import 'package:talker_flutter/talker_flutter.dart';

class const VoicePlaybackState({
  final String? eventId,
  final bool playing = false,
  final Duration position = Duration.zero,
  final Duration duration = Duration.zero,
  final bool loading = false,
}) {
  double get progress {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }
}

class VoicePlaybackService() {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration?>? _durationSub;

  String? _currentEventId;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _loading = false;
  int _loadToken = 0;

  final _controller = StreamController<VoicePlaybackState>.broadcast();
  final _completedController = StreamController<String>.broadcast();

  this {
    _subscribe(_player);
  }

  Stream<VoicePlaybackState> get stream => _controller.stream;

  Stream<String> get completed => _completedController.stream;

  VoicePlaybackState get state => VoicePlaybackState(
    eventId: _currentEventId,
    playing: _playing,
    position: _position,
    duration: _duration,
    loading: _loading,
  );

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  Future<void> toggle(String eventId, Duration voiceDuration) async {
    if (_loading) return;

    if (_currentEventId == eventId && _playing) {
      await _player.pause();
      return;
    }

    if (_currentEventId == eventId && !_playing) {
      try {
        if (_duration > Duration.zero && _position >= _duration) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      } catch (e, s) {
        getIt<Talker>().error('[voice] playback failed', e, s);
      }
      return;
    }

    final token = ++_loadToken;
    _currentEventId = eventId;
    _duration = voiceDuration;
    _position = Duration.zero;
    _playing = false;
    _loading = true;
    _emit();

    try {
      final file = await getIt<ChatRepository>().voiceFile(eventId);
      if (token != _loadToken) return;
      await _player.stop();
      await _player.setFilePath(file.path);
      if (token != _loadToken) return;
    } catch (e, s) {
      if (token != _loadToken) return;
      getIt<Talker>().error('[voice] load voice file failed', e, s);
      _currentEventId = null;
      _loading = false;
      _playing = false;
      _position = Duration.zero;
      _emit();
      return;
    }

    _loading = false;
    _emit();

    try {
      await _player.play();
    } catch (e, s) {
      if (token != _loadToken) return;
      getIt<Talker>().error('[voice] playback failed', e, s);
    }
  }

  Future<void> seekTo(String eventId, double fraction) async {
    if (eventId != _currentEventId) return;
    if (_duration <= Duration.zero) return;
    await _player.seek(_duration * fraction.clamp(0.0, 1.0));
  }

  void _subscribe(AudioPlayer player) {
    _positionSub = player.positionStream.listen((position) {
      _position = position;
      _emit();
    });
    _durationSub = player.durationStream.listen((duration) {
      if (duration != null && duration > Duration.zero) {
        _duration = duration;
        _emit();
      }
    });
    _stateSub = player.playerStateStream.listen((playerState) async {
      if (playerState.processingState == ProcessingState.completed) {
        final finishedId = _currentEventId;
        await player.pause();
        await player.seek(Duration.zero);
        _playing = false;
        _position = Duration.zero;
        _emit();
        if (finishedId != null && !_completedController.isClosed) {
          _completedController.add(finishedId);
        }
        return;
      }
      _playing = playerState.playing;
      _emit();
    });
  }

  void dispose() {
    _loadToken++;
    _positionSub?.cancel();
    _stateSub?.cancel();
    _durationSub?.cancel();
    unawaited(_player.dispose());
    _controller.close();
    _completedController.close();
  }
}
