import 'dart:io';

import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/telegram/telegram_feedback_service.dart';
import 'package:convetchat/features/settings/ui/cubit/feedback_cubit.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class const FeedbackPageCup({super.key}) extends StatefulWidget {
  @override
  State<FeedbackPageCup> createState() => _FeedbackPageCupState();
}

class _FeedbackPageCupState() extends State<FeedbackPageCup> {
  static const _photoExts = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
  };

  final TextEditingController _controller = TextEditingController();

  List<FeedbackAttachment> _attachments = [];
  bool _includeLogs = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    try {
      final files = await ImagePicker().pickMultipleMedia();
      if (!mounted || files.isEmpty) return;
      setState(() {
        _attachments = [
          ..._attachments,
          for (final file in files)
            FeedbackAttachment(name: file.name, path: file.path),
        ];
      });
    } catch (_) {
      if (mounted) {
        AdaptiveSnackbar.show(
          context: context,
          message: 'Не удалось выбрать файлы',
          type: .error,
        );
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments = [..._attachments]..removeAt(index);
    });
  }

  Future<void> _onSend() async {
    final cubit = context.read<FeedbackCubit>();
    await cubit.send(
      _controller.text,
      attachments: _attachments,
      includeLogs: _includeLogs,
    );
    if (!mounted || !cubit.state.sent) return;
    setState(() {
      _controller.clear();
      _attachments = [];
      _includeLogs = false;
    });
  }

  bool get _canSend =>
      _controller.text.trim().isNotEmpty ||
      _attachments.isNotEmpty ||
      _includeLogs;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FeedbackCubit>().state;

    if (state.sent) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Сообщить об ошибке'),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 72,
                    color: CupertinoColors.systemGreen,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Сообщение отправлено.\nСпасибо за помощь!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  AdaptiveButton.outlined(
                    onPressed: () => context.read<FeedbackCubit>().reset(),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Text('Написать ещё'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Сообщить об ошибке'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: state.isSending ? null : _pickMedia,
          child: const Icon(CupertinoIcons.photo_on_rectangle),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _controller,
                  autofocus: true,
                  enabled: !state.isSending,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: .top,
                  placeholder: 'Опишите проблему…',
                ),
              ),
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                _AttachmentStrip(
                  attachments: _attachments,
                  onRemove: _removeAttachment,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoCheckbox(
                        value: _includeLogs,
                        onChanged: (value) =>
                            setState(() => _includeLogs = value ?? false),
                      ),
                      const Text('Отправить логи'),
                    ],
                  ),
                  AdaptiveButton.filled(
                    onPressed: state.isSending || !_canSend ? () {} : _onSend,
                    enabled: !state.isSending && _canSend,
                    child: state.isSending
                        ? Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: const AdaptiveLoadingIndicator(
                              color: CupertinoColors.white,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: const Text(
                              'Отправить',
                              style: TextStyle(color: CupertinoColors.white),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class const _AttachmentStrip({
  required final List<FeedbackAttachment> attachments,
  required final ValueChanged<int> onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: .horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return _AttachmentThumb(
            attachment: attachments[index],
            onRemove: () => onRemove(index),
          );
        },
      ),
    );
  }
}

class const _AttachmentThumb({
  required final FeedbackAttachment attachment,
  required final VoidCallback onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final path = attachment.path;
    final isImage = _FeedbackPageCupState._photoExts.contains(
      attachment.name.split('.').last.toLowerCase(),
    );

    return Stack(
      clipBehavior: .none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 88,
            height: 88,
            child: isImage && path != null
                ? Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _FileIcon(fileName: ''),
                  )
                : _FileIcon(fileName: attachment.name),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: _RemoveButton(onPressed: onRemove),
        ),
      ],
    );
  }
}

class const _RemoveButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      sizeStyle: .small,
      color: CupertinoColors.tertiarySystemFill,
      padding: const EdgeInsets.all(6),
      borderRadius: BorderRadius.circular(16),
      onPressed: onPressed,
      child: const Icon(
        CupertinoIcons.xmark,
        color: CupertinoColors.label,
        size: 12,
      ),
    );
  }
}

class const _FileIcon({required final String fileName})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      color: CupertinoColors.tertiarySystemFill,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.doc_fill,
            color: CupertinoColors.systemGrey,
            size: 28,
          ),
          if (fileName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}
