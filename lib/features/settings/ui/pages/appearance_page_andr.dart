import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/theme/accent_color_store.dart';
import 'package:convetchat/core/theme/theme_mode_store.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

const _paletteColors = [
  Colors.blue,
  Colors.blueGrey,
  Colors.teal,
  Colors.green,
  Colors.lime,
  Colors.orange,
  Colors.red,
  Colors.pink,
  Colors.purple,
];

class const AppearancePageAndr({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        title: const Text('Внешний вид'),
        automaticallyImplyLeading: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          M3EList(
            itemCount: 1,
            itemBuilder: (context, index) {
              final store = getIt<ThemeModeStore>();
              return ValueListenableBuilder<ThemeMode>(
                valueListenable: store,
                builder: (context, themeMode, _) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 16,
                          children: [
                            const Icon(Icons.sunny),
                            Text(
                              'Тема',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        M3ESegmentedButton<ThemeMode>(
                          showSelectedIcon: false,
                          segments: const [
                            M3ESegment(value: .light, label: 'Светлая'),
                            M3ESegment(value: .dark, label: 'Тёмная'),
                            M3ESegment(value: .system, label: 'Системная'),
                          ],
                          selected: {themeMode},
                          onSelectionChanged: (v) => store.setMode(v.first),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          M3EList(
            itemCount: 1,
            itemBuilder: (context, index) {
              final accentStore = getIt<AccentColorStore>();
              return ValueListenableBuilder<Color>(
                valueListenable: accentStore,
                builder: (context, color, _) {
                  final useDynamic = accentStore.useDynamicColor;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 16,
                          children: [
                            const Icon(Icons.palette_outlined),
                            Text(
                              'Цветовая палитра',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        M3ECheckbox(
                          value: useDynamic,
                          label: const Text('На основе обоев'),
                          onChanged: (v) async {
                            if (v != true) {
                              await accentStore.setUseDynamicColor(false);
                              return;
                            }
                            final supported = await accentStore
                                .checkDynamicColorSupported();
                            if (!supported) {
                              if (!context.mounted) return;
                              AdaptiveSnackbar.show(
                                context: context,
                                message:
                                    'Динамический цвет недоступен на этом '
                                    'устройстве',
                                type: .warning,
                              );
                              return;
                            }
                            await accentStore.setUseDynamicColor(true);
                          },
                        ),
                        if (!useDynamic)
                          Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              for (final c in _paletteColors)
                                _PaletteDot(
                                  color: c,
                                  selected: color == c,
                                  onTap: useDynamic
                                      ? null
                                      : () => accentStore.setSeedColor(c),
                                ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class const _PaletteDot({
  required final Color color,
  required final bool selected,
  final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 3,
                )
              : null,
        ),
        child: selected
            ? Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.onSurface,
                size: 22,
              )
            : null,
      ),
    );
  }
}
