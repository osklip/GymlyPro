class WorkoutSet {
  final int? id;
  final int? sessionId;
  final int exerciseId;
  final int setNumber;
  final int reps;
  final double weight;
  final int? rpe;
  final bool isSuccessful;
  final double? aiSuggestedWeight;
  final bool isWarmup;

  WorkoutSet({
    this.id,
    this.sessionId,
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.rpe,
    this.isSuccessful = true,
    this.aiSuggestedWeight,
    this.isWarmup = false,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      id: json['id'] as int?,
      sessionId: json['session_id'] as int?,
      exerciseId: json['exercise_id'] as int,
      setNumber: json['set_number'] as int,
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
      rpe: json['rpe'] as int?,
      isSuccessful: json['is_successful'] as bool? ?? true,
      aiSuggestedWeight: json['ai_suggested_weight'] != null ? (json['ai_suggested_weight'] as num).toDouble() : null,
      isWarmup: json['is_warmup'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'set_number': setNumber,
      'reps': reps,
      'weight': weight,
      if (rpe != null) 'rpe': rpe,
      'is_successful': isSuccessful,
      if (aiSuggestedWeight != null) 'ai_suggested_weight': aiSuggestedWeight,
      'is_warmup': isWarmup,
    };
  }
}

class WorkoutSession {
  final int? id;
  final String? userId;
  final int? planId;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalVolume;
  final int earnedPoints;
  final List<WorkoutSet> sets;

  WorkoutSession({
    this.id,
    this.userId,
    this.planId,
    required this.startTime,
    this.endTime,
    this.totalVolume = 0.0,
    this.earnedPoints = 0,
    this.sets = const [],
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as int?,
      userId: json['user_id'] as String?,
      planId: json['plan_id'] as int?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0.0,
      earnedPoints: json['earned_points'] as int? ?? 0,
      sets: (json['sets'] as List<dynamic>?)
              ?.map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (planId != null) 'plan_id': planId,
      'start_time': startTime.toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toIso8601String(),
      'total_volume': totalVolume,
      'earned_points': earnedPoints,
      'sets': sets.map((e) => e.toJson()).toList(),
    };
  }
}