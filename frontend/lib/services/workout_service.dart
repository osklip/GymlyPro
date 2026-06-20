import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_plan.dart';

class WorkoutService {
  final String _baseUrl = "http://10.0.2.2:8000";
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Brak autoryzacji. Użytkownik nie jest zalogowany.');
    }
    // Wymuszenie odświeżenia tokenu zapobiega problemom z synchronizacją czasu
    final token = await user.getIdToken(true);
    if (token == null) {
      throw Exception('Nie udało się wygenerować tokenu dostępu.');
    }
    return token;
  }

  Future<List<WorkoutPlan>> getMyPlans() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/plans/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => WorkoutPlan.fromJson(json)).toList();
      } else {
        throw Exception('Błąd serwera HTTP: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Brak połączenia z serwerem. Upewnij się, że backend jest uruchomiony na hoście (Windows 11).');
    } catch (e) {
      throw Exception('Nieoczekiwany błąd: $e');
    }
  }

  Future<WorkoutPlan> createPlan(WorkoutPlan plan) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/plans/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(plan.toJson()),
      );

      if (response.statusCode == 201) {
        return WorkoutPlan.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Błąd serwera podczas tworzenia planu: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Brak połączenia sieciowego z serwerem.');
    } catch (e) {
      throw Exception('Nieoczekiwany błąd: $e');
    }
  }
}