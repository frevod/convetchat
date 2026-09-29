import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:go_router/go_router.dart';

class const ComposeButtonCup({super.key}) extends StatelessWidget {
  Future<void> _showMenu(BuildContext context) async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop('search'),
            child: const Text('Поиск пользователей'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop('group'),
            child: const Text('Создать группу'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop('catalog'),
            child: const Text('Каталог комнат'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Отмена'),
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'search':
        context.push('/user_search');
      case 'group':
        context.push('/create_group');
      case 'catalog':
        AdaptiveSnackbar.show(context: context, message: 'В разработке...');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showMenu(context),
      child: const Icon(CupertinoIcons.square_pencil),
    );
  }
}
