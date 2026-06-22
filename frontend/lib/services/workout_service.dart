import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_plan.dart';

class WorkoutService {
  final String _baseUrl = "http://10.0.2.2:8000/plans";
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getToken() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Brak autoryzacji.');
    final token = await user.getIdToken();
    if (token == null) throw Exception('Błąd generowania tokenu Firebase.');
    return token;
  }

  Future<List<WorkoutPlan>> getPlans() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> raw = json.decode(utf8.decode(response.bodyBytes));
        return raw.map((item) => WorkoutPlan.fromJson(item)).toList();
      } else {
        throw Exception('Błąd pobierania planów: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Brak połączenia z serwerem.');
    }
  }

  Future<WorkoutPlan> createPlan(WorkoutPlan plan) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode(plan.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return WorkoutPlan.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Błąd tworzenia planu: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Brak połączenia z serwerem.');
    }
  }

  Future<void> deletePlan(int planId) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/$planId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Błąd usuwania planu: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Brak połączenia z serwerem.');
    }
  }

  Future<WorkoutPlan> toggleActive(int planId) async {
    try {
      final token = await _getToken();
      final response = await http.patch(
        Uri.parse('$_baseUrl/$planId/toggle'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return WorkoutPlan.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Błąd zmiany stanu planu: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Brak połączenia z serwerem.');
    }
  }

  // NOWE: Żądanie edycji planu
  Future<WorkoutPlan> updatePlan(WorkoutPlan plan) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/${plan.id}'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode(plan.toJson()),
      );

      if (response.statusCode == 200) {
        return WorkoutPlan.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Błąd edycji planu: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Brak połączenia z serwerem.');
    }
  }
}