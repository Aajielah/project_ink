import 'package:flutter/material.dart';

class AppColors {
  // Midnight Ink Palette (Dark Theme Base)
  static const Color darkBackground = Color(0xFF0F141C);
  static const Color darkSurface = Color(0xFF18202C);
  static const Color darkSurfaceElevated = Color(0xFF222D3E);
  static const Color darkBorder = Color(0xFF2E3D52);

  // Warm Parchment Palette (Light Theme Base)
  static const Color lightBackground = Color(0xFFF9F6F0);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF2ECE1);
  static const Color lightBorder = Color(0xFFE2D9C8);

  // Creative Ink Accents
  static const Color amberGold = Color(0xFFE5A93C);
  static const Color crimsonInk = Color(0xFFD94D58);
  static const Color deepTeal = Color(0xFF2A9D8F);
  static const Color violetLore = Color(0xFF8338EC);
  static const Color royalBlue = Color(0xFF3A86FF);
  static const Color emerald = Color(0xFF2EC4B6);

  // Aliases for intuitive semantic usage
  static const Color goldenHour = amberGold;
  static const Color crimsonArc = crimsonInk;
  static const Color emeraldGreen = emerald;

  // Role Badge Colors
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'protagonist':
        return amberGold;
      case 'antagonist':
        return crimsonInk;
      case 'mentor':
        return deepTeal;
      case 'foil':
        return violetLore;
      default:
        return royalBlue;
    }
  }

  // Cover Color Helper
  static Color getCoverAccent(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'crimson':
        return crimsonInk;
      case 'teal':
        return deepTeal;
      case 'violet':
        return violetLore;
      case 'blue':
        return royalBlue;
      case 'emerald':
        return emerald;
      case 'amber':
      default:
        return amberGold;
    }
  }
}
