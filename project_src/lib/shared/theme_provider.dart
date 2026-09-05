import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

const String _keyThemePalette = 'app_theme_palette';

class ThemePaletteNotifier extends StateNotifier<AppPalette> {
  ThemePaletteNotifier() : super(AppPalette.midnight) {
    _loadPalette();
  }

  Future<void> _loadPalette() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_keyThemePalette);
      if (saved != null) {
        state = AppPalette.values.firstWhere(
          (p) => p.name == saved,
          orElse: () => AppPalette.midnight,
        );
      }
    } catch (_) {}
  }

  Future<void> setPalette(AppPalette palette) async {
    state = palette;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemePalette, palette.name);
    } catch (_) {}
  }
}

final themePaletteProvider = StateNotifierProvider<ThemePaletteNotifier, AppPalette>((ref) {
  return ThemePaletteNotifier();
});
