import 'dart:async';
import 'dart:typed_data';

import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/formatted_text.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/video_player_page.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const MediaMessageCup({required final ChatMessage message, super.key})
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
            center: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _retry,
              child: const Icon(CupertinoIcons.refresh),
            ),
            child: const SizedBox.expand(),
          );
        }
        return _MediaFrame(
          message: widget.message,
          center: const CupertinoActivityIndicator(radius: 20),
          child: const SizedBox.expand(),
        );
      },
    );
  }

  void _openViewer(BuildContext context, Uint8List thumb) {
    final cubit = context.read<ChatCubit>();
    final full = cubit.mediaBytes(eventId: widget.message.id, thumb: false);
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
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
      CupertinoPageRoute<void>(builder: (_) => VideoPlayerPage(file: file)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _thumb,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        const center = SizedBox(
          width: 52,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Color(0xB3000000), shape: .circle),
            child: Icon(
              CupertinoIcons.play_fill,
              size: 32,
              color: Color(0xFFFFFFFF),
            ),
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
              CupertinoIcons.refresh,
              size: 28,
              color: Color(0xFFFFFFFF),
            ),
            child: const SizedBox.expand(),
          );
        }
        return _MediaFrame(
          message: widget.message,
          center: const CupertinoActivityIndicator(radius: 20),
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
    final msg = message;
    final media = msg.media!;
    final maxWidth = (MediaQuery.sizeOf(context).width * 0.68).clamp(
      0.0,
      480.0,
    );
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
                  if (msg.isOwn && msg.status == .failed)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () =>
                            context.read<ChatCubit>().cancelSendMessage(msg),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xB3000000),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            size: 14,
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
                            messageClockText(msg.time),
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
                                if (msg.status == .sending ||
                                    msg.status == .failed) ...[
                                  const SizedBox(width: 3),
                                  if (msg.isOwn && msg.status == .failed)
                                    GestureDetector(
                                      onTap: () => context
                                          .read<ChatCubit>()
                                          .retrySendMessage(msg),
                                      child: _OverlayStatusIcon(
                                        status: msg.status!,
                                      ),
                                    )
                                  else
                                    _OverlayStatusIcon(status: msg.status!),
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
                          color: msg.isOwn
                              ? CupertinoColors.white
                              : CupertinoColors.secondaryLabel.resolveFrom(
                                  context,
                                ),
                        ),
                      )
                    : FormattedText.plain(
                        caption,
                        style: TextStyle(
                          fontSize: 14,
                          color: msg.isOwn
                              ? CupertinoColors.white
                              : CupertinoColors.secondaryLabel.resolveFrom(
                                  context,
                                ),
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
      .sent => const SizedBox.shrink(),
      .read => const SizedBox.shrink(),
      .failed => const Icon(
        CupertinoIcons.exclamationmark_circle,
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
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0x00000000),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.xmark),
        ),
      ),
      child: SafeArea(
        child: Center(
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
      ),
    );
  }
}
