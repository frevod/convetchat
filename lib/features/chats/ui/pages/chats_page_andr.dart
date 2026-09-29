import 'package:convetchat/features/chats/ui/cubit/chats_cubit.dart';
import 'package:convetchat/features/chats/ui/widgets/chats_app_bar_title.dart';
import 'package:convetchat/features/chats/ui/widgets/chats_list.dart';
import 'package:convetchat/features/chats/ui/widgets/encryption_banner.dart';
import 'package:convetchat/features/chats/ui/widgets/new_chat_menu_andr.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/components/app_bars/m3e_app_bars.dart';
import 'package:material_ui/material_ui.dart';

class const ChatsPageAndr({super.key}) extends StatefulWidget {
  @override
  State<ChatsPageAndr> createState() => _ChatsPageState();
}

class _ChatsPageState() extends State<ChatsPageAndr> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<ChatsCubit>().state;

    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        title: ChatsAppBarTitle(connectionStatus: state.connectionStatus),
      ),
      floatingActionButton: const NewChatMenuAndr(),
      body: Column(
        children: [
          EncryptionBanner(),
          Expanded(child: ChatsList(state: state)),
        ],
      ),
    );
  }
}
