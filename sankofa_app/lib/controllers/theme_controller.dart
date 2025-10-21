import 'package:flutter/material.dart';
import 'package:sankofasave/services/theme_service.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._service, {ThemeMode initialMode = ThemeMode.light})
      : _themeMode = initialMode;

  final ThemeService _service;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadTheme() async {
    final storedMode = await _service.getThemeMode();
    if (storedMode != null && storedMode != _themeMode) {
      _themeMode = storedMode;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _service.saveThemeMode(mode);
  }

  Future<void> toggleTheme() async {
    final nextMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}

class ThemeControllerProvider extends InheritedNotifier<ThemeController> {
  const ThemeControllerProvider({
    super.key,
    required super.notifier,
    required super.child,
  });

  static ThemeController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ThemeControllerProvider>();
    assert(provider != null, 'ThemeControllerProvider not found in context');
    return provider!.notifier!;
  }
}