import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ai_recommendation.dart';
import '../models/ai_models.dart';

class AiService {
  final String _baseUrl = "http://10.0.2.2:8000/ai";

  Future<String> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Brak zalogowanego użytkownika');
    return await user.getIdToken() ?? '';
  }

  Future<AiRecommendation> getWeightRecommendation(int exerciseId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/recommendation/$exerciseId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return AiRecommendation.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Błąd pobierania rekomendacji ciężaru: ${response.statusCode}');
    }
  }

  Future<AiSubstitute> getSubstitutes(int exerciseId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/substitute/$exerciseId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return AiSubstitute.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Błąd silnika AI: ${response.statusCode}');
    }
  }

  Future<AiGuidance> getGuidance(int exerciseId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/guidance/$exerciseId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return AiGuidance.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Błąd silnika AI: ${response.statusCode}');
    }
  }
}