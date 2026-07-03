class SettingsModel {
  final String id;
  final String theme; // light, dark, system
  final bool notifications;
  final bool dailyQuotes;
  final bool backupReminder;
  final bool vibration;

  const SettingsModel({
    required this.id,
    required this.theme,
    required this.notifications,
    required this.dailyQuotes,
    required this.backupReminder,
    required this.vibration,
  });

  SettingsModel copyWith({
    String? id,
    String? theme,
    bool? notifications,
    bool? dailyQuotes,
    bool? backupReminder,
    bool? vibration,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      theme: theme ?? this.theme,
      notifications: notifications ?? this.notifications,
      dailyQuotes: dailyQuotes ?? this.dailyQuotes,
      backupReminder: backupReminder ?? this.backupReminder,
      vibration: vibration ?? this.vibration,
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
    );
  }
}
