import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/username_setup_screen.dart';
import 'screens/email_verification_screen.dart';
import 'services/auth_service.dart';
import 'services/onboarding_service.dart';
import 'services/image_preload_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Support all orientations for iPad multitasking and better device compatibility
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Listick',
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFE91E63),
          onPrimary: Colors.white,
          secondary: Color(0xFF9C27B0),
          onSecondary: Colors.white,
          surface: Color(0xFF0A0A0A),
          onSurface: Colors.white,
          error: Color(0xFFE53E3E),
          onError: Colors.white,
          outline: Color(0xFF2A2A2A),
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 0,
          color: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE91E63)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          labelStyle: const TextStyle(color: Colors.white),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.userVerificationChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: Center(child: CircularProgressIndicator())),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;

          // Check if user needs email verification first
          if (_authService.needsEmailVerification(user)) {
            return EmailVerificationScreen(user: user);
          }

          // Check if user needs onboarding
          return FutureBuilder<Map<String, dynamic>>(
            future: OnboardingService().getOnboardingProgress(user.uid),
            builder: (context, onboardingSnapshot) {
              if (onboardingSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (onboardingSnapshot.hasData) {
                final progress = onboardingSnapshot.data!;

                // Check if user has completed all onboarding steps
                if (progress['hasUsername'] == true &&
                    progress['hasAvatar'] == true &&
                    progress['hasInterests'] == true) {
                  return const HomeScreen();
                }
              }

              // User needs onboarding - start with username setup
              return const UsernameSetupScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
