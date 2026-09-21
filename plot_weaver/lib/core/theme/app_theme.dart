import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.amberGold,
        onPrimary: Colors.black,
        secondary: AppColors.deepTeal,
        onSecondary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: Color(0xFFE6E8EC),
        surfaceContainerHighest: AppColors.darkSurfaceElevated,
        outline: AppColors.darkBorder,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFE6E8EC),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedIconTheme: const IconThemeData(color: AppColors.amberGold),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF8E9BAE)),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.amberGold,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: Color(0xFF8E9BAE),
          fontSize: 12,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.amberGold.withOpacity(0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.amberGold);
          }
          return const IconThemeData(color: Color(0xFF8E9BAE));
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.amberGold, width: 2),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.amberGold,
        onPrimary: Colors.black,
        secondary: AppColors.deepTeal,
        onSecondary: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: Color(0xFF2B2824),
        surfaceContainerHighest: AppColors.lightSurfaceElevated,
        outline: AppColors.lightBorder,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF2B2824),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.lightSurfaceElevated,
        selectedIconTheme: const IconThemeData(color: AppColors.amberGold),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF756F68)),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.amberGold,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: Color(0xFF756F68),
          fontSize: 12,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurfaceElevated,
        indicatorColor: AppColors.amberGold.withOpacity(0.2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.amberGold, width: 2),
        ),
      ),
    );
  }
}
