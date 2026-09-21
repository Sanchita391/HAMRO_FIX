import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/screens/auth/landing_page.dart';
import 'package:hamro_fix/screens/auth/worker/worker_signup.dart';
import 'package:hamro_fix/screens/dashboards/admin_dashboard.dart';
import 'package:hamro_fix/screens/dashboards/official_dashboard.dart';
import 'package:hamro_fix/screens/dashboards/public_dashboard.dart';
import 'package:hamro_fix/screens/dashboards/worker_dashboard.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/auth_services.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthServices();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AuthLoadingScreen();
        }
        final user = snapshot.data;
        if (user == null) {
          return const LandingPage();
        }
        return RoleRouter(uid: user.uid);
      },
    );
  }
}

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final auth = AuthServices();
    return StreamBuilder<UserProfile?>(
      stream: auth.watchProfile(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AuthLoadingScreen();
        }
        if (snapshot.hasError) {
          return AuthErrorScreen(
            message: AuthMessages.from(snapshot.error!),
            onRetry: () {},
          );
        }
        final profile = snapshot.data;
        if (profile == null) {
          return FutureBuilder<bool>(
            future: auth.hasPendingOfficialRequest(uid),
            builder: (context, pendingSnap) {
              if (!pendingSnap.hasData) {
                return const AuthLoadingScreen();
              }
              if (pendingSnap.data == true) {
                return const PendingVerificationPage();
              }
              return const AuthErrorScreen(
                message:
                    'Your account role has not been configured. Please contact the administrator.',
              );
            },
          );
        }

        final role = profile.normalizedRole;
        if (role == null || !UserRole.isKnown(role)) {
          return const AuthErrorScreen(
            message:
                'Your account role has not been configured. Please contact the administrator.',
          );
        }

        if (role == UserRole.worker && !profile.isApproved) {
          return const PendingVerificationPage();
        }

        return switch (role) {
          UserRole.public => PublicDashboard(profile: profile),
          UserRole.official => OfficialDashboard(profile: profile),
          UserRole.worker => WorkerDashboard(profile: profile),
          UserRole.admin => AdminDashboard(profile: profile),
          _ => const AuthErrorScreen(
            message:
                'Your account role has not been configured. Please contact the administrator.',
          ),
        };
      },
    );
  }
}

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF6FBF6),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      ),
    );
  }
}

class AuthErrorScreen extends StatelessWidget {
  const AuthErrorScreen({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFB71C1C),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => AuthServices().signOut(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),
                child: const Text('Back to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
