import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chats/ui/cubit/user_search_cubit.dart';
import 'package:convetchat/features/chats/ui/cubit/user_search_state.dart';
import 'package:convetchat/features/chats/ui/pages/user_search_page_andr.dart';
import 'package:convetchat/features/chats/ui/pages/user_search_page_cup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const UserSearchPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UserSearchCubit>(),
      child: BlocListener<UserSearchCubit, UserSearchState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            AdaptiveSnackbar.show(
              context: context,
              message: state.errorMessage!,
              type: .error,
            );
            context.read<UserSearchCubit>().clearError();
          }
        },
        child: (getIt<PlatformStyle>().isCupertino)
            ? const UserSearchPageCup()
            : const UserSearchPageAndr(),
      ),
    );
  }
}
