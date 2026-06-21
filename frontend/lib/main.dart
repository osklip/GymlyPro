import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/session_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/exercise_provider.dart';
import 'screens/login_screen.dart';
import 'providers/ai_provider.dart';
import 'screens/main_screen.dart';
import 'providers/user_provider.dart';
import 'providers/measurement_provider.dart';
import 'providers/achievement_provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
    const primaryEmerald = Color(0xFF10B981);
    const darkSlateText = Color(0xFF0F172A);
    const lightSurfaceBg = Color(0xFFF8FAFC);
    const containerHighBg = Color(0xFFF1F5F9);
    const cardBorderColor = Color(0xFFE2E8F0);

    final baseTextTheme = ThemeData.light().textTheme;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MeasurementProvider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
      ],
      child: MaterialApp(
        title: 'GymlyPro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: const ColorScheme.light(
            primary: primaryEmerald,
            onPrimary: Colors.white,
            secondary: Color(0xFF0EA5E9),
            onSecondary: Colors.white,
            surface: lightSurfaceBg,
            onSurface: darkSlateText,
            surfaceContainerLow: Colors.white,
            surfaceContainer: containerHighBg,
            surfaceContainerHigh: Color(0xFFE2E8F0),
            error: Color(0xFFEF4444),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: lightSurfaceBg,
          textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTextTheme).apply(
            bodyColor: darkSlateText,
            displayColor: darkSlateText,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: lightSurfaceBg,
            foregroundColor: darkSlateText,
            elevation: 0,
            centerTitle: false,
          ),
          // POPRAWKA: Zastosowanie CardThemeData
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: cardBorderColor, width: 1),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: containerHighBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: primaryEmerald, width: 2),
            ),
            labelStyle: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: darkSlateText,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
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
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}