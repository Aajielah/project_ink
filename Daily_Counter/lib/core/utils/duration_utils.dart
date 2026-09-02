class DurationUtils {
  static const List<String> units = [
    'Days',
    'Weeks',
    'Months',
    'Years',
    'Custom Range',
  ];

  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int calculateTotalDays({
    required String unit,
    required int value,
    required DateTime startDate,
    DateTime? customEndDate,
  }) {
    final normStart = normalizeDate(startDate);
    switch (unit) {
      case 'Days':
        return value > 0 ? value : 1;
      case 'Weeks':
        return value > 0 ? value * 7 : 7;
      case 'Months':
        final endMonth = DateTime(normStart.year, normStart.month + value, normStart.day);
        final diff = endMonth.difference(normStart).inDays;
        return diff > 0 ? diff : value * 30;
      case 'Years':
        final endYear = DateTime(normStart.year + value, normStart.month, normStart.day);
        final diff = endYear.difference(normStart).inDays;
        return diff > 0 ? diff : value * 365;
      case 'Custom Range':
        if (customEndDate != null) {
          final normEnd = normalizeDate(customEndDate);
          final diff = normEnd.difference(normStart).inDays + 1;
          return diff > 0 ? diff : 1;
        }
        return value > 0 ? value : 1;
      default:
        return value > 0 ? value : 1;
    }
  }

  /// Calculates the exact calendar end date without DST duration drift.
  static DateTime calculateEndDate(DateTime startDate, int targetDays) {
    final normStart = normalizeDate(startDate);
    if (targetDays <= 1) return normStart;
    return DateTime(normStart.year, normStart.month, normStart.day + targetDays - 1);
  }

  static String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
