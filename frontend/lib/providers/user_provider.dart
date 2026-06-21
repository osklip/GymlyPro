import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  
  UserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _userService.getProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Metoda wymuszająca aktualizację profilu (np. po pomyślnym zakończeniu treningu)
  Future<void> refreshProfile() async {
    try {
      _profile = await _userService.getProfile();
      notifyListeners();
    } catch (e) {
      debugPrint("Błąd odświeżania profilu w tle: $e");
    }
  }
}