import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_session.dart';

class SessionService {
  final String _baseUrl = "http://10.0.2.2:8000";
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Brak autoryzacji. Sesja wymaga zalogowanego użytkownika.');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Nie udało się wygenerować tokenu dostępu Firebase.');
    }
    return token;
  }

  Future<WorkoutSession> startSession(int? planId) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/sessions/start'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'plan_id': planId}), 
      );

      if (response.statusCode == 201) {
        return WorkoutSession.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Błąd podczas uruchamiania sesji (Kod: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Brak połączenia z serwerem. Upewnij się, że FastAPI działa.');
    }
  }

  Future<WorkoutSet> addSet(int sessionId, WorkoutSet workoutSet) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/sessions/$sessionId/sets'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode(workoutSet.toJson()), 
      );

      if (response.statusCode == 201) {
        return WorkoutSet.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Błąd zapisu serii (Kod: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Brak sieci. Wynik serii nie został przesłany.');
    }
  }

  Future<void> deleteSet(int sessionId, int setId) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/sessions/$sessionId/sets/$setId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 204) {
        throw Exception('Błąd skasowania serii (Kod: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Brak sieci.');
    }
  }

  Future<WorkoutSession> finishSession(int sessionId) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/sessions/$sessionId/finish'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return WorkoutSession.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Nie udało się zakończyć treningu (Kod: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Brak sieci przy zamykaniu treningu.');
    }
  }

  // Zaktualizowana metoda pobierająca paczki danych
  Future<List<WorkoutSession>> getHistory({int skip = 0, int limit = 20}) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/sessions/history?skip=$skip&limit=$limit'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => WorkoutSession.fromJson(json)).toList();
      } else {
        throw Exception('Błąd pobierania historii (Kod: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Brak sieci. Historia treningów jest niedostępna offline.');
    }
  }
}