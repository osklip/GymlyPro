import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Dla emulatora Android używamy 10.0.2.2. Jeśli testujesz na Windows, zmień na 127.0.0.1
  final String _baseUrl = "http://10.0.2.2:8000"; 

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp(String email, String password, String displayName) async {
    final creds = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    
    // Po rejestracji w Firebase, synchronizujemy użytkownika z naszym backendem
    await _syncUserWithBackend(displayName);
    
    return creds;
  }

  Future<void> _syncUserWithBackend(String displayName) async {
    // Parametr true wymusza pobranie całkowicie nowego tokenu z serwerów Google,
    // omijając lokalną pamięć podręczną aplikacji.
    final token = await _auth.currentUser?.getIdToken(true);
    
    final response = await http.post(
      Uri.parse('$_baseUrl/users/sync?display_name=$displayName'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Nie udało się zsynchronizować użytkownika z bazą');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}