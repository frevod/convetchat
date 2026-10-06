import 'package:convetchat/core/platform_info.dart';
import 'package:convetchat/features/chat/domain/entities/chat_send_restriction.dart';
import 'package:convetchat/features/chat/domain/entities/record_mode.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/edit_notice.dart';
import 'package:convetchat/features/chat/ui/widgets/media_attach_sheet_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/pending_media_strip_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/record_mic_button.dart';
import 'package:convetchat/features/chat/ui/widgets/recording_indicator.dart';
import 'package:convetchat/features/chat/ui/widgets/reply_widget.dart';
import 'package:convetchat/features/chat/ui/widgets/send_restriction_notice.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const MessageInputAndr({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ChatCubit>();
    final state = cubit.state;
    final replyTo = state.replyTo;

    if (state.sendRestriction != ChatSendRestriction.none) {
      return SendRestrictionNotice(restriction: state.sendRestriction);
    }

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: .only(topLeft: .circular(18), topRight: .circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              if (replyTo != null)
                ReplyWidget(
                  reply: replyTo,
                  onCancel: cubit.cancelReply,
                  onTap: () => cubit.jumpToMessage(replyTo.id),
                ),

              if (state.editing case final editing?)
                EditNotice(
                  onCancel: cubit.cancelEdit,
                  onTap: () => cubit.jumpToMessage(editing.id),
                ),

              if (state.pendingMedia.isNotEmpty)
                PendingMediaStripAndr(
                  items: state.pendingMedia,
                  onRemove: cubit.removePending,
                ),

              Row(
                crossAxisAlignment: .end,
                children: [
                  if (!state.isRecording)
                    M3EButton.outlined(
                      onPressed: () async {
                        if (PlatformInfos.isLinux) {
                          final picked = await FilePicker.pickFiles();
                          final files = picked
                              .where((f) => f.path != null)
                              .map(
                                (f) => (
                                  path: f.path!,
                                  name: f.name,
                                  size: f.lengthSync(),
                                ),
                              )
                              .toList(growable: false);
                          if (files.isNotEmpty) {
                            await cubit.attachLocalFiles(files);
                          }
                          return;
                        }
                        final picked = await MediaAttachSheetAndr.show(context);
                        if (picked != null && picked.isNotEmpty) {
                          await cubit.attachAssets(picked);
                        }
                      },
                      decoration: const M3EButtonDecoration(
                        fixedSize: Size(48, 48),
                        borderRadius: 50,
                        pressedRadius: 10,
                        hoveredRadius: 20,
                      ),
                      child: Icon(Icons.add_rounded),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        IgnorePointer(
                          ignoring: state.isRecording,
                          child: Opacity(
                            opacity: state.isRecording ? 0 : 1,
                            child: TextField(
                              controller: cubit.inputController,
                              focusNode: cubit.inputFocus,
                              onTapOutside: (_) {},
                              minLines: 1,
                              maxLines: 5,
                              textInputAction: state.sendOnEnter
                                  ? TextInputAction.send
                                  : TextInputAction.newline,
                              onSubmitted: state.sendOnEnter
                                  ? (_) => cubit.send()
                                  : null,
                              decoration: InputDecoration(
                                hintText: 'Сообщение',
                                border: OutlineInputBorder(
                                  borderRadius: .circular(24),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (state.isRecording)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
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
                      final locked = state.recordLocked;
                      final canSend =
                          (hasText || hasSendableMedia) && !state.isRecording;
                      return RecordMicButton(
                        locked: locked,
                        onStart: cubit.startRecording,
                        onStop: cubit.stopRecordingAndSend,
                        onCancel: cubit.cancelRecording,
                        onLock: cubit.lockRecording,
                        buttonBuilder: (context, dragOffset, dragging) {
                          final scheme = Theme.of(context).colorScheme;
                          final sendLike = locked || canSend;
                          final showHints =
                              (state.isRecording || dragging) && !locked;
                          return Stack(
                            clipBehavior: .none,
                            alignment: .bottomCenter,
                            children: [
                              Transform.translate(
                                offset: showHints ? dragOffset : Offset.zero,
                                child: ExcludeFocus(
                                  child: M3EButton.filled(
                                    key: const ValueKey('trailing action'),
                                    decoration: const M3EButtonDecoration(
                                      fixedSize: Size(48, 48),
                                      borderRadius: 50,
                                      pressedRadius: 10,
                                      hoveredRadius: 20,
                                    ),
                                    onPressed: () {
                                      if (locked) {
                                        cubit.stopRecordingAndSend();
                                        return;
                                      }
                                      if (canSend) {
                                        cubit.send();
                                        return;
                                      }
                                      HapticFeedback.mediumImpact();
                                      cubit.toggleRecordMode();
                                    },
                                    child: Icon(
                                      sendLike
                                          ? Icons.arrow_upward_rounded
                                          : (state.recordMode ==
                                                    RecordMode.circle
                                                ? Icons.videocam_rounded
                                                : Icons.mic_rounded),
                                    ),
                                  ),
                                ),
                              ),
                              if (showHints)
                                Positioned(
                                  bottom: 80,
                                  child: Transform.translate(
                                    offset: Offset(0, dragOffset.dy),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainer,
                                        borderRadius: .circular(18),
                                      ),
                                      padding: EdgeInsets.all(8),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons
                                                .keyboard_double_arrow_up_rounded,
                                          ),
                                          Icon(
                                            Icons.lock_open_rounded,
                                            size: 22,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (showHints)
                                Positioned(
                                  left: -60,
                                  top: 12,
                                  child: Transform.translate(
                                    offset: Offset(dragOffset.dx, 0),
                                    child: Icon(
                                      Icons.keyboard_double_arrow_left_rounded,
                                      size: 22,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
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
      ),
    );
  }
}
