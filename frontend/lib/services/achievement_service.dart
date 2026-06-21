import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/achievement.dart';

class AchievementService {
  final String _baseUrl = "http://10.0.2.2:8000";
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Brak autoryzacji.');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Błąd generowania tokenu dostępu Firebase.');
    }
    return token;
  }

  Future<List<Achievement>> getGlobalAchievements() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/achievements/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Achievement.fromJson(json)).toList();
      } else {
        throw Exception('Błąd pobierania definicji osiągnięć (Kod: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Brak połączenia z serwerem FastAPI.');
    }
  }

  Future<List<UserAchievement>> getUserAchievements() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/achievements/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => UserAchievement.fromJson(json)).toList();
      } else {
        throw Exception('Błąd pobierania odznak użytkownika (Kod: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Brak połączenia z serwerem FastAPI.');
    }
  }
}