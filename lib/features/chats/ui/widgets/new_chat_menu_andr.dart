import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const NewChatMenuAndr({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return M3EFabMenu(
      icon: const Icon(Icons.edit_rounded),
      closeIcon: const Icon(Icons.close_rounded),
      items: [
        M3EFabMenuItem(
          icon: const Icon(Icons.person_search_rounded),
          label: 'Поиск пользователей',
          onPressed: () => context.push('/user_search'),
        ),
        M3EFabMenuItem(
          icon: const Icon(Icons.group_add_rounded),
          label: 'Создать группу',
          onPressed: () => context.push('/create_group'),
        ),
        M3EFabMenuItem(
          icon: const Icon(Icons.travel_explore_rounded),
          label: 'Каталог комнат',
          onPressed: () => context.push('/room_directory'),
        ),
      ],
    );
  }
}
