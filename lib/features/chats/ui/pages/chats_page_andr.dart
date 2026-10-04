import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chats/domain/entities/connection_status.dart';
import 'package:convetchat/features/chats/ui/cubit/chat_search_cubit.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_cubit.dart';
import 'package:convetchat/features/chats/ui/widgets/chat_search_body_andr.dart';
import 'package:convetchat/features/chats/ui/widgets/chats_list.dart';
import 'package:convetchat/features/chats/ui/widgets/encryption_banner.dart';
import 'package:convetchat/features/chats/ui/widgets/new_chat_menu_andr.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const ChatsPageAndr({super.key}) extends StatefulWidget {
  @override
  State<ChatsPageAndr> createState() => _ChatsPageState();
}

class _ChatsPageState() extends State<ChatsPageAndr> {
  late final M3ESearchController _searchController = M3ESearchController();

  late final ChatSearchCubit _searchCubit = getIt<ChatSearchCubit>();

  @override
  void dispose() {
    _searchController.dispose();
    _searchCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ChatsCubit>().state;
    final hint = state.connectionStatus == ConnectionStatus.disconnected
        ? 'Нет соединения с сервером'
        : 'Чаты';

    return Scaffold(
      appBar: M3EAppBar.search(
        shapeFamily: .round,
        density: .compact,
        searchController: _searchController,
        barHintText: hint,
        onChanged: _searchCubit.setQuery,
        onClose: () {
          _searchController.clear();
          _searchCubit.setQuery('');
        },
        suggestionsBuilder: (_, controller) => [
          ChatSearchBodyAndr(
            searchController: controller,
            searchCubit: _searchCubit,
            chatsCubit: context.read<ChatsCubit>(),
          ),
        ],
      ),
      floatingActionButton: const NewChatMenuAndr(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            EncryptionBanner(),
            Expanded(child: ChatsList(state: state)),
          ],
        ),
      ),
    );
  }
}
