import 'package:flutter/material.dart';
import '../models/ai_recommendation.dart';
import '../models/ai_models.dart';
import '../services/ai_service.dart';

class AiProvider extends ChangeNotifier {
  final AiService _aiService = AiService();
  
  final Map<int, bool> _loadingStates = {};

  bool isLoading(int exerciseId) {
    return _loadingStates[exerciseId] ?? false;
  }

  Future<AiRecommendation> fetchRecommendation(int exerciseId) async {
    _loadingStates[exerciseId] = true;
    notifyListeners();
    
    try {
      final rec = await _aiService.getWeightRecommendation(exerciseId);
      return rec;
    } finally {
      _loadingStates[exerciseId] = false;
      notifyListeners();
    }
  }

  Future<AiSubstitute> fetchSubstitutes(int exerciseId) async {
    _loadingStates[exerciseId] = true;
    notifyListeners();
    try {
      return await _aiService.getSubstitutes(exerciseId);
    } finally {
      _loadingStates[exerciseId] = false;
      notifyListeners();
    }
  }

  Future<AiGuidance> fetchGuidance(int exerciseId) async {
    _loadingStates[exerciseId] = true;
    notifyListeners();
    try {
      return await _aiService.getGuidance(exerciseId);
    } finally {
      _loadingStates[exerciseId] = false;
      notifyListeners();
    }
  }
}