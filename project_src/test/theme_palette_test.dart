import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_ink/core/theme/app_theme.dart';
import 'package:project_ink/shared/theme_provider.dart';

void main() {
  group('AppPalette Extension Tests', () {
    test('All palettes have valid non-empty display names and IDs', () {
      for (final palette in AppPalette.values) {
        expect(palette.displayName.isNotEmpty, isTrue);
        expect(palette.id, equals(palette.name));
        expect(palette.previewPrimary, isA<Color>());
        expect(palette.previewSecondary, isA<Color>());
        expect(palette.previewDarkBg, isA<Color>());
      }
    });

    test('Midnight palette has expected preview colors', () {
      const palette = AppPalette.midnight;
      expect(palette.displayName, 'Midnight Ink Glow');
      expect(palette.previewPrimary, const Color(0xFF00E5FF));
      expect(palette.previewSecondary, const Color(0xFF3B82F6));
      expect(palette.previewDarkBg, const Color(0xFF090D16));
    });

    test('Amber palette has expected preview colors', () {
      const palette = AppPalette.amber;
      expect(palette.displayName, 'Warm Literary & Amber');
      expect(palette.previewPrimary, const Color(0xFFF59E0B));
      expect(palette.previewSecondary, const Color(0xFFF97316));
      expect(palette.previewDarkBg, const Color(0xFF14100C));
    });

    test('Sage palette has expected preview colors', () {
      const palette = AppPalette.sage;
      expect(palette.displayName, 'Zen Forest & Sage');
      expect(palette.previewPrimary, const Color(0xFF10B981));
      expect(palette.previewSecondary, const Color(0xFF14B8A6));
      expect(palette.previewDarkBg, const Color(0xFF0A1410));
    });

    test('Royal palette has expected preview colors', () {
      const palette = AppPalette.royal;
      expect(palette.displayName, 'Classic Royal Velvet');
      expect(palette.previewPrimary, const Color(0xFF6750A4));
      expect(palette.previewSecondary, const Color(0xFF7C4DFF));
      expect(palette.previewDarkBg, const Color(0xFF0F0C1E));
    });
  });

  group('AppTheme ThemeData Generation Tests', () {
    test('Generates valid dark themes for all palettes', () {
      for (final palette in AppPalette.values) {
        final darkTheme = AppTheme.getTheme(palette, isDark: true);
        expect(darkTheme.brightness, Brightness.dark);
        expect(darkTheme.scaffoldBackgroundColor, isNotNull);
        expect(darkTheme.cardTheme.elevation, 0);
        expect(darkTheme.appBarTheme.backgroundColor, isNotNull);
      }
    });

    test('Generates valid light themes for all palettes', () {
      for (final palette in AppPalette.values) {
        final lightTheme = AppTheme.getTheme(palette, isDark: false);
        expect(lightTheme.brightness, Brightness.light);
        expect(lightTheme.scaffoldBackgroundColor, isNotNull);
        expect(lightTheme.cardTheme.elevation, 0.5);
        expect(lightTheme.appBarTheme.backgroundColor, isNotNull);
      }
    });

    test('Midnight Dark theme primary color matches Cyan glow', () {
      final darkTheme = AppTheme.getTheme(AppPalette.midnight, isDark: true);
      expect(darkTheme.colorScheme.primary, const Color(0xFF00E5FF));
      expect(darkTheme.colorScheme.surface, const Color(0xFF0F1523));
    });

    test('Amber Light theme primary color matches Warm Amber', () {
      final lightTheme = AppTheme.getTheme(AppPalette.amber, isDark: false);
      expect(lightTheme.colorScheme.primary, const Color(0xFF92400E));
    });
  });

  group('ThemePaletteNotifier Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Defaults to midnight palette when no preference is saved', () {
      final notifier = ThemePaletteNotifier();
      expect(notifier.state, AppPalette.midnight);
    });

    test('Loads previously saved palette from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme_palette': 'amber'});
      final notifier = ThemePaletteNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state, AppPalette.amber);
    });

    test('setPalette updates state and persists to SharedPreferences', () async {
      final notifier = ThemePaletteNotifier();
      await notifier.setPalette(AppPalette.sage);
      expect(notifier.state, AppPalette.sage);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_palette'), 'sage');
    });

    test('Gracefully falls back to midnight on invalid saved palette key', () async {
      SharedPreferences.setMockInitialValues({'app_theme_palette': 'unknown_theme'});
      final notifier = ThemePaletteNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state, AppPalette.midnight);
    });
  });
}
