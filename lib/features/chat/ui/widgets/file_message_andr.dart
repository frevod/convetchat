import 'package:convetchat/core/utils/file_format.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/formatted_text.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/message_status_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class const FileMessageAndr({required final ChatMessage message, super.key})
    extends StatefulWidget {
  @override
  State<FileMessageAndr> createState() => _FileMessageAndrState();
}

class _FileMessageAndrState() extends State<FileMessageAndr> {
  bool _ready = false;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _checkCached();
  }

  Future<void> _checkCached() async {
    try {
      final cached = await context.read<ChatCubit>().isFullCached(
        widget.message.id,
      );
      if (mounted) setState(() => _ready = cached);
    } catch (_) {}
  }

  Future<void> _onTap() async {
    if (_downloading) return;
    final cubit = context.read<ChatCubit>();
    if (_ready) {
      await cubit.openFileMessage(widget.message);
      return;
    }
    setState(() => _downloading = true);
    try {
      await cubit.mediaBytes(eventId: widget.message.id, thumb: false);
      if (mounted) setState(() => _ready = true);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = widget.message;
    final media = message.media;
    final name = media?.fileName ?? message.body;
    final isOwn = message.isOwn;
    final contentColor = isOwn ? scheme.onPrimary : scheme.onSurface;
    final subtleColor = isOwn
        ? scheme.onPrimary.withValues(alpha: 0.7)
        : scheme.onSurfaceVariant;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
      child: InkWell(
        borderRadius: .circular(14),
        onTap: _onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (isOwn ? scheme.onPrimary : scheme.primary)
                          .withValues(alpha: 0.15),
                      borderRadius: .circular(12),
                    ),
                    child: _downloading
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: contentColor,
                            ),
                          )
                        : Icon(
                            _ready
                                ? Icons.insert_drive_file_rounded
                                : Icons.download_rounded,
                            color: contentColor,
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      mainAxisSize: .min,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: .ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: .w500,
                            color: contentColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _ready
                              ? '${formatFileSize(media?.size)} · ${_actionHint()}'
                              : '${formatFileSize(media?.size)} · загрузить',
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: TextStyle(fontSize: 12, color: subtleColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (media?.caption case final caption? when caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
                  child: media?.captionHtml != null
                      ? FormattedText(
                          html: media!.captionHtml!,
                          style: TextStyle(fontSize: 14, color: contentColor),
                          linkStyle: TextStyle(
                            fontSize: 14,
                            color: isOwn ? scheme.onPrimary : scheme.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: isOwn
                                ? scheme.onPrimary
                                : scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : FormattedText.plain(
                          caption,
                          style: TextStyle(fontSize: 14, color: contentColor),
                          linkStyle: TextStyle(
                            fontSize: 14,
                            color: isOwn ? scheme.onPrimary : scheme.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: isOwn
                                ? scheme.onPrimary
                                : scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              Row(
                mainAxisSize: .min,
                mainAxisAlignment: .end,
                children: [
                  Text(
                    messageClockText(message.time),
                    style: TextStyle(fontSize: 11, color: subtleColor),
                  ),
                  MessageStatusIcon(status: message.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _actionHint() => 'открыть';
}
