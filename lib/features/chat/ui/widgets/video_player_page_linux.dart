import 'dart:io';

import 'package:convetchat/core/di/locator.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class const VideoPlayerPageLinux({
  required final Future<File> file,
  super.key,
}) extends StatefulWidget {
  @override
  State<VideoPlayerPageLinux> createState() => _VideoPlayerPageLinuxState();
}

class _VideoPlayerPageLinuxState() extends State<VideoPlayerPageLinux> {
  Player? _player;
  VideoController? _controller;
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
      final player = Player();
      final controller = VideoController(player);
      setState(() {
        _player = player;
        _controller = controller;
      });
      await player.open(Media(file.path));
      await player.play();
    } catch (e, s) {
      getIt<Talker>().error('Видео: не удалось воспроизвести', e, s);
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _openExternal() async {
    try {
      final file = await widget.file;
      await launchUrl(Uri.file(file.path));
    } catch (e, s) {
      getIt<Talker>().error('Видео: не удалось открыть внешне', e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final textTheme = Theme.of(context).textTheme;
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
                                'Не удалось воспроизвести видео',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: const Color(0xFFFFFFFF),
                                ),
                              ),
                              const SizedBox(height: 16),
                              M3EButton.filled(
                                onPressed: _openExternal,
                                child: const Text(
                                  'Открыть во внешнем плеере',
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(
                            width: 48,
                            height: 48,
                            child: M3EProgressIndicator.circularWavy(size: 48),
                          )
                  : Video(
                      controller: controller,
                      controls: MaterialDesktopVideoControls,
                    ),
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
