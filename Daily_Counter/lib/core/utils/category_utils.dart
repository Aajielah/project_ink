import 'package:flutter/material.dart';

class CategoryUtils {
  static IconData getIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'study':
        return Icons.school_rounded;
      case 'faith':
        return Icons.auto_awesome_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'reading':
        return Icons.menu_book_rounded;
      case 'work':
        return Icons.work_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  static Color getColor(String category, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (category.toLowerCase()) {
      case 'fitness':
        return isDark ? Colors.orangeAccent : Colors.orange;
      case 'study':
        return isDark ? Colors.blueAccent : Colors.blue;
      case 'faith':
        return isDark ? Colors.purpleAccent : Colors.purple;
      case 'health':
        return isDark ? Colors.redAccent : Colors.red;
      case 'reading':
        return isDark ? Colors.tealAccent : Colors.teal;
      case 'work':
        return isDark ? Colors.blueGrey : Colors.blueGrey;
      default:
        return isDark ? Colors.indigoAccent : Colors.indigo;
    }
  }
}
