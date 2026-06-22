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
    _isLoading = true; _errorMessage = null; notifyListeners();
    try {
      _plans = await _workoutService.getPlans();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPlan(WorkoutPlan plan) async {
    _isLoading = true; _errorMessage = null; notifyListeners();
    try {
      final created = await _workoutService.createPlan(plan);
      _plans.insert(0, created);
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
      _errorMessage = e.toString();
      rethrow;
    }
  }

  Future<void> toggleActiveStatus(int planId) async {
    try {
      final updated = await _workoutService.toggleActive(planId);
      final idx = _plans.indexWhere((p) => p.id == planId);
      if (idx != -1) {
        _plans[idx] = updated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  // NOWE: Aktualizacja obiektu planu w lokalnej pamięci RAM
  Future<void> updatePlan(WorkoutPlan plan) async {
    _isLoading = true; _errorMessage = null; notifyListeners();
    try {
      final updated = await _workoutService.updatePlan(plan);
      final idx = _plans.indexWhere((p) => p.id == updated.id);
      if (idx != -1) {
        _plans[idx] = updated;
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}