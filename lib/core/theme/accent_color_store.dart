import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccentColorStore() extends ValueNotifier<Color> {
  static const _seedKey = 'accent_seed';
  static const _dynamicKey = 'use_dynamic_color';

  bool _useDynamicColor = true;
  bool? _dynamicSupported;

  this : super(Colors.blue) {
    _restore();
  }

  bool get useDynamicColor => _useDynamicColor;

  bool? get dynamicSupported => _dynamicSupported;

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSeed = prefs.getInt(_seedKey);
      value = Color(savedSeed ?? Colors.blue.toARGB32());
      _useDynamicColor = prefs.getBool(_dynamicKey) ?? true;
      notifyListeners();
      if (_useDynamicColor && !await checkDynamicColorSupported()) {
        _useDynamicColor = false;
        notifyListeners();
        await prefs.setBool(_dynamicKey, false);
      }
    } catch (_) {}
  }

  Future<bool> checkDynamicColorSupported() async {
    if (_dynamicSupported != null) return _dynamicSupported!;
    bool supported;
    try {
      supported = await DynamicColorPlugin.getCorePalette() != null;
    } catch (_) {
      supported = false;
    }
    _dynamicSupported = supported;
    return supported;
  }

  Future<void> setSeedColor(Color color) async {
    value = color;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_seedKey, color.toARGB32());
    } catch (_) {}
  }

  Future<void> setUseDynamicColor(bool enabled) async {
    _useDynamicColor = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dynamicKey, enabled);
    } catch (_) {}
  }
}
