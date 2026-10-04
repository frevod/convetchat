import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/app/adaptive/adaptive_text_field.dart';
import 'package:convetchat/features/chats/ui/cubit/user_search_cubit.dart';
import 'package:convetchat/features/chats/ui/widgets/user_search_result.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const UserSearchPageCup({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<UserSearchCubit>();
    final state = cubit.state;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Поиск пользователей'),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AdaptiveTextField(
                controller: cubit.searchController,
                onChanged: cubit.onQueryChanged,
                label: '@пользователь:сервер',
              ),
            ),
            Expanded(
              child: state.isCreating
                  ? const Center(child: AdaptiveLoadingIndicator())
                  : ListView.builder(
                      itemCount: state.results.length,

                      itemBuilder: (_, index) {
                        final user = state.results[index];
                        return UserSearchResult(
                          displayName: user.displayName,
                          userId: user.userId,
                          onTap: () =>
                              cubit.openDirectChat(context, user.userId),
                          showLoading: state.isSearching,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
