class PlanExercise {
  final int? id;
  final int? planId;
  final int exerciseId;
  final int order;
  final int targetSets;
  final int targetReps;
  final double? targetWeight;

  PlanExercise({
    this.id,
    this.planId,
    required this.exerciseId,
    required this.order,
    required this.targetSets,
    required this.targetReps,
    this.targetWeight,
  });

  factory PlanExercise.fromJson(Map<String, dynamic> json) {
    return PlanExercise(
      id: json['id'] as int?,
      planId: json['plan_id'] as int?,
      exerciseId: json['exercise_id'] as int,
      order: json['order'] as int,
      targetSets: json['target_sets'] as int,
      targetReps: json['target_reps'] as int,
      targetWeight: json['target_weight'] != null ? (json['target_weight'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'order': order,
      'target_sets': targetSets,
      'target_reps': targetReps,
      if (targetWeight != null) 'target_weight': targetWeight,
    };
  }
}

class WorkoutPlan {
  final int? id;
  final String? userId;
  final String name;
  final bool isActive;
  final DateTime? createdAt;
  final List<PlanExercise> exercises;

  WorkoutPlan({
    this.id,
    this.userId,
    required this.name,
    this.isActive = false,
    this.createdAt,
    this.exercises = const [],
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'] as int?,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => PlanExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'is_active': isActive,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}