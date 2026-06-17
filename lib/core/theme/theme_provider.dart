import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePresetColor {
  terracotta(Color(0xFFC1694F), 'Terracotta'),
  pink(Color(0xFFE8889A), 'Pink'),
  lavender(Color(0xFFB39DDB), 'Lavender'),
  mint(Color(0xFFA5D6A7), 'Mint'),
  skyBlue(Color(0xFF90CAF9), 'Sky Blue');

  final Color color;
  final String name;
  const ThemePresetColor(this.color, this.name);
}

class ThemeColorNotifier extends StateNotifier<ThemePresetColor> {
  ThemeColorNotifier() : super(ThemePresetColor.terracotta) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('theme_color_preset');
      if (name != null) {
        state = ThemePresetColor.values.firstWhere(
          (e) => e.name == name,
          orElse: () => ThemePresetColor.terracotta,
        );
      }
    } catch (_) {}
  }

  Future<void> selectColor(ThemePresetColor preset) async {
    state = preset;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_color_preset', preset.name);
    } catch (_) {}
  }
}

final themeColorProvider =
    StateNotifierProvider<ThemeColorNotifier, ThemePresetColor>((ref) {
  return ThemeColorNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt('theme_mode');
      if (modeIndex != null &&
          modeIndex >= 0 &&
          modeIndex < ThemeMode.values.length) {
        state = ThemeMode.values[modeIndex];
      }
    } catch (_) {}
  }

  Future<void> selectMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', mode.index);
    } catch (_) {}
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
