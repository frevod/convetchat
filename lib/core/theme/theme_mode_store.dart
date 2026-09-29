import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeStore() extends ValueNotifier<ThemeMode> {
  static const _prefsKey = 'theme_mode';

  this : super(ThemeMode.system) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      value = ThemeMode.values.firstWhere(
        (mode) => mode.name == saved,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (_) {}
  }

  int get modeIndex => switch (value) {
    .light => 0,
    .dark => 1,
    .system => 2,
  };

  Future<void> setModeIndex(int index) => setMode(switch (index) {
    0 => .light,
    1 => .dark,
    _ => .system,
  });
}
