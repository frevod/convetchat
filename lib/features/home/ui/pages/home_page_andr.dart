import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/components/navigation_bar/m3e_navigation_bar.dart';
import 'package:material_ui/material_ui.dart';

class const HomePageAndr({
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
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: M3ENavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        labelBehavior: .onlySelected,
        wideDestinationWidth: 100,
        destinations: const [
          M3ENavigationBarDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
          ),
          M3ENavigationBarDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
          ),
        ],
      ),
    );
  }
}
