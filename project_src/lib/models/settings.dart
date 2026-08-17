class SettingsModel {
  final String id;
  final String theme; // light, dark, system
  final bool notifications;
  final bool dailyQuotes;
  final bool backupReminder;
  final bool vibration;
  final int streakShields;

  const SettingsModel({
    required this.id,
    required this.theme,
    required this.notifications,
    required this.dailyQuotes,
    required this.backupReminder,
    required this.vibration,
    this.streakShields = 2,
  });

  SettingsModel copyWith({
    String? id,
    String? theme,
    bool? notifications,
    bool? dailyQuotes,
    bool? backupReminder,
    bool? vibration,
    int? streakShields,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      theme: theme ?? this.theme,
      notifications: notifications ?? this.notifications,
      dailyQuotes: dailyQuotes ?? this.dailyQuotes,
      backupReminder: backupReminder ?? this.backupReminder,
      vibration: vibration ?? this.vibration,
      streakShields: streakShields ?? this.streakShields,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'theme': theme,
      'notifications': notifications,
      'dailyQuotes': dailyQuotes,
      'backupReminder': backupReminder,
      'vibration': vibration,
      'streakShields': streakShields,
    };
  }

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      id: json['id'] as String,
      theme: json['theme'] as String,
      notifications: json['notifications'] as bool,
      dailyQuotes: json['dailyQuotes'] as bool,
      backupReminder: json['backupReminder'] as bool,
      vibration: json['vibration'] as bool,
      streakShields: json['streakShields'] as int? ?? 2,
    );
  }
}
