class DailyLogModel {
  final String id;
  final String projectId;
  final String? scheduleId;
  final DateTime date;
  final int plannedWords;
  final int actualWords;
  final int carryForwardWords;
  final int backlogCreated;
  final bool completed;
  final DateTime loggedAt;

  const DailyLogModel({
    required this.id,
    required this.projectId,
    this.scheduleId,
    required this.date,
    required this.plannedWords,
    required this.actualWords,
    required this.carryForwardWords,
    required this.backlogCreated,
    required this.completed,
    required this.loggedAt,
  });

  DailyLogModel copyWith({
    String? id,
    String? projectId,
    String? scheduleId,
    DateTime? date,
    int? plannedWords,
    int? actualWords,
    int? carryForwardWords,
    int? backlogCreated,
    bool? completed,
    DateTime? loggedAt,
  }) {
    return DailyLogModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      scheduleId: scheduleId ?? this.scheduleId,
      date: date ?? this.date,
      plannedWords: plannedWords ?? this.plannedWords,
      actualWords: actualWords ?? this.actualWords,
      carryForwardWords: carryForwardWords ?? this.carryForwardWords,
      backlogCreated: backlogCreated ?? this.backlogCreated,
      completed: completed ?? this.completed,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'scheduleId': scheduleId,
      'date': date.toIso8601String(),
      'plannedWords': plannedWords,
      'actualWords': actualWords,
      'carryForwardWords': carryForwardWords,
      'backlogCreated': backlogCreated,
      'completed': completed,
      'loggedAt': loggedAt.toIso8601String(),
    };
  }

  factory DailyLogModel.fromJson(Map<String, dynamic> json) {
    return DailyLogModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      scheduleId: json['scheduleId'] as String?,
      date: DateTime.parse(json['date'] as String),
      plannedWords: json['plannedWords'] as int,
      actualWords: json['actualWords'] as int,
      carryForwardWords: json['carryForwardWords'] as int,
      backlogCreated: json['backlogCreated'] as int,
      completed: json['completed'] as bool,
      loggedAt: DateTime.parse(json['loggedAt'] as String),
    );
  }
}
