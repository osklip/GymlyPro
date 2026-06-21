class BodyMeasurement {
  final int? id;
  final String? userId;
  final double weight;
  final double height;
  final double? bodyFatPercentage;
  final DateTime? measuredAt;

  BodyMeasurement({
    this.id,
    this.userId,
    required this.weight,
    required this.height,
    this.bodyFatPercentage,
    this.measuredAt,
  });

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      id: json['id'] as int?,
      userId: json['user_id'] as String?,
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      bodyFatPercentage: json['body_fat_percentage'] != null ? (json['body_fat_percentage'] as num).toDouble() : null,
      measuredAt: json['measured_at'] != null ? DateTime.parse(json['measured_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'height': height,
      if (bodyFatPercentage != null) 'body_fat_percentage': bodyFatPercentage,
    };
  }
}