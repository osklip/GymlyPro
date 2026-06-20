import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/workout_provider.dart';
import 'screens/login_screen.dart';
import 'screens/plans_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB033Y7JK1X1Hwjjq4HX2w55JD-CUANZgs",
        appId: "1:1035896017078:android:e66cdce4ca42d926fa1617",
        messagingSenderId: "1035896017078",
        projectId: "gymlypro",
        storageBucket: "gymlypro.firebasestorage.app",
      ),
    );
    debugPrint("Firebase zainicjalizowany pomyślnie.");
  } catch (e) {
    debugPrint('Błąd inicjalizacji Firebase: $e');
  }

  runApp(const GymlyProApp());
}

class GymlyProApp extends StatelessWidget {
  const GymlyProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
      ],
      child: MaterialApp(
        title: 'GymlyPro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFF1E1E2C),
          ),
        ),
        home: const AuthenticationWrapper(),
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          return const PlansScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}