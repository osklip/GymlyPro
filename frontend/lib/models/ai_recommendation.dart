class AiRecommendation {
  final int exerciseId;
  final double? suggestedWeight;
  final String message;

  AiRecommendation({
    required this.exerciseId,
    this.suggestedWeight,
    required this.message,
  });

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      exerciseId: json['exercise_id'] as int,
      suggestedWeight: json['suggested_weight'] != null ? (json['suggested_weight'] as num).toDouble() : null,
      message: json['message'] as String,
    );
  }
}