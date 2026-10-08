import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/call/presentation/widgets/call_banner_andr.dart';
import 'package:convetchat/features/call/presentation/widgets/call_button_andr.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/chat_message_list.dart';
import 'package:convetchat/features/chat/ui/widgets/circle_preview_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/message_input.dart';
import 'package:convetchat/features/chat/ui/widgets/message_selection.dart';
import 'package:convetchat/features/chat/ui/widgets/pinned_banner.dart';
import 'package:convetchat/features/chat/ui/widgets/presence_status_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const ChatPageAndr({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatCubit>();
    final selectionCount = context.select(
      (ChatCubit c) => c.state.selectedEventIds.length,
    );
    final roomName = context.select((ChatCubit c) => c.state.roomName);
    final avatarMxc = context.select((ChatCubit c) => c.state.avatarMxc);
    final typingUsers = context.select((ChatCubit c) => c.state.typingUsers);
    final partnerUserId = context.select(
      (ChatCubit c) => c.state.partnerUserId,
    );
    final partnerOnline = context.select(
      (ChatCubit c) => c.state.partnerOnline,
    );
    final partnerBusy = context.select((ChatCubit c) => c.state.partnerBusy);
    final partnerLastActive = context.select(
      (ChatCubit c) => c.state.partnerLastActive,
    );
    final scheme = Theme.of(context).colorScheme;
    final statusText = presenceStatusText(
      typingUsers: typingUsers,
      partnerUserId: partnerUserId,
      partnerOnline: partnerOnline,
      partnerBusy: partnerBusy,
      partnerLastActive: partnerLastActive,
    );

    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        automaticallyImplyLeading: selectionCount == 0,
        leading: selectionCount > 0
            ? M3EIconButton(
                variant: .standard,
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
                  mainAxisSize: .min,
                  children: [
                    MxcAvatar(
                      mxc: avatarMxc,
                      fallback: avatarInitial(roomName),
                      size: 40,
                      context: context,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: .start,
                        mainAxisSize: .min,
                        children: [
                          Text(roomName, maxLines: 1, overflow: .ellipsis),
                          if (statusText.isNotEmpty)
                            Text(
                              statusText,
                              maxLines: 1,
                              overflow: .ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        actions: [
          if (selectionCount > 0) const MessageSelectionActions(),
          if (selectionCount == 0)
            CallButtonAndr(
              roomId: cubit.roomId,
              roomName: roomName,
              partnerUserId: partnerUserId,
            ),
        ],
      ),

      body: Stack(
        children: [
          Column(
            children: [
              CallBannerAndr(roomId: cubit.roomId),
              const PinnedBanner(),
              Expanded(child: ChatMessageList()),
              MessageInput(),
            ],
          ),
          const CirclePreviewAndr(),
        ],
      ),
    );
  }
}
