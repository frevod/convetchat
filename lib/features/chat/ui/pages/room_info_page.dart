import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/ui/cubit/room_info_cubit.dart';
import 'package:convetchat/features/chat/ui/cubit/room_info_state.dart';
import 'package:convetchat/features/chat/ui/pages/room_info_page_andr.dart';
import 'package:convetchat/features/chat/ui/pages/room_info_page_cup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class const RoomInfoPage({super.key, required final String roomId}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RoomInfoCubit>(param1: roomId),
      child: BlocListener<RoomInfoCubit, RoomInfoState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            AdaptiveSnackbar.show(
              context: context,
              message: state.errorMessage!,
              type: .error,
            );
            context.read<RoomInfoCubit>().clearError();
          }
          if (state.left) {
            context.go('/chats');
          }
        },
        child: (getIt<PlatformStyle>().isCupertino)
            ? const RoomInfoPageCup()
            : const RoomInfoPageAndr(),
      ),
    );
  }
}
