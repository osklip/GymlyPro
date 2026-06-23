class AiSubstitute {
  final int originalExerciseId;
  final List<int> substituteExerciseIds;
  final String reasoning;

  AiSubstitute({
    required this.originalExerciseId,
    required this.substituteExerciseIds,
    required this.reasoning,
  });

  factory AiSubstitute.fromJson(Map<String, dynamic> json) {
    return AiSubstitute(
      originalExerciseId: json['original_exercise_id'] as int? ?? 0,
      substituteExerciseIds: (json['substitute_exercise_ids'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      reasoning: json['reasoning'] as String? ?? '',
    );
  }
}

class AiGuidance {
  final int exerciseId;
  final List<String> tips;
  final List<String> focusAreas;

  AiGuidance({
    required this.exerciseId,
    required this.tips,
    required this.focusAreas,
  });

  factory AiGuidance.fromJson(Map<String, dynamic> json) {
    return AiGuidance(
      exerciseId: json['exercise_id'] as int? ?? 0,
      tips: (json['tips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      focusAreas: (json['focus_areas'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}