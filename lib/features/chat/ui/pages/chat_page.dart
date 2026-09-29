import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_state.dart';
import 'package:convetchat/features/chat/ui/pages/chat_page_andr.dart';
import 'package:convetchat/features/chat/ui/pages/chat_page_cup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const ChatPage({
  super.key,
  required final String roomId,
  final String? scrollToEventId,
}) extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState() extends State<ChatPage> {
  bool _scrolledToNotification = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatCubit>(param1: widget.roomId),
      child: BlocListener<ChatCubit, ChatState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            AdaptiveSnackbar.show(
              context: context,
              message: state.errorMessage!,
              type: .error,
            );
            context.read<ChatCubit>().clearError();
          }

          if (!_scrolledToNotification &&
              widget.scrollToEventId != null &&
              !state.isLoading &&
              state.messages.isNotEmpty) {
            _scrolledToNotification = true;
            context.read<ChatCubit>().jumpToMessage(widget.scrollToEventId!);
          }
        },
        child: (getIt<PlatformStyle>().isCupertino)
            ? const ChatPageCup()
            : const ChatPageAndr(),
      ),
    );
  }
}
