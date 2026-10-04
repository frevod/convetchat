import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_cubit.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_state.dart';
import 'package:convetchat/features/chats/ui/pages/chats_page_andr.dart';
import 'package:convetchat/features/chats/ui/pages/chats_page_cup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const ChatsPage({super.key}) extends StatefulWidget {
  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState() extends State<ChatsPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatsCubit>(),
      child: BlocListener<ChatsCubit, ChatsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            AdaptiveSnackbar.show(
              context: context,
              message: state.errorMessage!,
              type: .error,
            );
            context.read<ChatsCubit>().clearError();
          }
        },
        child: (getIt<PlatformStyle>().isCupertino)
            ? const ChatsPageCup()
            : const ChatsPageAndr(),
      ),
    );
  }
}
