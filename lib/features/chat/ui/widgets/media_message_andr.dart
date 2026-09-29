import 'dart:async';
import 'dart:typed_data';

import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/video_player_page_andr.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const MediaMessageAndr({required final ChatMessage message, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final media = message.media!;
    if (media.kind == .video) return _VideoTile(message: message);
    return _PhotoTile(message: message);
  }
}

class const _PhotoTile({required final ChatMessage message})
    extends StatefulWidget {
  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState() extends State<_PhotoTile> {
  late Future<Uint8List> _thumb;

  @override
  void initState() {
    super.initState();
    _thumb = _load();
  }

  Future<Uint8List> _load() => context.read<ChatCubit>().mediaBytes(
    eventId: widget.message.id,
    thumb: true,
  );

  void _retry() => setState(() => _thumb = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _thumb,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null) {
          return _MediaFrame(
            message: widget.message,
            onTap: () => _openViewer(context, bytes),
            child: Image.memory(bytes, fit: .cover),
          );
        }
        if (snapshot.hasError) {
          return _MediaFrame(
            message: widget.message,
            center: M3EIconButton(
              icon: const Icon(Icons.refresh_rounded),
              variant: .tonal,
              onPressed: _retry,
            ),
            child: const SizedBox.expand(),
          );
        }
        return _MediaFrame(
          message: widget.message,
          center: const SizedBox(
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

class const _VideoTile({required final ChatMessage message})
    extends StatefulWidget {
  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState() extends State<_VideoTile> {
  late Future<Uint8List> _thumb;

  @override
  void initState() {
    super.initState();
    _thumb = _load();
  }

  Future<Uint8List> _load() => context.read<ChatCubit>().mediaBytes(
    eventId: widget.message.id,
    thumb: true,
  );

  void _retryThumb() => setState(() => _thumb = _load());

  void _open() {
    final cubit = context.read<ChatCubit>();
    final file = cubit.videoFile(
      eventId: widget.message.id,
      fileName: widget.message.media?.fileName,
      mimeType: widget.message.media?.mimeType,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => VideoPlayerPageAndr(file: file)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _thumb,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        final center = Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xB3000000),
            shape: .circle,
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            size: 32,
            color: Color(0xFFFFFFFF),
          ),
        );
        if (bytes != null) {
          return _MediaFrame(
            message: widget.message,
            onTap: _open,
            center: center,
            child: Image.memory(bytes, fit: .cover),
          );
        }
        if (snapshot.hasError) {
          return _MediaFrame(
            message: widget.message,
            onTap: _retryThumb,
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
          center: const SizedBox(
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
  final Widget? center,
  final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final media = message.media!;
    final scheme = Theme.of(context).colorScheme;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.68;
    final height = (maxWidth / media.aspect).clamp(80.0, 340.0);
    final caption = media.caption;
    return GestureDetector(
      onTap: onTap,
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
                  if (message.isOwn && message.status == .failed)
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
                          if (message.status != null) ...[
                            const SizedBox(width: 3),
                            if (message.isOwn && message.status == .failed)
                              GestureDetector(
                                onTap: () => context
                                    .read<ChatCubit>()
                                    .retrySendMessage(message),
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
                  ),
                ],
              ),
            ),
            if (caption != null && caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                child: Text(
                  caption,
                  style: TextStyle(
                    fontSize: 14,
                    color: message.isOwn
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
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
      .sent => const Icon(
        Icons.done_rounded,
        size: 12,
        color: Color(0xB3FFFFFF),
      ),
      .read => const Icon(
        Icons.done_all_rounded,
        size: 12,
        color: Color(0xFFFFFFFF),
      ),
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
