class ScheduleModel {
  final String id;
  final String projectId;
  final DateTime date;
  final int plannedWords;
  final bool isRestDay;
  final bool completed;
  final bool automaticRestDay;
  final bool locked;
  final bool isRecoveryDay;
  final bool isShielded;

  const ScheduleModel({
    required this.id,
    required this.projectId,
    required this.date,
    required this.plannedWords,
    required this.isRestDay,
    required this.completed,
    required this.automaticRestDay,
    required this.locked,
    this.isRecoveryDay = false,
    this.isShielded = false,
  });

  ScheduleModel copyWith({
    String? id,
    String? projectId,
    DateTime? date,
    int? plannedWords,
    bool? isRestDay,
    bool? completed,
    bool? automaticRestDay,
    bool? locked,
    bool? isRecoveryDay,
    bool? isShielded,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      plannedWords: plannedWords ?? this.plannedWords,
      isRestDay: isRestDay ?? this.isRestDay,
      completed: completed ?? this.completed,
      automaticRestDay: automaticRestDay ?? this.automaticRestDay,
      locked: locked ?? this.locked,
      isRecoveryDay: isRecoveryDay ?? this.isRecoveryDay,
      isShielded: isShielded ?? this.isShielded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'date': date.toIso8601String(),
      'plannedWords': plannedWords,
      'isRestDay': isRestDay,
      'completed': completed,
      'automaticRestDay': automaticRestDay,
      'locked': locked,
      'isRecoveryDay': isRecoveryDay,
      'isShielded': isShielded,
    };
  }

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      date: DateTime.parse(json['date'] as String),
      plannedWords: json['plannedWords'] as int,
      isRestDay: json['isRestDay'] as bool,
      completed: json['completed'] as bool,
      automaticRestDay: json['automaticRestDay'] as bool,
      locked: json['locked'] as bool,
      isRecoveryDay: json['isRecoveryDay'] as bool? ?? false,
      isShielded: json['isShielded'] as bool? ?? false,
    );
  }
}
