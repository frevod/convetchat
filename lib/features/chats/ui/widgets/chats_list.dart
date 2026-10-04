import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_state.dart';
import 'package:convetchat/features/chats/ui/widgets/chats_list_andr.dart';
import 'package:convetchat/features/chats/ui/widgets/chats_list_cup.dart';
import 'package:flutter/widgets.dart';

class const ChatsList({super.key, required final ChatsState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return ChatsListCup(state: state);
    }
    return ChatsListAndr(state: state);
  }
}
