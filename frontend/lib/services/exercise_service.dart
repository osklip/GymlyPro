import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/exercise.dart';

class ExerciseService {
  final String _baseUrl = "http://10.0.2.2:8000";
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Brak autoryzacji. Zaloguj się ponownie.');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Błąd weryfikacji tokenu dostępu.');
    }
    return token;
  }

  Future<List<Exercise>> getExercises() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/exercises/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Exercise.fromJson(json)).toList();
      } else {
        throw Exception('Nie udało się pobrać listy ćwiczeń. Kod błędu: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Błąd komunikacji z serwerem. Upewnij się, że backend funkcjonuje poprawnie w środowisku Windows.');
    } catch (e) {
      throw Exception('Wystąpił nieoczekiwany błąd strumienia: $e');
    }
  }
}