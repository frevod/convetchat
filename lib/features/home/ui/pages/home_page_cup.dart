import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:go_router/go_router.dart';

class const HomePageCup({
  super.key,
  required final StatefulNavigationShell navigationShell,
}) extends StatelessWidget {
  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(child: navigationShell),
          CupertinoTabBar(
            currentIndex: navigationShell.currentIndex,
            onTap: _onDestinationSelected,
            activeColor: CupertinoColors.systemBlue,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.chat_bubble),
                activeIcon: Icon(CupertinoIcons.chat_bubble_fill),
                label: 'Чаты',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.settings),
                activeIcon: Icon(CupertinoIcons.settings_solid),
                label: 'Настройки',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
