class Achievement {
  final int id;
  final String name;
  final String description;
  final String? iconUrl;
  final int requiredPoints;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.requiredPoints,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Brak nazwy',
      description: json['description'] as String? ?? '',
      iconUrl: json['icon_url'] as String?,
      requiredPoints: json['required_points'] as int? ?? 0,
    );
  }
}

class UserAchievement {
  final String userId;
  final int achievementId;
  final DateTime earnedAt;

  UserAchievement({
    required this.userId,
    required this.achievementId,
    required this.earnedAt,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      userId: json['user_id'] as String? ?? '',
      achievementId: json['achievement_id'] as int? ?? 0,
      earnedAt: json['earned_at'] != null 
          ? DateTime.parse(json['earned_at'] as String) 
          : DateTime.now(),
    );
  }
}