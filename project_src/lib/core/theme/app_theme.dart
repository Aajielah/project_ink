import 'package:flutter/material.dart';

enum AppPalette {
  midnight,
  amber,
  sage,
  royal,
}

extension AppPaletteExtension on AppPalette {
  String get displayName {
    switch (this) {
      case AppPalette.midnight:
        return 'Midnight Ink Glow';
      case AppPalette.amber:
        return 'Warm Literary & Amber';
      case AppPalette.sage:
        return 'Zen Forest & Sage';
      case AppPalette.royal:
        return 'Classic Royal Velvet';
    }
  }

  String get id => name;

  Color get previewPrimary {
    switch (this) {
      case AppPalette.midnight:
        return const Color(0xFF00E5FF);
      case AppPalette.amber:
        return const Color(0xFFF59E0B);
      case AppPalette.sage:
        return const Color(0xFF10B981);
      case AppPalette.royal:
        return const Color(0xFF6750A4);
    }
  }

  Color get previewSecondary {
    switch (this) {
      case AppPalette.midnight:
        return const Color(0xFF3B82F6);
      case AppPalette.amber:
        return const Color(0xFFF97316);
      case AppPalette.sage:
        return const Color(0xFF14B8A6);
      case AppPalette.royal:
        return const Color(0xFF7C4DFF);
    }
  }

  Color get previewDarkBg {
    switch (this) {
      case AppPalette.midnight:
        return const Color(0xFF090D16);
      case AppPalette.amber:
        return const Color(0xFF14100C);
      case AppPalette.sage:
        return const Color(0xFF0A1410);
      case AppPalette.royal:
        return const Color(0xFF0F0C1E);
    }
  }
}

class AppTheme {
  static ThemeData getTheme(AppPalette palette, {required bool isDark}) {
    return isDark ? _getDarkTheme(palette) : _getLightTheme(palette);
  }

  static ThemeData _getDarkTheme(AppPalette palette) {
    ColorScheme colorScheme;
    Color scaffoldBg;
    Color surfaceColor;
    Color cardColor;

    switch (palette) {
      case AppPalette.midnight:
        scaffoldBg = const Color(0xFF080C14);
        surfaceColor = const Color(0xFF0F1523);
        cardColor = const Color(0xFF131B2E);
        colorScheme = const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          onPrimary: Color(0xFF00363D),
          primaryContainer: Color(0xFF004F58),
          onPrimaryContainer: Color(0xFF80F2FF),
          secondary: Color(0xFF3B82F6),
          onSecondary: Color(0xFF002B73),
          secondaryContainer: Color(0xFF1D4ED8),
          onSecondaryContainer: Color(0xFFBFDBFE),
          tertiary: Color(0xFFA855F7),
          onTertiary: Color(0xFF4A044E),
          tertiaryContainer: Color(0xFF7E22CE),
          onTertiaryContainer: Color(0xFFF3E8FF),
          surface: Color(0xFF0F1523),
          onSurface: Color(0xFFF1F5F9),
          surfaceContainerHighest: Color(0xFF1E293B),
          onSurfaceVariant: Color(0xFF94A3B8),
          outline: Color(0xFF334155),
          outlineVariant: Color(0xFF1E293B),
        );
        break;

      case AppPalette.amber:
        scaffoldBg = const Color(0xFF130F0D);
        surfaceColor = const Color(0xFF1C1613);
        cardColor = const Color(0xFF241C18);
        colorScheme = const ColorScheme.dark(
          primary: Color(0xFFF59E0B),
          onPrimary: Color(0xFF451A03),
          primaryContainer: Color(0xFF78350F),
          onPrimaryContainer: Color(0xFFFDE68A),
          secondary: Color(0xFFF97316),
          onSecondary: Color(0xFF431407),
          secondaryContainer: Color(0xFF9A3412),
          onSecondaryContainer: Color(0xFFFFEDD5),
          tertiary: Color(0xFFD97706),
          onTertiary: Color(0xFF451A03),
          surface: Color(0xFF1C1613),
          onSurface: Color(0xFFFDF4E3),
          surfaceContainerHighest: Color(0xFF2D231E),
          onSurfaceVariant: Color(0xFFA89F91),
          outline: Color(0xFF4A3E37),
          outlineVariant: Color(0xFF2E241E),
        );
        break;

      case AppPalette.sage:
        scaffoldBg = const Color(0xFF09120F);
        surfaceColor = const Color(0xFF111F1A);
        cardColor = const Color(0xFF162923);
        colorScheme = const ColorScheme.dark(
          primary: Color(0xFF10B981),
          onPrimary: Color(0xFF022C22),
          primaryContainer: Color(0xFF065F46),
          onPrimaryContainer: Color(0xFFA7F3D0),
          secondary: Color(0xFF14B8A6),
          onSecondary: Color(0xFF042F2E),
          secondaryContainer: Color(0xFF0F766E),
          onSecondaryContainer: Color(0xFFCCFBF1),
          tertiary: Color(0xFF84CC16),
          onTertiary: Color(0xFF1A2E05),
          surface: Color(0xFF111F1A),
          onSurface: Color(0xFFECFDF5),
          surfaceContainerHighest: Color(0xFF1F382F),
          onSurfaceVariant: Color(0xFF8BA599),
          outline: Color(0xFF335345),
          outlineVariant: Color(0xFF1C3229),
        );
        break;

      case AppPalette.royal:
        scaffoldBg = const Color(0xFF0E0B1A);
        surfaceColor = const Color(0xFF171229);
        cardColor = const Color(0xFF201A38);
        colorScheme = const ColorScheme.dark(
          primary: Color(0xFFD0BCFF),
          onPrimary: Color(0xFF381E72),
          primaryContainer: Color(0xFF4F378B),
          onPrimaryContainer: Color(0xFFEADDFF),
          secondary: Color(0xFFCCC2DC),
          onSecondary: Color(0xFF332D41),
          secondaryContainer: Color(0xFF4A4458),
          onSecondaryContainer: Color(0xFFE8DEF8),
          tertiary: Color(0xFFEFB8C8),
          onTertiary: Color(0xFF492532),
          surface: Color(0xFF171229),
          onSurface: Color(0xFFE6E1E5),
          surfaceContainerHighest: Color(0xFF2A2342),
          onSurfaceVariant: Color(0xFFCAC4D0),
          outline: Color(0xFF49454F),
          outlineVariant: Color(0xFF2E2745),
        );
        break;
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardColor,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.6),
            width: 1.0,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
      ),
    );
  }

  static ThemeData _getLightTheme(AppPalette palette) {
    ColorScheme colorScheme;
    Color scaffoldBg = const Color(0xFFF8FAFC);

    switch (palette) {
      case AppPalette.midnight:
        colorScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF007799),
          brightness: Brightness.light,
          primary: const Color(0xFF006880),
          secondary: const Color(0xFF1E5BB0),
        );
        break;

      case AppPalette.amber:
        scaffoldBg = const Color(0xFFFAF7F2);
        colorScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFFB45309),
          brightness: Brightness.light,
          primary: const Color(0xFF92400E),
          secondary: const Color(0xFFC2410C),
        );
        break;

      case AppPalette.sage:
        scaffoldBg = const Color(0xFFF4F8F6);
        colorScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF059669),
          brightness: Brightness.light,
          primary: const Color(0xFF047857),
          secondary: const Color(0xFF0D9488),
        );
        break;

      case AppPalette.royal:
        scaffoldBg = const Color(0xFFF6F4FA);
        colorScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        );
        break;
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      cardTheme: CardThemeData(
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.4),
            width: 1.0,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
      ),
    );
  }
}
