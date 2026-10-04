import 'package:convetchat/features/chats/ui/cubit/chats_cubit.dart';
import 'package:convetchat/features/chats/ui/widgets/chats_app_bar_title.dart';
import 'package:convetchat/features/chats/ui/widgets/chats_list.dart';
import 'package:convetchat/features/chats/ui/widgets/compose_button_cup.dart';
import 'package:convetchat/features/chats/ui/widgets/encryption_banner.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const ChatsPageCup({super.key}) extends StatefulWidget {
  @override
  State<ChatsPageCup> createState() => _ChatsPageCupState();
}

class _ChatsPageCupState() extends State<ChatsPageCup> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<ChatsCubit>().state;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Чаты'),
            middle: ChatsAppBarTitle(connectionStatus: state.connectionStatus),
            alwaysShowMiddle: false,
            trailing: const ComposeButtonCup(),
          ),
          SliverToBoxAdapter(child: EncryptionBanner()),
          ChatsList(state: state),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}
