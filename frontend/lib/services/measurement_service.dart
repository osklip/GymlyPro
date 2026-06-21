import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/body_measurement.dart';

class MeasurementService {
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

  Future<List<BodyMeasurement>> getMeasurements() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/measurements/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => BodyMeasurement.fromJson(json)).toList();
      } else {
        throw Exception('Błąd podczas pobierania pomiarów (Kod: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Brak połączenia z lokalnym serwerem.');
    }
  }

  Future<BodyMeasurement> addMeasurement(BodyMeasurement measurement) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/measurements/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(measurement.toJson()),
      );

      if (response.statusCode == 201) {
        return BodyMeasurement.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Błąd zapisu pomiaru na serwerze (Kod: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Brak połączenia z siecią. Zapis anulowany.');
    }
  }
}