class MotivationUtils {
  static const List<String> categories = [
    'Fitness',
    'Study',
    'Faith',
    'Health',
    'Reading',
    'Work',
    'Custom',
  ];

  static String getDefaultMotivation(String category) {
    switch (category.toLowerCase()) {
      case 'fitness':
        return 'Consistency transforms the body and mind.';
      case 'study':
        return 'Knowledge is power built one day at a time.';
      case 'faith':
        return 'Small consistent deeds are most beloved.';
      case 'health':
        return 'Your health is an investment, not an expense.';
      case 'reading':
        return 'A chapter a day opens countless worlds.';
      case 'work':
        return 'Focus on progress, not perfection.';
      default:
        return 'A promise to myself to stay consistent every day.';
    }
  }
}
