class UserProfile {
  final String id;
  final String displayName;
  final int totalPoints;
  final int level;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.totalPoints,
    required this.level,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      totalPoints: json['total_points'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}