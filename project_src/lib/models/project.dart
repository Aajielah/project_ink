enum ProjectStatus { upcoming, active, paused, frozen, completed }

enum RestMode { fixed, flexible, adaptive, sprint }

/// Parses the RestMode string in a backward-compatible manner.
RestMode parseRestMode(String value) {
  final lower = value.toLowerCase();
  if (lower == 'random') {
    return RestMode.adaptive;
  }
  return RestMode.values.byName(lower);
}

enum ProjectType { fixed, ongoing }

class ProjectModel {
  final String id;
  final String name;
  final String? description;
  final ProjectStatus status;
  final ProjectType projectType;
  final int targetWords;
  final int writtenWords;
  final int remainingWords;
  final int dailyWordTarget;
  final int backlogWords;
  final DateTime startDate;
  final DateTime expectedFinishDate;
  final DateTime? actualFinishDate;
  final RestMode restMode;
  final int allowedRestDays;
  final int remainingRestDays;
  final int projectStreak;
  final int longestProjectStreak;
  final int currentWeek;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? coverImagePath;
  final String? coverType;
  final int pendingCarryForward;
  final String ongoingStyle; // 'daily' or 'rhythm'
  final String writingSession; // 'none', 'morning', 'evening'

  const ProjectModel({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.projectType = ProjectType.fixed,
    required this.targetWords,
    required this.writtenWords,
    required this.remainingWords,
    required this.dailyWordTarget,
    required this.backlogWords,
    required this.startDate,
    required this.expectedFinishDate,
    this.actualFinishDate,
    required this.restMode,
    required this.allowedRestDays,
    required this.remainingRestDays,
    required this.projectStreak,
    required this.longestProjectStreak,
    required this.currentWeek,
    required this.createdAt,
    required this.updatedAt,
    this.coverImagePath,
    this.coverType,
    this.pendingCarryForward = 0,
    this.ongoingStyle = 'daily',
    this.writingSession = 'none',
  });



  ProjectModel copyWith({
    String? id,
    String? name,
    String? description,
    ProjectStatus? status,
    ProjectType? projectType,
    int? targetWords,
    int? writtenWords,
    int? remainingWords,
    int? dailyWordTarget,
    int? backlogWords,
    DateTime? startDate,
    DateTime? expectedFinishDate,
    DateTime? actualFinishDate,
    RestMode? restMode,
    int? allowedRestDays,
    int? remainingRestDays,
    int? projectStreak,
    int? longestProjectStreak,
    int? currentWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverImagePath,
    String? coverType,
    int? pendingCarryForward,
    String? ongoingStyle,
    String? writingSession,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      projectType: projectType ?? this.projectType,
      targetWords: targetWords ?? this.targetWords,
      writtenWords: writtenWords ?? this.writtenWords,
      remainingWords: remainingWords ?? this.remainingWords,
      dailyWordTarget: dailyWordTarget ?? this.dailyWordTarget,
      backlogWords: backlogWords ?? this.backlogWords,
      startDate: startDate ?? this.startDate,
      expectedFinishDate: expectedFinishDate ?? this.expectedFinishDate,
      actualFinishDate: actualFinishDate ?? this.actualFinishDate,
      restMode: restMode ?? this.restMode,
      allowedRestDays: allowedRestDays ?? this.allowedRestDays,
      remainingRestDays: remainingRestDays ?? this.remainingRestDays,
      projectStreak: projectStreak ?? this.projectStreak,
      longestProjectStreak: longestProjectStreak ?? this.longestProjectStreak,
      currentWeek: currentWeek ?? this.currentWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      coverType: coverType ?? this.coverType,
      pendingCarryForward: pendingCarryForward ?? this.pendingCarryForward,
      ongoingStyle: ongoingStyle ?? this.ongoingStyle,
      writingSession: writingSession ?? this.writingSession,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status.name,
      'projectType': projectType.name,
      'targetWords': targetWords,
      'writtenWords': writtenWords,
      'remainingWords': remainingWords,
      'dailyWordTarget': dailyWordTarget,
      'backlogWords': backlogWords,
      'startDate': startDate.toIso8601String(),
      'expectedFinishDate': expectedFinishDate.toIso8601String(),
      'actualFinishDate': actualFinishDate?.toIso8601String(),
      'restMode': restMode.name,
      'allowedRestDays': allowedRestDays,
      'remainingRestDays': remainingRestDays,
      'projectStreak': projectStreak,
      'longestProjectStreak': longestProjectStreak,
      'currentWeek': currentWeek,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'coverImagePath': coverImagePath,
      'coverType': coverType,
      'pendingCarryForward': pendingCarryForward,
      'ongoingStyle': ongoingStyle,
      'writingSession': writingSession,
    };
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: ProjectStatus.values.byName(json['status'] as String),
      projectType: ProjectType.values.byName(json['projectType'] as String? ?? 'fixed'),
      targetWords: json['targetWords'] as int,
      writtenWords: json['writtenWords'] as int,
      remainingWords: json['remainingWords'] as int,
      dailyWordTarget: json['dailyWordTarget'] as int,
      backlogWords: json['backlogWords'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      expectedFinishDate: DateTime.parse(json['expectedFinishDate'] as String),
      actualFinishDate: json['actualFinishDate'] != null
          ? DateTime.parse(json['actualFinishDate'] as String)
          : null,
      restMode: parseRestMode(json['restMode'] as String),
      allowedRestDays: json['allowedRestDays'] as int,
      remainingRestDays: json['remainingRestDays'] as int,
      projectStreak: json['projectStreak'] as int,
      longestProjectStreak: json['longestProjectStreak'] as int,
      currentWeek: json['currentWeek'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      coverImagePath: json['coverImagePath'] as String?,
      coverType: json['coverType'] as String?,
      pendingCarryForward: json['pendingCarryForward'] as int? ?? 0,
      ongoingStyle: json['ongoingStyle'] as String? ?? 'daily',
      writingSession: json['writingSession'] as String? ?? 'none',
    );
  }
}
