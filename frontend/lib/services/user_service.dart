import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/leaderboard_entry.dart';

class UserService {
  final String _baseUrl = "http://10.0.2.2:8000";
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getToken() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Brak autoryzacji.');
    final token = await user.getIdToken();
    if (token == null) throw Exception('Błąd generowania tokenu Firebase.');
    return token;
  }

  Future<UserProfile> getProfile() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/users/me'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return UserProfile.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Błąd pobierania profilu (Kod: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Brak połączenia z serwerem.');
    }
  }

  Future<List<LeaderboardEntry>> getLeaderboard({
    String category = 'points',
    String timeframe = 'all',
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/leaderboard?category=$category&timeframe=$timeframe&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> rawList = json.decode(utf8.decode(response.bodyBytes));
        return rawList.map((item) => LeaderboardEntry.fromJson(item)).toList();
      } else {
        throw Exception('Błąd pobierania rankingu (Kod: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Brak połączenia z serwerem.');
    }
  }
}