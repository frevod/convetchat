import 'dart:async';
import 'dart:ui';

import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_info.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/formatted_text.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/domain/services/circle_playback_coordinator.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/file_message_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/video_player_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:video_player/video_player.dart';

class const MediaMessageAndr({
  required final ChatMessage message,
  final bool previewOnly = false,
  final bool highlighted = false,
  final VoidCallback? onLinkTap,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final media = message.media!;
    if (media.kind == .file) {
      return FileMessageAndr(message: message);
    }
    if (media.kind == .video && media.isCircle) {
      return _CircleTile(
        message: message,
        previewOnly: previewOnly,
        highlighted: highlighted,
      );
    }
    if (media.kind == .video) {
      return _VideoTile(
        message: message,
        previewOnly: previewOnly,
        onLinkTap: onLinkTap,
      );
    }
    return _PhotoTile(
      message: message,
      previewOnly: previewOnly,
      onLinkTap: onLinkTap,
    );
  }
}

class const _CircleTile({
  required final ChatMessage message,
  required final bool previewOnly,
  final bool highlighted = false,
}) extends StatefulWidget {
  static const _collapsed = 168.0;
  static const _expanded = 260.0;

  @override
  State<_CircleTile> createState() => _CircleTileState();
}

class _CircleTileState() extends State<_CircleTile> {
  Future<Uint8List>? _thumb;
  VideoPlayerController? _video;
  Player? _mkPlayer;
  VideoController? _mkController;
  StreamSubscription<bool>? _mkCompleted;
  bool _playing = false;
  bool _busy = false;
  bool _fullReady = false;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    if (widget.message.media?.hasThumb == true) {
      _thumb = _loadThumb();
    }
    getIt<CirclePlaybackCoordinator>().addListener(_onCoordinator);
    unawaited(_initCache());
  }

  Future<void> _initCache() async {
    var ready = widget.message.isOwn;
    if (!ready) {
      try {
        ready = await context.read<ChatCubit>().isFullCached(widget.message.id);
      } catch (_) {
        ready = false;
      }
    }
    if (!mounted) return;
    setState(() => _fullReady = ready);
    if (ready &&
        getIt<CirclePlaybackCoordinator>().consumeAutoplay(widget.message.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_toggle());
      });
    }
  }

  @override
  void didUpdateWidget(_CircleTile old) {
    super.didUpdateWidget(old);
    if (_thumb == null &&
        widget.message.media?.hasThumb == true &&
        old.message.media?.hasThumb != true) {
      _thumb = _loadThumb();
    }
  }

  Future<Uint8List> _loadThumb() => context.read<ChatCubit>().mediaBytes(
    eventId: widget.message.id,
    thumb: true,
  );

  @override
  void dispose() {
    getIt<CirclePlaybackCoordinator>()
      ..removeListener(_onCoordinator)
      ..playStopped(widget.message.id);
    _video?.dispose();
    unawaited(_mkCompleted?.cancel());
    unawaited(_mkPlayer?.dispose());
    super.dispose();
  }

  void _onCoordinator() {
    final coordinator = getIt<CirclePlaybackCoordinator>();
    if (coordinator.consumeAutoplay(widget.message.id)) {
      if (!_playing && mounted) unawaited(_toggle());
      return;
    }
    if (!_playing) return;
    if (coordinator.activeId == widget.message.id) {
      return;
    }
    _playing = false;
    unawaited(_video?.pause());
    unawaited(_mkPlayer?.pause());
    if (mounted) setState(() {});
  }

  void _onFinished() {
    _playing = false;
    getIt<CirclePlaybackCoordinator>().playStopped(widget.message.id);
    if (mounted) setState(() {});
    if (mounted) {
      unawaited(context.read<ChatCubit>().playNextAfter(widget.message.id));
    }
  }

  void _onVideoProgress() {
    final controller = _video;
    if (controller == null || !_playing) return;
    final value = controller.value;
    if (!value.isInitialized || value.duration <= Duration.zero) return;
    if (value.position >= value.duration && !value.isPlaying) {
      unawaited(controller.pause());
      unawaited(controller.seekTo(Duration.zero));
      _onFinished();
    }
  }

  bool get _sending => widget.message.status == .sending;

  Future<void> _toggle() async {
    if (widget.previewOnly || _sending || _busy || _downloading) return;
    if (!_fullReady) {
      await _download();
      return;
    }
    if (PlatformInfos.isLinux) return _toggleLinux();
    if (_playing) {
      _playing = false;
      getIt<CirclePlaybackCoordinator>().playStopped(widget.message.id);
      await _video?.pause();
      if (mounted) setState(() {});
      return;
    }
    if (_video == null) {
      setState(() => _busy = true);
      try {
        final cubit = context.read<ChatCubit>();
        final file = await cubit.videoFile(
          eventId: widget.message.id,
          fileName: widget.message.media?.fileName,
          mimeType: widget.message.media?.mimeType,
        );
        final controller = VideoPlayerController.file(file);
        await controller.initialize();
        await controller.setLooping(false);
        if (!mounted) {
          await controller.dispose();
          return;
        }
        controller.addListener(_onVideoProgress);
        _video = controller;
      } catch (e, s) {
        getIt<Talker>().error('[chat] video message playback failed', e, s);
        if (mounted) setState(() => _busy = false);
        return;
      }
      if (mounted) setState(() => _busy = false);
    }
    try {
      await _video?.play();
    } catch (e, s) {
      getIt<Talker>().error('[chat] video message playback failed', e, s);
      return;
    }
    getIt<CirclePlaybackCoordinator>().playStarted(widget.message.id);
    if (mounted) setState(() => _playing = true);
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      await context.read<ChatCubit>().videoFile(
        eventId: widget.message.id,
        fileName: widget.message.media?.fileName,
        mimeType: widget.message.media?.mimeType,
      );
      if (!mounted) return;
      setState(() => _fullReady = true);
    } catch (e, s) {
      getIt<Talker>().error('[chat] video message download failed', e, s);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _toggleLinux() async {
    if (_playing) {
      _playing = false;
      getIt<CirclePlaybackCoordinator>().playStopped(widget.message.id);
      await _mkPlayer?.pause();
      if (mounted) setState(() {});
      return;
    }
    if (_mkController == null) {
      setState(() => _busy = true);
      try {
        final cubit = context.read<ChatCubit>();
        final file = await cubit.videoFile(
          eventId: widget.message.id,
          fileName: widget.message.media?.fileName,
          mimeType: widget.message.media?.mimeType,
        );
        final player = Player();
        final controller = VideoController(player);
        if (!mounted) {
          await player.dispose();
          return;
        }
        _mkPlayer = player;
        _mkController = controller;
        await _mkCompleted?.cancel();
        _mkCompleted = player.stream.completed.listen((completed) {
          if (!completed) return;
          unawaited(player.pause());
          unawaited(player.seek(Duration.zero));
          _onFinished();
        });
        await player.open(Media(file.path));
      } catch (e, s) {
        getIt<Talker>().error('[chat] video message playback failed', e, s);
        if (mounted) setState(() => _busy = false);
        return;
      }
      if (mounted) setState(() => _busy = false);
    }
    try {
      await _mkPlayer?.seek(Duration.zero);
      await _mkPlayer?.play();
    } catch (e, s) {
      getIt<Talker>().error('[chat] video message playback failed', e, s);
      return;
    }
    getIt<CirclePlaybackCoordinator>().playStarted(widget.message.id);
    if (mounted) setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.previewOnly;
    final playing = _playing && (_video != null || _mkController != null);
    final size = playing ? _CircleTile._expanded : _CircleTile._collapsed;
    return GestureDetector(
      onTap: preview || _sending ? null : _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: widget.highlighted
            ? BoxDecoration(
                shape: .circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.5,
                ),
              )
            : null,
        child: ClipOval(
          child: Stack(
            fit: .expand,
            children: [
              _ThumbBody(thumb: _thumb, blurred: !_fullReady && !playing),
              if (playing && _video != null)
                _CircleVideoFill(controller: _video!, size: size)
              else if (playing && _mkController != null)
                SizedBox(
                  width: size,
                  height: size,
                  child: Video(
                    controller: _mkController!,
                    fit: BoxFit.cover,
                    controls: NoVideoControls,
                  ),
                ),
              if (_busy || _downloading || _sending)
                const Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: M3EProgressIndicator.circularWavy(size: 36),
                  ),
                )
              else if (!_fullReady)
                const Center(
                  child: Icon(
                    Icons.download_rounded,
                    size: 44,
                    color: Color(0xFFFFFFFF),
                  ),
                )
              else if (!playing)
                const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 44,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class const _ThumbBody({
  required final Future<Uint8List>? thumb,
  final bool blurred = false,
}) extends StatelessWidget {
  static const _fallback = ColoredBox(color: Color(0xFF000000));

  @override
  Widget build(BuildContext context) {
    final thumb = this.thumb;
    if (thumb == null) return _fallback;
    return FutureBuilder<Uint8List>(
      future: thumb,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) return _fallback;
        final image = Image.memory(
          bytes,
          fit: .cover,
          errorBuilder: (_, _, _) => _fallback,
        );
        if (!blurred) return image;
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: image,
        );
      },
    );
  }
}

class const _CircleVideoFill({
  required final VideoPlayerController controller,
  required final double size,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final raw = controller.value.aspectRatio;
    final ar = raw <= 0 ? 1.0 : raw;
    return FittedBox(
      fit: .cover,
      clipBehavior: .hardEdge,
      child: SizedBox(
        width: size,
        height: size / ar,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class const _PhotoTile({
  required final ChatMessage message,
  required final bool previewOnly,
  final VoidCallback? onLinkTap,
}) extends StatefulWidget {
  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState() extends State<_PhotoTile> {
  late Future<Uint8List> _thumb;
  bool _fullReady = false;
  bool _downloading = false;
  Uint8List? _fullBytes;

  @override
  void initState() {
    super.initState();
    _thumb = _load();
    unawaited(_initCache());
  }

  Future<void> _initCache() async {
    if (widget.previewOnly || widget.message.isOwn) {
      if (!mounted) return;
      setState(() => _fullReady = true);
      return;
    }
    try {
      final ready = await context.read<ChatCubit>().isFullCached(
        widget.message.id,
      );
      if (!mounted) return;
      if (!ready) return;
      final full = await context.read<ChatCubit>().mediaBytes(
        eventId: widget.message.id,
        thumb: false,
      );
      if (!mounted) return;
      setState(() {
        _fullBytes = full;
        _fullReady = true;
      });
    } catch (_) {}
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final full = await context.read<ChatCubit>().mediaBytes(
        eventId: widget.message.id,
        thumb: false,
      );
      if (!mounted) return;
      setState(() {
        _fullBytes = full;
        _fullReady = true;
      });
    } catch (e, s) {
      getIt<Talker>().error('[chat] photo download failed', e, s);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<Uint8List> _load() {
    final cubit = context.read<ChatCubit>();
    if (widget.previewOnly) {
      final cached = cubit.cachedMediaBytes(eventId: widget.message.id);
      if (cached != null) return SynchronousFuture(cached);
    }
    return cubit.mediaBytes(eventId: widget.message.id, thumb: true);
  }

  void _retry() {
    setState(() {
      _thumb = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.previewOnly;
    return FutureBuilder<Uint8List>(
      future: _thumb,
      builder: (context, snapshot) {
        final storedFull = _fullBytes;
        final full = _fullReady ? storedFull : null;
        final bytes = full ?? snapshot.data;
        if (bytes != null) {
          final center = _downloading
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: M3EProgressIndicator.circularWavy(size: 40),
                )
              : _fullReady
              ? null
              : M3EIconButton(
                  icon: const Icon(Icons.download_rounded),
                  variant: .tonal,
                  onPressed: preview ? null : _download,
                );
          final image = Image.memory(bytes, fit: .cover);
          return _MediaFrame(
            message: widget.message,
            onLinkTap: widget.onLinkTap,
            interactive: !preview,
            center: center,
            onTap: preview
                ? null
                : _fullReady
                ? () => _openViewer(context, full ?? bytes)
                : _download,
            child: full != null
                ? image
                : ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: image,
                  ),
          );
        }
        if (snapshot.hasError) {
          return _MediaFrame(
            message: widget.message,
            onLinkTap: widget.onLinkTap,
            interactive: !preview,
            center: M3EIconButton(
              icon: const Icon(Icons.refresh_rounded),
              variant: .tonal,
              onPressed: preview ? null : _retry,
            ),
            child: const SizedBox.expand(),
          );
        }
        return _MediaFrame(
          message: widget.message,
          onLinkTap: widget.onLinkTap,
          interactive: !preview,
          center: preview
              ? null
              : const SizedBox(
                  width: 40,
                  height: 40,
                  child: M3EProgressIndicator.circularWavy(size: 40),
                ),
          child: const SizedBox.expand(),
        );
      },
    );
  }

  void _openViewer(BuildContext context, Uint8List thumb) {
    final cubit = context.read<ChatCubit>();
    final full = cubit.mediaBytes(eventId: widget.message.id, thumb: false);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PhotoViewerPage(full: full, thumb: thumb),
      ),
    );
  }
}

class const _VideoTile({
  required final ChatMessage message,
  required final bool previewOnly,
  final VoidCallback? onLinkTap,
}) extends StatefulWidget {
  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState() extends State<_VideoTile> {
  late Future<Uint8List> _thumb;
  bool _fullReady = false;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _thumb = _load();
    unawaited(_initCache());
  }

  Future<void> _initCache() async {
    if (widget.previewOnly || widget.message.isOwn) {
      if (!mounted) return;
      setState(() => _fullReady = true);
      return;
    }
    try {
      final ready = await context.read<ChatCubit>().isFullCached(
        widget.message.id,
      );
      if (!mounted) return;
      setState(() => _fullReady = ready);
    } catch (_) {}
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      await context.read<ChatCubit>().videoFile(
        eventId: widget.message.id,
        fileName: widget.message.media?.fileName,
        mimeType: widget.message.media?.mimeType,
      );
      if (!mounted) return;
      setState(() => _fullReady = true);
    } catch (e, s) {
      getIt<Talker>().error('[chat] video download failed', e, s);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<Uint8List> _load() {
    final cubit = context.read<ChatCubit>();
    if (widget.previewOnly) {
      final cached = cubit.cachedMediaBytes(eventId: widget.message.id);
      if (cached != null) return SynchronousFuture(cached);
    }
    return cubit.mediaBytes(eventId: widget.message.id, thumb: true);
  }

  void _retryThumb() {
    setState(() {
      _thumb = _load();
    });
  }

  void _open() {
    final cubit = context.read<ChatCubit>();
    final file = cubit.videoFile(
      eventId: widget.message.id,
      fileName: widget.message.media?.fileName,
      mimeType: widget.message.media?.mimeType,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => VideoPlayerPage(file: file)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.previewOnly;
    return FutureBuilder<Uint8List>(
      future: _thumb,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        final Widget center = _downloading
            ? const SizedBox(
                width: 40,
                height: 40,
                child: M3EProgressIndicator.circularWavy(size: 40),
              )
            : Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xB3000000),
                  shape: .circle,
                ),
                child: Icon(
                  _fullReady
                      ? Icons.play_arrow_rounded
                      : Icons.download_rounded,
                  size: 32,
                  color: const Color(0xFFFFFFFF),
                ),
              );
        if (bytes != null) {
          final image = Image.memory(bytes, fit: .cover);
          return _MediaFrame(
            message: widget.message,
            onLinkTap: widget.onLinkTap,
            interactive: !preview,
            onTap: preview
                ? null
                : _fullReady
                ? _open
                : _download,
            center: center,
            child: _fullReady
                ? image
                : ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: image,
                  ),
          );
        }
        if (snapshot.hasError) {
          return _MediaFrame(
            message: widget.message,
            onLinkTap: widget.onLinkTap,
            interactive: !preview,
            onTap: preview ? null : _retryThumb,
            center: const Icon(
              Icons.refresh_rounded,
              size: 28,
              color: Color(0xFFFFFFFF),
            ),
            child: const SizedBox.expand(),
          );
        }
        return _MediaFrame(
          message: widget.message,
          onLinkTap: widget.onLinkTap,
          interactive: !preview,
          center: preview
              ? null
              : const SizedBox(
                  width: 40,
                  height: 40,
                  child: M3EProgressIndicator.circularWavy(size: 40),
                ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class const _MediaFrame({
  required final ChatMessage message,
  required final Widget child,
  final bool interactive = true,
  final Widget? center,
  final VoidCallback? onTap,
  final VoidCallback? onLinkTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final media = message.media!;
    final scheme = Theme.of(context).colorScheme;
    final maxWidth = (MediaQuery.sizeOf(context).width * 0.68).clamp(
      0.0,
      480.0,
    );
    final height = (maxWidth / media.aspect).clamp(80.0, 340.0);
    final caption = media.caption;
    return GestureDetector(
      onTap: interactive ? onTap : null,
      child: SizedBox(
        width: maxWidth,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            SizedBox(
              width: maxWidth,
              height: height,
              child: Stack(
                fit: .expand,
                children: [
                  ClipRRect(borderRadius: .circular(14), child: child),
                  if (media.kind == .video && media.durationMs != null)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC000000),
                          borderRadius: .circular(8),
                        ),
                        child: Text(
                          _formatDuration(media.durationMs!),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    ),
                  if (center != null) Center(child: center),
                  if (message.isOwn && message.status == .failed && interactive)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => context
                            .read<ChatCubit>()
                            .cancelSendMessage(message),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xB3000000),
                            shape: .circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC000000),
                        borderRadius: .circular(8),
                      ),
                      child: Row(
                        mainAxisSize: .min,
                        children: [
                          Text(
                            messageClockText(message.time),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            alignment: .centerLeft,
                            child: Row(
                              mainAxisSize: .min,
                              children: [
                                if (message.status == .sending ||
                                    message.status == .failed) ...[
                                  const SizedBox(width: 3),
                                  if (message.isOwn &&
                                      message.status == .failed)
                                    GestureDetector(
                                      onTap: interactive
                                          ? () => context
                                                .read<ChatCubit>()
                                                .retrySendMessage(message)
                                          : null,
                                      child: _OverlayStatusIcon(
                                        status: message.status!,
                                      ),
                                    )
                                  else
                                    _OverlayStatusIcon(status: message.status!),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (caption != null && caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                child: media.captionHtml != null
                    ? FormattedText(
                        html: media.captionHtml!,
                        style: TextStyle(
                          fontSize: 14,
                          color: message.isOwn
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                        ),
                        linkStyle: TextStyle(
                          fontSize: 14,
                          color: message.isOwn
                              ? scheme.onPrimary
                              : scheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: message.isOwn
                              ? scheme.onPrimary
                              : scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        onLinkTap: onLinkTap,
                      )
                    : FormattedText.plain(
                        caption,
                        style: TextStyle(
                          fontSize: 14,
                          color: message.isOwn
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                        ),
                        linkStyle: TextStyle(
                          fontSize: 14,
                          color: message.isOwn
                              ? scheme.onPrimary
                              : scheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: message.isOwn
                              ? scheme.onPrimary
                              : scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        onLinkTap: onLinkTap,
                      ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class const _OverlayStatusIcon({required final MessageStatus status})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return switch (status) {
      .sending => const SizedBox(
        width: 10,
        height: 10,
        child: AdaptiveLoadingIndicator(color: Color(0xFFFFFFFF)),
      ),
      .sent => const SizedBox.shrink(),
      .read => const SizedBox.shrink(),
      .failed => const Icon(
        Icons.error_rounded,
        size: 12,
        color: Color(0xFFFF8A80),
      ),
    };
  }
}

class const _PhotoViewerPage({
  required final Future<Uint8List> full,
  required final Uint8List thumb,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: FutureBuilder<Uint8List>(
                future: full,
                builder: (context, snapshot) {
                  final bytes = snapshot.data ?? thumb;
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.memory(bytes, fit: .contain),
                  );
                },
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
