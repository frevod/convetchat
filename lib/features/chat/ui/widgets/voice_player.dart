import 'dart:async';

import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/features/chat/domain/entities/voice_message.dart';
import 'package:convetchat/features/chat/domain/services/voice_playback_service.dart';
import 'package:convetchat/features/chat/ui/widgets/waveform_bars.dart';
import 'package:material_ui/material_ui.dart';

class const VoicePlayer({
  super.key,
  required final VoiceMessage voice,
  required final Color accent,
  required final Color track,
  required final IconData playIcon,
  required final IconData pauseIcon,
  required final Color iconColor,
  required final Color buttonColor,
  required final Color loadingColor,
}) extends StatefulWidget {
  static const int barCount = 30;

  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState() extends State<VoicePlayer> {
  late final VoicePlaybackService _service;
  late final StreamSubscription<VoicePlaybackState> _sub;
  VoicePlaybackState _state = const VoicePlaybackState();

  @override
  void initState() {
    super.initState();
    _service = getIt<VoicePlaybackService>();
    _state = _service.state;
    _sub = _service.stream.listen((s) {
      if (mounted) setState(() => _state = s);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  bool get _playing => _state.eventId == widget.voice.eventId && _state.playing;

  bool get _loading => _state.eventId == widget.voice.eventId && _state.loading;

  Duration get _position =>
      _state.eventId == widget.voice.eventId ? _state.position : Duration.zero;

  Duration get _duration {
    final eventDuration = widget.voice.duration;
    if (eventDuration > Duration.zero) return eventDuration;
    return _state.eventId == widget.voice.eventId
        ? _state.duration
        : Duration.zero;
  }

  double get _progress {
    final total = _duration.inMilliseconds;
    if (total <= 0) return 0;
    return (_position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  List<double> get _bars {
    final wave = widget.voice.waveform;
    if (wave.isEmpty) return const <double>[];
    return List.generate(VoicePlayer.barCount, (i) {
      final index = (i * wave.length / VoicePlayer.barCount).floor().clamp(
        0,
        wave.length - 1,
      );
      return (wave[index] / 1024).clamp(0.0, 1.0);
    });
  }

  Future<void> _toggle() async {
    if (_loading) return;
    await _service.toggle(widget.voice.eventId, _duration);
  }

  Future<void> _seekTo(double fraction) async =>
      _service.seekTo(widget.voice.eventId, fraction);

  @override
  Widget build(BuildContext context) {
    final showPosition = _playing || _position > Duration.zero
        ? _position
        : _duration;
    return Row(
      mainAxisSize: .min,
      children: [
        GestureDetector(
          behavior: .opaque,
          onTap: _toggle,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: .circular(100),
              color: widget.buttonColor,
            ),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: _loading
                  ? SizedBox(
                      width: 28,
                      height: 28,
                      child: FittedBox(
                        fit: .contain,
                        child: AdaptiveLoadingIndicator(
                          color: widget.loadingColor,
                        ),
                      ),
                    )
                  : Icon(
                      _playing ? widget.pauseIcon : widget.playIcon,
                      size: 28,
                      color: widget.iconColor,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              SizedBox(
                width: 160,
                height: 28,
                child: Builder(
                  builder: (barsContext) => GestureDetector(
                    behavior: .opaque,
                    onTapDown: (details) {
                      final box = barsContext.findRenderObject() as RenderBox?;
                      final width = box?.size.width ?? 1.0;
                      _seekTo(details.localPosition.dx / width);
                    },
                    child: WaveformBars(
                      values: _bars,
                      progress: _progress,
                      playedColor: widget.accent,
                      trackColor: widget.track,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                mediaTimeText(showPosition),
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
