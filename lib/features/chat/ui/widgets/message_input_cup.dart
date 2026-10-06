import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/utils/file_format.dart';
import 'package:convetchat/features/chat/domain/entities/chat_send_restriction.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/edit_notice.dart';
import 'package:convetchat/features/chat/ui/widgets/media_attach_sheet_cup.dart';
import 'package:convetchat/features/chat/ui/widgets/pending_media_strip_cup.dart';
import 'package:convetchat/features/chat/ui/widgets/record_mic_button.dart';
import 'package:convetchat/features/chat/ui/widgets/recording_indicator.dart';
import 'package:convetchat/features/chat/ui/widgets/reply_preview_animation.dart';
import 'package:convetchat/features/chat/ui/widgets/send_restriction_notice.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const MessageInputCup({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ChatCubit>();
    final state = cubit.state;
    final replyTo = state.replyTo;

    if (state.sendRestriction != ChatSendRestriction.none) {
      return SendRestrictionNotice(restriction: state.sendRestriction);
    }

    final blue = CupertinoColors.activeBlue.resolveFrom(context);
    const white = CupertinoColors.white;
    final grey = CupertinoColors.systemGrey.resolveFrom(context);
    final fieldFill = CupertinoColors.systemFill.resolveFrom(context);

    final stripInsets = EdgeInsets.only(
      left: state.isRecording ? 8 : 52,
      right: 52,
    );

    return Container(
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: .min,
          children: [
            ReplyPreviewAnimation(
              reply: replyTo,
              contentPadding: stripInsets,
              onCancel: cubit.cancelReply,
              onTapMessage: (message) => cubit.jumpToMessage(message.id),
            ),

            if (state.editing case final editing?)
              Padding(
                padding: stripInsets,
                child: EditNotice(
                  onCancel: cubit.cancelEdit,
                  onTap: () => cubit.jumpToMessage(editing.id),
                ),
              ),

            if (state.pendingMedia.isNotEmpty)
              Padding(
                padding: stripInsets,
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .stretch,
                  children: [
                    if (cubit.exceedsUploadLimit &&
                        state.uploadLimitBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Лимит сервера на файлы – ${formatFileSize(state.uploadLimitBytes)} (вложения: ${formatFileSize(cubit.pendingUploadBytes)})',
                          textAlign: .center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemRed,
                          ),
                        ),
                      ),
                    PendingMediaStripCup(
                      items: state.pendingMedia,
                      onRemove: cubit.removePending,
                    ),
                  ],
                ),
              ),

            Row(
              crossAxisAlignment: state.recordLocked ? .end : .center,
              children: [
                if (!state.isRecording)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final picked = await MediaAttachSheetCup.show(context);
                      if (picked != null && picked.isNotEmpty) {
                        await cubit.attachAssets(picked);
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: fieldFill,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.plus),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      IgnorePointer(
                        ignoring: state.isRecording,
                        child: Opacity(
                          opacity: state.isRecording ? 0 : 1,
                          child: CupertinoTextField(
                            controller: cubit.inputController,
                            focusNode: cubit.inputFocus,
                            placeholder: 'Сообщение',
                            onTapOutside: (_) {},
                            maxLines: 5,
                            minLines: 1,
                            textInputAction: state.sendOnEnter
                                ? TextInputAction.send
                                : TextInputAction.newline,
                            onSubmitted: state.sendOnEnter
                                ? (_) => cubit.send()
                                : null,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: .circular(50),
                              border: BoxBorder.all(),
                              color: CupertinoColors.systemFill,
                            ),
                          ),
                        ),
                      ),
                      if (state.isRecording)
                        Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: fieldFill,
                            borderRadius: .circular(50),
                          ),
                          child: RecordingIndicator(
                            levels: state.recordLevels,
                            elapsed: state.recordElapsed,
                            showCancel: state.recordLocked,
                            onCancel: cubit.cancelRecording,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: cubit.inputController,
                  builder: (context, value, _) {
                    final hasText = value.text.trim().isNotEmpty;
                    final hasSendableMedia = state.pendingMedia.isNotEmpty;
                    if (state.recordLocked) {
                      return Column(
                        mainAxisSize: .min,
                        children: [
                          Icon(
                            CupertinoIcons.lock_fill,
                            size: 20,
                            color: CupertinoColors.systemGrey,
                          ),
                          const SizedBox(height: 4),
                          _CircleButton(
                            onPressed: cubit.stopRecordingAndSend,
                            background: blue,
                            icon: const Icon(
                              CupertinoIcons.arrow_up,
                              color: white,
                              size: 20,
                            ),
                          ),
                        ],
                      );
                    }
                    if ((hasText || hasSendableMedia) &&
                        !state.isRecording &&
                        !cubit.exceedsUploadLimit) {
                      return _CircleButton(
                        onPressed: cubit.send,
                        background: blue,
                        icon: const Icon(
                          CupertinoIcons.arrow_up,
                          color: white,
                          size: 19,
                        ),
                      );
                    }
                    return RecordMicButton(
                      locked: state.recordLocked,
                      onStart: cubit.startRecording,
                      onStop: cubit.stopRecordingAndSend,
                      onCancel: cubit.cancelRecording,
                      onLock: cubit.lockRecording,
                      buttonBuilder: (context, dragOffset, dragging) {
                        final micButton = _CircleButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            AdaptiveSnackbar.show(
                              context: context,
                              message: 'Удерживайте для записи',
                              type: .info,
                            );
                          },
                          icon: Icon(
                            CupertinoIcons.mic_fill,
                            color: CupertinoColors.label.resolveFrom(context),
                            size: 20,
                          ),
                        );
                        if (state.recordLocked ||
                            (!state.isRecording && !dragging)) {
                          return micButton;
                        }
                        return Stack(
                          clipBehavior: .none,
                          alignment: .bottomCenter,
                          children: [
                            Positioned(
                              bottom: 54,
                              child: Transform.translate(
                                offset: Offset(0, dragOffset.dy),
                                child: Icon(
                                  CupertinoIcons.lock_open_fill,
                                  size: 22,
                                  color: grey,
                                ),
                              ),
                            ),
                            Positioned(
                              left: -44,
                              top: 12,
                              child: Transform.translate(
                                offset: Offset(dragOffset.dx, 0),
                                child: Icon(
                                  CupertinoIcons.chevron_left_2,
                                  size: 22,
                                  color: grey,
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: dragOffset,
                              child: micButton,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class const _CircleButton({
  required final VoidCallback? onPressed,
  required final Widget icon,
  final Color? background,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fill = background ?? CupertinoColors.systemFill.resolveFrom(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: onPressed,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: icon,
      ),
    );
  }
}
