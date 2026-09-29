import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/theme/theme_mode_store.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class const AppearancePageCup({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final store = getIt<ThemeModeStore>();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('Внешний вид')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ValueListenableBuilder(
              valueListenable: store,
              builder: (context, _, _) {
                return CupertinoListSection.insetGrouped(
                  backgroundColor: CupertinoColors.transparent,
                  children: [
                    CupertinoListTile(
                      padding: EdgeInsets.all(8),
                      title: Text('Тема'),
                      subtitle: SizedBox(
                        width: .infinity,
                        child: CupertinoSlidingSegmentedControl<int>(
                          groupValue: store.modeIndex,
                          onValueChanged: (index) {
                            if (index != null) store.setModeIndex(index);
                          },
                          children: const {
                            0: Text('Светлая'),
                            1: Text('Тёмная'),
                            2: Text('Системная'),
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
