import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ai_recommendation.dart';

class AiService {
  final String _baseUrl = "http://10.0.2.2:8000";
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Brak autoryzacji.');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Błąd weryfikacji tokenu dostępu.');
    }
    return token;
  }

  Future<AiRecommendation> getRecommendation(int exerciseId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/ai/recommendation/$exerciseId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return AiRecommendation.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Błąd serwera. Kod błędu: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Brak komunikacji. Upewnij się, że FastAPI działa w systemie Windows 11.');
    } catch (e) {
      throw Exception('Wystąpił nieoczekiwany błąd strumienia AI: $e');
    }
  }
}