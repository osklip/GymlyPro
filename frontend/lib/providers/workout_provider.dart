import 'package:flutter/material.dart';
import '../models/workout_plan.dart';
import '../services/workout_service.dart';

class WorkoutProvider extends ChangeNotifier {
  final WorkoutService _workoutService = WorkoutService();
  
  List<WorkoutPlan> _plans = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<WorkoutPlan> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPlans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _plans = await _workoutService.getMyPlans();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPlan(WorkoutPlan newPlan) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdPlan = await _workoutService.createPlan(newPlan);
      _plans.insert(0, createdPlan); // Wstawienie na początek listy
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removePlan(int planId) async {
    try {
      await _workoutService.deletePlan(planId);
      _plans.removeWhere((p) => p.id == planId);
      notifyListeners();
    } catch (e) {
      debugPrint("Błąd usuwania planu: $e");
      rethrow;
    }
  }

  Future<void> toggleActiveStatus(int planId) async {
    try {
      final updatedPlan = await _workoutService.togglePlanStatus(planId);
      final index = _plans.indexWhere((p) => p.id == planId);
      if (index != -1) {
        _plans[index] = updatedPlan;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Błąd przełączania statusu: $e");
      rethrow;
    }
  }
}