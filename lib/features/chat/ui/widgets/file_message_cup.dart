import 'package:convetchat/core/utils/file_format.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/formatted_text.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/message_status_icon.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const FileMessageCup({required final ChatMessage message, super.key})
    extends StatefulWidget {
  @override
  State<FileMessageCup> createState() => _FileMessageCupState();
}

class _FileMessageCupState() extends State<FileMessageCup> {
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
    final message = widget.message;
    final media = message.media;
    final name = media?.fileName ?? message.body;
    final label = CupertinoColors.label.resolveFrom(context);
    const grey = CupertinoColors.systemGrey;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _onTap,
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
                      color: grey.withValues(alpha: 0.2),
                      borderRadius: .circular(12),
                    ),
                    child: _downloading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CupertinoActivityIndicator(),
                          )
                        : Icon(
                            _ready
                                ? CupertinoIcons.doc_fill
                                : CupertinoIcons.cloud_download,
                            color: CupertinoColors.activeBlue.resolveFrom(
                              context,
                            ),
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
                            color: label,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _ready
                              ? '${formatFileSize(media?.size)} · открыть'
                              : '${formatFileSize(media?.size)} · загрузить',
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: const TextStyle(fontSize: 12, color: grey),
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
                          style: TextStyle(fontSize: 14, color: label),
                          linkStyle: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.activeBlue.resolveFrom(
                              context,
                            ),
                            decoration: TextDecoration.underline,
                            decorationColor: CupertinoColors.activeBlue
                                .resolveFrom(context),
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : FormattedText.plain(
                          caption,
                          style: TextStyle(fontSize: 14, color: label),
                          linkStyle: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.activeBlue.resolveFrom(
                              context,
                            ),
                            decoration: TextDecoration.underline,
                            decorationColor: CupertinoColors.activeBlue
                                .resolveFrom(context),
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
                    style: const TextStyle(fontSize: 11, color: grey),
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
}
