import 'dart:io';

import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/core/telegram/telegram_feedback_service.dart';
import 'package:convetchat/features/settings/ui/cubit/feedback_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:system_asset_picker/system_asset_picker.dart';

class const FeedbackPageAndr({super.key}) extends StatefulWidget {
  @override
  State<FeedbackPageAndr> createState() => _FeedbackPageAndrState();
}

class _FeedbackPageAndrState() extends State<FeedbackPageAndr> {
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
      final paths = await SystemAssetPicker.pickImagesAndVideos(
        maxItems: 10,
        maxVideoSizeMB: 50,
      );
      if (!mounted || paths.isEmpty) return;
      setState(() {
        _attachments = [
          ..._attachments,
          for (final path in paths)
            FeedbackAttachment(name: path.split('/').last, path: path),
        ];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось выбрать файлы')),
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

  void _onReset() {
    setState(() {
      _controller.clear();
      _attachments = [];
      _includeLogs = false;
    });
    context.read<FeedbackCubit>().reset();
  }

  bool get _canSend =>
      _controller.text.trim().isNotEmpty ||
      _attachments.isNotEmpty ||
      _includeLogs;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FeedbackCubit>().state;

    if (state.sent) {
      return Scaffold(
        appBar: M3EAppBar.top(
          shapeFamily: .round,
          density: .compact,
          title: const Text('Сообщить об ошибке'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 72,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Сообщение отправлено.\nСпасибо за помощь!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                AdaptiveButton.outlined(
                  onPressed: _onReset,
                  child: const Text('Написать ещё'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        automaticallyImplyLeading: true,
        title: const Text('Сообщить об ошибке'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                minLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                enabled: !state.isSending,
                onChanged: (_) {
                  if (state.errorMessage != null) {
                    context.read<FeedbackCubit>().clearError();
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Опишите проблему…',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  suffix: M3EIconButton(
                    variant: .standard,
                    onPressed: state.isSending ? () {} : _pickMedia,
                    icon: Icon(
                      Icons.photo_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
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
              spacing: 5,
              mainAxisSize: .min,
              children: [
                M3ECheckbox(
                  value: _includeLogs,
                  onChanged: (value) {
                    setState(() => _includeLogs = value ?? false);
                  },
                  label: const Text('Отправить логи'),
                ),
                AdaptiveButton.filled(
                  onPressed: state.isSending || !_canSend ? () {} : _onSend,
                  enabled: !state.isSending && _canSend,
                  child: state.isSending
                      ? const AdaptiveLoadingIndicator()
                      : const Text('Отправить'),
                ),
              ],
            ),
          ],
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
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: attachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 20),
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

  @override
  Widget build(BuildContext context) {
    final path = attachment.path;
    final isImage = _photoExts.contains(
      attachment.name.split('.').last.toLowerCase(),
    );

    return Stack(
      clipBehavior: Clip.none,
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
          top: -8,
          right: -8,
          child: M3EIconButton(
            size: .xs,
            shape: .round,
            variant: .filled,
            tooltip: 'Удалить',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 16),
          ),
        ),
      ],
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file_rounded,
            color: Theme.of(context).colorScheme.primary,
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
