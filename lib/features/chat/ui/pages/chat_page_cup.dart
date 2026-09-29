import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/chat_message_list.dart';
import 'package:convetchat/features/chat/ui/widgets/message_input.dart';
import 'package:convetchat/features/chat/ui/widgets/message_selection.dart';
import 'package:convetchat/features/chat/ui/widgets/presence_status_text.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class const ChatPageCup({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ChatCubit>();
    final state = cubit.state;
    final cubitActions = context.read<ChatCubit>();
    final selectionCount = state.selectedEventIds.length;
    final hasOwnSelected = selectedHasOwnMessages(cubitActions);
    final selecting = selectionCount > 0;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: selecting
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: cubitActions.clearSelection,
                child: const Icon(CupertinoIcons.xmark),
              )
            : null,
        middle: selecting
            ? Text('Выбрано: $selectionCount', maxLines: 1, overflow: .ellipsis)
            : GestureDetector(
                onTap: () =>
                    context.push('/chat/${cubitActions.roomId}/info'),
                behavior: .opaque,
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      state.roomName,
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                    PresenceStatusText(
                      state: state,
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemBlue.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
        trailing: selecting
            ? Row(
                mainAxisSize: .min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => cubitActions.copySelected(),
                    child: const Icon(CupertinoIcons.doc_on_doc),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: hasOwnSelected
                        ? () => cubitActions.deleteSelected()
                        : null,
                    child: const Icon(CupertinoIcons.delete),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => openForwardPickerAndPick(context),
                    child: const Icon(CupertinoIcons.arrow_turn_up_right),
                  ),
                ],
              )
            : MxcAvatar(
                mxc: state.avatarMxc,
                fallback: avatarInitial(state.roomName),
                size: 35,
                context: context,
              ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: ChatMessageList()),
            const MessageInput(),
          ],
        ),
      ),
    );
  }
}
