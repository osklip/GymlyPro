import 'package:flutter/material.dart';
import '../models/workout_session.dart';
import '../services/session_service.dart';

class SessionProvider extends ChangeNotifier {
  final SessionService _sessionService = SessionService();
  
  WorkoutSession? _currentSession;
  List<WorkoutSession> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  WorkoutSession? get currentSession => _currentSession;
  List<WorkoutSession> get history => _history;
  bool get isActive => _currentSession != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> startWorkout(int? planId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSession = await _sessionService.startSession(planId);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logSet(WorkoutSet workoutSet) async {
    if (_currentSession == null || _currentSession!.id == null) {
      throw Exception("Brak identyfikatora aktywnej sesji.");
    }

    try {
      final savedSet = await _sessionService.addSet(_currentSession!.id!, workoutSet);
      
      final updatedSets = List<WorkoutSet>.from(_currentSession!.sets)..add(savedSet);
      _currentSession = WorkoutSession(
        id: _currentSession!.id,
        userId: _currentSession!.userId,
        planId: _currentSession!.planId,
        startTime: _currentSession!.startTime,
        endTime: _currentSession!.endTime,
        totalVolume: _currentSession!.totalVolume,
        earnedPoints: _currentSession!.earnedPoints,
        sets: updatedSets,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  Future<WorkoutSession?> finishWorkout() async {
    if (_currentSession == null || _currentSession!.id == null) return null;
    
    _isLoading = true;
    notifyListeners();

    try {
      final finishedSession = await _sessionService.finishSession(_currentSession!.id!);
      _currentSession = null; 
      // Asynchroniczne odświeżenie historii w tle po udanym treningu
      fetchHistory();
      return finishedSession;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _history = await _sessionService.getHistory();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}