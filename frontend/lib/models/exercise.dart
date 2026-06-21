class Exercise {
  final int id;
  final String name;
  final String targetMuscleGroup;
  final String equipmentType;
  final String movementType;

  Exercise({
    required this.id,
    required this.name,
    required this.targetMuscleGroup,
    required this.equipmentType,
    required this.movementType,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as int,
      name: json['name'] as String,
      targetMuscleGroup: json['target_muscle_group'] as String,
      equipmentType: json['equipment_type'] as String,
      movementType: json['movement_type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'target_muscle_group': targetMuscleGroup,
      'equipment_type': equipmentType,
      'movement_type': movementType,
    };
  }
}