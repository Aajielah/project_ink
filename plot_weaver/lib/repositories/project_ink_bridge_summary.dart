class ProjectInkBookSummary {
  final String id;
  final String name;
  final int targetWords;
  final int writtenWords;
  final int streak;
  final String status;

  const ProjectInkBookSummary({
    required this.id,
    required this.name,
    required this.targetWords,
    required this.writtenWords,
    required this.streak,
    required this.status,
  });

  double get progressPercentage {
    if (targetWords <= 0) return 0;
    return (writtenWords / targetWords).clamp(0.0, 1.0);
  }
}
