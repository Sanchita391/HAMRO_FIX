import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hamro_fix/core/network/ipv4_http_stub.dart'
    if (dart.library.io) 'package:hamro_fix/core/network/ipv4_http_io.dart';
import 'package:hamro_fix/core/l10n/app_locale.dart';
import 'package:hamro_fix/core/theme/app_theme.dart';
import 'package:hamro_fix/firebase_options.dart';
import 'package:hamro_fix/widgets/auth_gate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// App entry: start Flutter, connect Firebase, then show HamroFixApp.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installIpv4PreferredNetworking();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  try {
    // Load Firebase using the project settings in firebase_options.dart.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Phone cache only. On Chrome this setting can block login.
    if (!kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
    }
    try {
      await FirebaseFirestore.instance.enableNetwork();
    } catch (_) {}
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

// Root widget: theme, English/Nepali wrapper, then AuthGate for login routing.
class HamroFixApp extends StatelessWidget {
  const HamroFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: HamroFixTheme.light(),
      home: LocaleScope(child: const AuthGate()),
    );
  }
}
