import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chats/ui/cubit/create_group_cubit.dart';
import 'package:convetchat/features/chats/ui/cubit/create_group_state.dart';
import 'package:convetchat/features/chats/ui/pages/create_group_page_andr.dart';
import 'package:convetchat/features/chats/ui/pages/create_group_page_cup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class const CreateGroupPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CreateGroupCubit>(),
      child: BlocListener<CreateGroupCubit, CreateGroupState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            AdaptiveSnackbar.show(
              context: context,
              message: state.errorMessage!,
              type: .error,
            );
            context.read<CreateGroupCubit>().clearError();
          }
          final roomId = state.createdRoomId;
          if (roomId != null) {
            context.read<CreateGroupCubit>().consumeCreated();
            context.pushReplacement('/chat/$roomId');
          }
        },
        child: (getIt<PlatformStyle>().isCupertino)
            ? const CreateGroupPageCup()
            : const CreateGroupPageAndr(),
      ),
    );
  }
}
