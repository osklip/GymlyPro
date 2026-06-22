import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _baseUrl = "http://10.0.2.2:8000";

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> signUp(
      String email, String password, String displayName) async {
    final creds = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await _syncUserWithBackend(displayName);
    return creds;
  }

  Future<void> _syncUserWithBackend(String displayName) async {
    final token = await _auth.currentUser?.getIdToken(true);
    final response = await http.post(
      Uri.parse('$_baseUrl/users/sync?display_name=$displayName'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Nie udało się zsynchronizować użytkownika z bazą');
    }
  }

  // NOWE: Wysłanie linku do resetu hasła
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // NOWE: Aktualizacja hasła zalogowanego użytkownika
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}