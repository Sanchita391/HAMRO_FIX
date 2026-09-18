import 'package:flutter/material.dart';
import 'package:hamro_fix/screens/auth/landing_page.dart';

void main() {
  runApp(const HamroFixApp());
}

class HamroFixApp extends StatelessWidget {
  const HamroFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const LandingPage(),
    );
  }
}
