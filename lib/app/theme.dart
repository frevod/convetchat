import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

sealed class AppTheme() {
  static const seedColor = Colors.blue;

  static ThemeData materialTheme(
    Brightness brightness,
    ColorScheme? dynamicScheme, {
    Color seed = seedColor,
  }) {
    final scheme =
        dynamicScheme ?? .fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      colorScheme: scheme,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: .circular(18)),
      ),
    );
  }

  static M3EThemeData expressiveTheme(ThemeData theme) {
    return .fromMaterial(theme);
  }

  static CupertinoThemeData cupertinoTheme(Brightness brightness) {
    return CupertinoThemeData(
      primaryColor: CupertinoColors.systemBlue,
      brightness: brightness,
    );
  }
}
