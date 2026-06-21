import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';

class AchievementProvider extends ChangeNotifier {
  final AchievementService _service = AchievementService();

  List<Achievement> _allAchievements = [];
  List<UserAchievement> _userAchievements = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Achievement> get allAchievements => _allAchievements;
  List<UserAchievement> get userAchievements => _userAchievements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAchievements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getGlobalAchievements(),
        _service.getUserAchievements(),
      ]);

      _allAchievements = results[0] as List<Achievement>;
      _userAchievements = results[1] as List<UserAchievement>;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isUnlocked(int achievementId) {
    return _userAchievements.any((ua) => ua.achievementId == achievementId);
  }

  DateTime? getEarnedDate(int achievementId) {
    try {
      final match = _userAchievements.firstWhere((ua) => ua.achievementId == achievementId);
      return match.earnedAt;
    } catch (_) {
      return null;
    }
  }
}