import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/chats/ui/cubit/user_search_cubit.dart';
import 'package:convetchat/features/chats/ui/widgets/user_search_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/components/app_bars/m3e_app_bars.dart';
import 'package:material_ui/material_ui.dart';

class const UserSearchPageAndr({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<UserSearchCubit>();
    final state = cubit.state;

    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        automaticallyImplyLeading: true,
        title: Text('Найти человека'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: cubit.searchController,
              onChanged: cubit.onQueryChanged,
              textInputAction: .search,
              decoration: InputDecoration(
                hintText: 'Поиск пользователей',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: .circular(18)),
                suffixIcon: state.isSearching
                    ? const SizedBox.square(
                        dimension: 20,
                        child: Center(child: AdaptiveLoadingIndicator()),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: state.isCreating
                ? const Center(child: AdaptiveLoadingIndicator())
                : ListView.builder(
                    itemCount: state.results.length,
                    itemBuilder: (context, index) {
                      final user = state.results[index];
                      return UserSearchResult(
                        displayName: user.displayName,
                        userId: user.userId,
                        onTap: () => cubit.openDirectChat(context, user.userId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
