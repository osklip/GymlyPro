import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_session.dart';
import '../services/session_service.dart';

class SessionProvider extends ChangeNotifier {
  final SessionService _sessionService = SessionService();
  
  WorkoutSession? _currentSession;
  List<WorkoutSession> _history = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _skip = 0;
  final int _limit = 20;
  String? _errorMessage;

  // POPRAWKA: Dodanie modyfikatora 'static'
  static const String _diskKey = 'gymlypro_active_session_cache';

  SessionProvider() {
    tryRestoreSession();
  }

  WorkoutSession? get currentSession => _currentSession;
  List<WorkoutSession> get history => _history;
  bool get isActive => _currentSession != null;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  Future<void> _saveSessionToDisk() async {
    if (_currentSession == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(_currentSession!.toJson());
      await prefs.setString(_diskKey, jsonStr);
    } catch (e) {
      debugPrint('Błąd zapisu sesji na dysku: $e');
    }
  }

  Future<void> _clearSessionFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_diskKey);
      await prefs.remove('gymlypro_workout_draft');
    } catch (e) {
      debugPrint('Błąd czyszczenia dysku: $e');
    }
  }

  Future<bool> tryRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_diskKey);
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr);
        _currentSession = WorkoutSession.fromJson(decoded);
        notifyListeners();
        debugPrint('Odratowano aktywną sesję z dysku (ID: ${_currentSession?.id})');
        return true;
      }
    } catch (e) {
      debugPrint('Nie udało się przywrócić sesji z dysku: $e');
      await _clearSessionFromDisk();
    }
    return false;
  }

  Future<void> startWorkout(int? planId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSession = await _sessionService.startSession(planId);
      await _saveSessionToDisk(); 
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
      throw Exception("Brak aktywnej sesji.");
    }

    try {
      final savedSet = await _sessionService.addSet(_currentSession!.id!, workoutSet);
      final updatedSets = List<WorkoutSet>.from(_currentSession!.sets)..add(savedSet);
      _currentSession = WorkoutSession(
        id: _currentSession!.id, userId: _currentSession!.userId, planId: _currentSession!.planId,
        startTime: _currentSession!.startTime, endTime: _currentSession!.endTime,
        totalVolume: _currentSession!.totalVolume, earnedPoints: _currentSession!.earnedPoints, sets: updatedSets,
      );
      await _saveSessionToDisk(); 
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  Future<void> removeSet(int setId) async {
    if (_currentSession == null || _currentSession!.id == null) return;
    try {
      await _sessionService.deleteSet(_currentSession!.id!, setId);
      final updatedSets = _currentSession!.sets.where((s) => s.id != setId).toList();
      _currentSession = WorkoutSession(
        id: _currentSession!.id, userId: _currentSession!.userId, planId: _currentSession!.planId,
        startTime: _currentSession!.startTime, endTime: _currentSession!.endTime,
        totalVolume: _currentSession!.totalVolume, earnedPoints: _currentSession!.earnedPoints, sets: updatedSets,
      );
      await _saveSessionToDisk(); 
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
      await _clearSessionFromDisk(); 
      fetchHistory(refresh: true);
      return finishedSession;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh || _history.isEmpty) {
      _skip = 0; _hasMore = true; _isLoading = true; _errorMessage = null;
      notifyListeners();
      try {
        final fetched = await _sessionService.getHistory(skip: _skip, limit: _limit);
        _history = fetched; _skip += fetched.length; _hasMore = fetched.length == _limit;
      } catch (e) { _errorMessage = e.toString(); } finally { _isLoading = false; notifyListeners(); }
    }
  }

  Future<void> fetchMoreHistory() async {
    if (_isLoading || _isFetchingMore || !_hasMore) return;
    _isFetchingMore = true; _errorMessage = null; notifyListeners();
    try {
      final fetched = await _sessionService.getHistory(skip: _skip, limit: _limit);
      _history.addAll(fetched); _skip += fetched.length; _hasMore = fetched.length == _limit;
    } catch (e) { _errorMessage = e.toString(); } finally { _isFetchingMore = false; notifyListeners(); }
  }
}