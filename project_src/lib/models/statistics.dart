class StatisticsModel {
  final String id;
  final int lifetimeWords;
  final double averageWordsPerDay;
  final int currentGlobalStreak;
  final int longestGlobalStreak;
  final int projectsCompleted;
  final int writingDays;
  final int restDaysUsed;
  final int currentBacklog;

  const StatisticsModel({
    required this.id,
    required this.lifetimeWords,
    required this.averageWordsPerDay,
    required this.currentGlobalStreak,
    required this.longestGlobalStreak,
    required this.projectsCompleted,
    required this.writingDays,
    required this.restDaysUsed,
    required this.currentBacklog,
  });

  StatisticsModel copyWith({
    String? id,
    int? lifetimeWords,
    double? averageWordsPerDay,
    int? currentGlobalStreak,
    int? longestGlobalStreak,
    int? projectsCompleted,
    int? writingDays,
    int? restDaysUsed,
    int? currentBacklog,
  }) {
    return StatisticsModel(
      id: id ?? this.id,
      lifetimeWords: lifetimeWords ?? this.lifetimeWords,
      averageWordsPerDay: averageWordsPerDay ?? this.averageWordsPerDay,
      currentGlobalStreak: currentGlobalStreak ?? this.currentGlobalStreak,
      longestGlobalStreak: longestGlobalStreak ?? this.longestGlobalStreak,
      projectsCompleted: projectsCompleted ?? this.projectsCompleted,
      writingDays: writingDays ?? this.writingDays,
      restDaysUsed: restDaysUsed ?? this.restDaysUsed,
      currentBacklog: currentBacklog ?? this.currentBacklog,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lifetimeWords': lifetimeWords,
      'averageWordsPerDay': averageWordsPerDay,
      'currentGlobalStreak': currentGlobalStreak,
      'longestGlobalStreak': longestGlobalStreak,
      'projectsCompleted': projectsCompleted,
      'writingDays': writingDays,
      'restDaysUsed': restDaysUsed,
      'currentBacklog': currentBacklog,
    };
  }

  factory StatisticsModel.fromJson(Map<String, dynamic> json) {
    return StatisticsModel(
      id: json['id'] as String,
      lifetimeWords: json['lifetimeWords'] as int,
      averageWordsPerDay: (json['averageWordsPerDay'] as num).toDouble(),
      currentGlobalStreak: json['currentGlobalStreak'] as int,
      longestGlobalStreak: json['longestGlobalStreak'] as int,
      projectsCompleted: json['projectsCompleted'] as int,
      writingDays: json['writingDays'] as int,
      restDaysUsed: json['restDaysUsed'] as int,
      currentBacklog: json['currentBacklog'] as int,
    );
  }
}
