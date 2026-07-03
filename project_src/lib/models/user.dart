class UserModel {
  final String id;
  final String name;
  final DateTime createdAt;
  final String themeMode;
  final bool notificationsEnabled;
  final bool dailyQuotesEnabled;

  const UserModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.themeMode,
    required this.notificationsEnabled,
    required this.dailyQuotesEnabled,
  });

  UserModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    String? themeMode,
    bool? notificationsEnabled,
    bool? dailyQuotesEnabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyQuotesEnabled: dailyQuotesEnabled ?? this.dailyQuotesEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'themeMode': themeMode,
      'notificationsEnabled': notificationsEnabled,
      'dailyQuotesEnabled': dailyQuotesEnabled,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      themeMode: json['themeMode'] as String,
      notificationsEnabled: json['notificationsEnabled'] as bool,
      dailyQuotesEnabled: json['dailyQuotesEnabled'] as bool,
    );
  }
}
