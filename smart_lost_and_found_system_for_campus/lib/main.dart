import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'screens/welcome_screen.dart';
import 'user_session.dart' show UserSession;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAOxm8UzBrE-qLME33SaBq7KDzzJQhM8T4",
        authDomain: "campuslostfound-c33e0.firebaseapp.com",
        projectId: "campuslostfound-c33e0",
        storageBucket: "campuslostfound-c33e0.firebasestorage.app",
        messagingSenderId: "219806345538",
        appId: "1:219806345538:web:ed3234f9609ee056b540db",
        measurementId: "G-SHP2GLHRYY",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  await UserSession.init(); // <--- Load the token from disk
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      themeMode: appState.themeMode,
      debugShowCheckedModeBanner: false,
      // LIGHT THEME CONFIG
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        cardColor: Colors.white,
      ),
      // DARK THEME CONFIG
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF3B82F6),
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Your Navy Blue
        cardColor: const Color(0xFF1E293B),
      ),
      home: const WelcomeScreen(),
    );
  }

}