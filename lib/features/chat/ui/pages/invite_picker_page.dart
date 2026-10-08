import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/ui/cubit/invite_picker_cubit.dart';
import 'package:convetchat/features/chat/ui/pages/invite_picker_page_andr.dart';
import 'package:convetchat/features/chat/ui/pages/invite_picker_page_cup.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const InvitePickerPage({super.key, required final String roomId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InvitePickerCubit(getIt<ChatsRepository>()),
      child: (getIt<PlatformStyle>().isCupertino)
          ? InvitePickerPageCup(roomId: roomId)
          : InvitePickerPageAndr(roomId: roomId),
    );
  }
}
