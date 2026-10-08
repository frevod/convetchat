import 'dart:async';
import 'dart:io';

import 'package:convetchat/core/di/locator.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:video_player/video_player.dart';

class const VideoPlayerPageAndr({required final Future<File> file, super.key})
    extends StatefulWidget {
  @override
  State<VideoPlayerPageAndr> createState() => _VideoPlayerPageAndrState();
}

class _VideoPlayerPageAndrState() extends State<VideoPlayerPageAndr> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final file = await widget.file;
      if (!mounted) return;
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      await controller.play();
    } catch (e, s) {
      getIt<Talker>().error('[chat] video playback failed', e, s);
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: controller == null
                  ? _error != null
                        ? Column(
                            mainAxisSize: .min,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 40,
                                color: Color(0xFFFFFFFF),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(
                            width: 48,
                            height: 48,
                            child: M3EProgressIndicator.circularWavy(size: 48),
                          )
                  : _VideoBody(controller: controller),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: M3EIconButton(
                icon: const Icon(Icons.close_rounded),
                variant: .tonal,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class const _VideoBody({required final VideoPlayerController controller})
    extends StatefulWidget {
  @override
  State<_VideoBody> createState() => _VideoBodyState();
}

class _VideoBodyState() extends State<_VideoBody> {
  bool _controls = true;
  Timer? _hideTimer;

  VideoPlayerController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTick);
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    final playing = _controller.value.isPlaying;
    if (playing && _controls) {
      _scheduleHide();
    }
    if (!playing && !_controls) {
      _showControls();
    }
  }

  void _showControls() {
    if (!mounted) return;
    setState(() => _controls = true);
    _scheduleHide();
  }

  void _hideControls() {
    if (!mounted) return;
    setState(() => _controls = false);
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) _hideControls();
    });
  }

  void _playPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      _showControls();
    } else {
      _controller.play();
      _scheduleHide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _controls ? _hideControls() : _showControls(),
      child: Stack(
        alignment: .center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio == 0
                ? 16 / 9
                : _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          if (_controls)
            GestureDetector(
              onTap: _playPause,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xB3000000),
                  shape: .circle,
                ),
                padding: const EdgeInsets.all(10),
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller,
                  builder: (_, value, _) => Icon(
                    value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 36,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
          if (_controls)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _SeekBar(controller: _controller),
            ),
        ],
      ),
    );
  }
}

class const _SeekBar({required final VideoPlayerController controller})
    extends StatefulWidget {
  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState() extends State<_SeekBar> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (_, value, _) {
        final total = value.duration.inMilliseconds.toDouble();
        final pos = (_drag ?? value.position.inMilliseconds.toDouble()).clamp(
          0.0,
          total <= 0 ? 1.0 : total,
        );
        return Row(
          children: [
            Text(
              _stamp(value.position),
              style: const TextStyle(fontSize: 12, color: Color(0xFFFFFFFF)),
            ),
            Expanded(
              child: M3ESlider(
                value: total <= 0 ? 0 : pos,
                min: 0,
                max: total <= 0 ? 1 : total,
                onChanged: (v) => setState(() => _drag = v),
                onChangeEnd: (v) {
                  widget.controller.seekTo(Duration(milliseconds: v.round()));
                  setState(() => _drag = null);
                },
              ),
            ),
            Text(
              _stamp(value.duration),
              style: const TextStyle(fontSize: 12, color: Color(0xFFFFFFFF)),
            ),
          ],
        );
      },
    );
  }

  static String _stamp(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
