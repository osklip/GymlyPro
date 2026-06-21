import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';

class ExerciseProvider extends ChangeNotifier {
  final ExerciseService _exerciseService = ExerciseService();
  
  List<Exercise> _exercises = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Exercise> get exercises => _exercises;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchExercises() async {
    if (_exercises.isNotEmpty) {
      return; 
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _exercises = await _exerciseService.getExercises();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}