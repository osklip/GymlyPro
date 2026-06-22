class LeaderboardEntry {
  final String id;
  final String displayName;
  final int level;
  final double statValue;
  final String statLabel;

  LeaderboardEntry({
    required this.id,
    required this.displayName,
    required this.level,
    required this.statValue,
    required this.statLabel,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Nieznany',
      level: json['level'] as int? ?? 1,
      statValue: (json['stat_value'] as num?)?.toDouble() ?? 0.0,
      statLabel: json['stat_label'] as String? ?? 'pkt',
    );
  }
}