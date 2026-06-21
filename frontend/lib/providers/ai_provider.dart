import 'package:flutter/material.dart';
import '../models/ai_recommendation.dart';
import '../services/ai_service.dart';

class AiProvider extends ChangeNotifier {
  final AiService _aiService = AiService();
  final Map<int, bool> _loadingStates = {};

  bool isLoading(int exerciseId) => _loadingStates[exerciseId] ?? false;

  Future<AiRecommendation> fetchRecommendation(int exerciseId) async {
    _loadingStates[exerciseId] = true;
    notifyListeners();
    
    try {
      return await _aiService.getRecommendation(exerciseId);
    } finally {
      _loadingStates[exerciseId] = false;
      notifyListeners();
    }
  }
}