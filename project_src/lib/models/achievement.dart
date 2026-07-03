class AchievementModel {
  final String id;
  final String title;
  final String description;
  final DateTime earnedDate;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.earnedDate,
  });

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? earnedDate,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      earnedDate: earnedDate ?? this.earnedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'earnedDate': earnedDate.toIso8601String(),
    };
  }

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      earnedDate: DateTime.parse(json['earnedDate'] as String),
    );
  }
}
