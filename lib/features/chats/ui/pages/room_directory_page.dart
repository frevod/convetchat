import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chats/domain/entities/search_filter.dart';
import 'package:convetchat/features/chats/ui/cubit/chat_search_cubit.dart';
import 'package:convetchat/features/chats/ui/cubit/chat_search_state.dart';
import 'package:convetchat/features/chats/ui/pages/room_directory_page_andr.dart';
import 'package:convetchat/features/chats/ui/pages/room_directory_page_cup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const RoomDirectoryPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ChatSearchCubit>()..setFilter(SearchFilter.publicRooms),
      child: BlocListener<ChatSearchCubit, ChatSearchState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            AdaptiveSnackbar.show(
              context: context,
              message: state.errorMessage!,
              type: .error,
            );
            context.read<ChatSearchCubit>().clearError();
          }
        },
        child: (getIt<PlatformStyle>().isCupertino)
            ? const RoomDirectoryPageCup()
            : const RoomDirectoryPageAndr(),
      ),
    );
  }
}
