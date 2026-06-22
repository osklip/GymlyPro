import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/leaderboard_entry.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  
  UserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  // Stan filtrów rankingu
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoadingLeaderboard = false;
  String _selectedCategory = 'points'; // points, volume, progression
  String _selectedTimeframe = 'all';   // all, month, week
  int? _myRank;
  LeaderboardEntry? _myLeaderboardEntry;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<LeaderboardEntry> get leaderboard => _leaderboard;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  String get selectedCategory => _selectedCategory;
  String get selectedTimeframe => _selectedTimeframe;
  int? get myRank => _myRank;
  LeaderboardEntry? get myLeaderboardEntry => _myLeaderboardEntry;

  Future<void> fetchProfile() async {
    _isLoading = true; _errorMessage = null; notifyListeners();
    try {
      _profile = await _userService.getProfile();
    } catch (e) { _errorMessage = e.toString(); } finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> refreshProfile() async {
    try {
      _profile = await _userService.getProfile();
      notifyListeners();
    } catch (_) {}
  }

  void setCategory(String cat) {
    _selectedCategory = cat;
    fetchLeaderboard();
  }

  void setTimeframe(String tf) {
    _selectedTimeframe = tf;
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    _isLoadingLeaderboard = true; _errorMessage = null; notifyListeners();
    try {
      _leaderboard = await _userService.getLeaderboard(category: _selectedCategory, timeframe: _selectedTimeframe, limit: 50);
      _calculateMyRank();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  void _calculateMyRank() {
    if (_profile == null || _leaderboard.isEmpty) {
      _myRank = null; _myLeaderboardEntry = null;
      return;
    }
    for (int i = 0; i < _leaderboard.length; i++) {
      if (_leaderboard[i].id == _profile!.id || _leaderboard[i].displayName == _profile!.displayName) {
        _myRank = i + 1;
        _myLeaderboardEntry = _leaderboard[i];
        return;
      }
    }
    _myRank = null; _myLeaderboardEntry = null;
  }
}