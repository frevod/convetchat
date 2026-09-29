import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/chat_message_list.dart';
import 'package:convetchat/features/chat/ui/widgets/message_input.dart';
import 'package:convetchat/features/chat/ui/widgets/message_selection.dart';
import 'package:convetchat/features/chat/ui/widgets/presence_status_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const ChatPageAndr({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ChatCubit>();
    final state = cubit.state;
    final scheme = Theme.of(context).colorScheme;
    final selectionCount = state.selectedEventIds.length;

    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        automaticallyImplyLeading: selectionCount == 0,
        leading: selectionCount > 0
            ? IconButton(
                onPressed: cubit.clearSelection,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Снять выделение',
              )
            : null,
        title: selectionCount > 0
            ? MessageSelectionBarTitle(count: selectionCount)
            : GestureDetector(
                onTap: () => context.push('/chat/${cubit.roomId}/info'),
                behavior: .opaque,
                child: Row(
                children: [
                  MxcAvatar(
                    mxc: state.avatarMxc,
                    fallback: avatarInitial(state.roomName),
                    size: 40,
                    context: context,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: .start,
                      mainAxisSize: .min,
                      children: [
                        Text(state.roomName, maxLines: 1, overflow: .ellipsis),
                        PresenceStatusText(
                          state: state,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
                ),
              ),
        actions: [if (selectionCount > 0) const MessageSelectionActions()],
      ),

      body: Column(
        children: [
          Expanded(child: ChatMessageList()),
          MessageInput(),
        ],
      ),
    );
  }
}
