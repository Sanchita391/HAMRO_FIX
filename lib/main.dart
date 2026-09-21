import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hamro_fix/firebase_options.dart';
import 'package:hamro_fix/widgets/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization with options failed: $e');
    try {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized using platform native config');
    } catch (fallbackError) {
      debugPrint('Firebase initialization failed: $fallbackError');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  runApp(const HamroFixApp());
}

class HamroFixApp extends StatelessWidget {
  const HamroFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
