import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:hamro_fix/core/platform/app_target.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/screens/auth/landing_page.dart';
import 'package:hamro_fix/screens/auth/worker/worker_signup.dart';
import 'package:hamro_fix/screens/dashboards/admin_dashboard.dart';
import 'package:hamro_fix/screens/dashboards/official_dashboard.dart';
import 'package:hamro_fix/screens/dashboards/public_dashboard.dart';
import 'package:hamro_fix/screens/dashboards/worker_dashboard.dart';
import 'package:hamro_fix/screens/auth/use_correct_app_page.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/auth_services.dart';

// Watches Firebase Auth. Logged-out users see the landing page.
// Logged-in users go to RoleRouter, which picks the correct dashboard.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthServices();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data ?? auth.currentUser;
        if (snapshot.connectionState == ConnectionState.waiting &&
            user == null) {
          return const AuthLoadingScreen();
        }
        // No Auth session: show Register / Sign in.
        if (user == null) {
          return const LandingPage();
        }
        return RoleRouter(
          key: ValueKey(user.uid),
          uid: user.uid,
          firebaseUser: user,
        );
      },
    );
  }
}

// Loads users/{uid} and decides: pending, blocked, verify email, or a role dashboard.
class RoleRouter extends StatefulWidget {
  const RoleRouter({
    super.key,
    required this.uid,
    required this.firebaseUser,
  });

  final String uid;
  final User firebaseUser;

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  int _retryToken = 0;
  UserProfile? _cachedProfile;

  @override
  void initState() {
    super.initState();
    _prefetch();
  }

  // Read the profile once so the screen is not empty while the stream starts.
  Future<void> _prefetch() async {
    try {
      await FirebaseFirestore.instance.enableNetwork();
    } catch (_) {}
    try {
      final profile = await AuthServices().fetchProfile(widget.uid);
      if (mounted) setState(() => _cachedProfile = profile);
    } catch (_) {}
  }

  Future<void> _retry() async {
    try {
      await FirebaseFirestore.instance.enableNetwork();
    } catch (_) {}
    await _prefetch();
    if (mounted) setState(() => _retryToken++);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthServices();
    return StreamBuilder<UserProfile?>(
      key: ValueKey(_retryToken),
      stream: auth.watchProfile(widget.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null &&
            _cachedProfile == null) {
          return const AuthLoadingScreen();
        }
        if (snapshot.hasError && snapshot.data == null && _cachedProfile == null) {
          return AuthErrorScreen(
            message: AuthMessages.from(snapshot.error!),
            onRetry: _retry,
          );
        }
        final profile = snapshot.data ?? _cachedProfile;
        if (profile == null) {
          return FutureBuilder<bool>(
            future: auth.hasPendingOfficialRequest(widget.uid),
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

        // Rejected, blacklisted, or not yet approved staff cannot open a dashboard.
        if (profile.isRejected) {
          return const AuthErrorScreen(
            message:
                'This application was not approved. Please contact the administrator.',
          );
        }
        if (profile.isRestricted) {
          return AuthErrorScreen(
            message: profile.isBlacklisted
                ? 'This account has been blacklisted.'
                : 'This account is currently restricted.',
          );
        }
        if ((role == UserRole.worker || role == UserRole.official) &&
            !profile.isApproved) {
          return const PendingVerificationPage();
        }
        if (profile.mustChangePassword) {
          return PasswordChangeScreen(profile: profile);
        }
        // Public users must verify email before they can report issues.
        if (role == UserRole.public && !widget.firebaseUser.emailVerified) {
          return EmailVerificationScreen(user: widget.firebaseUser);
        }

        // Same Auth user, but official/admin use the website and public/worker use the phone.
        if (!AppTarget.roleCanUseThisApp(role)) {
          return UseCorrectAppPage(profile: profile);
        }

        // Open the dashboard that matches the role stored in Firestore.
        if (role == UserRole.public) {
          return PublicDashboard(profile: profile);
        }
        if (role == UserRole.official) {
          return OfficialDashboard(profile: profile);
        }
        if (role == UserRole.worker) {
          return WorkerDashboard(profile: profile);
        }
        if (role == UserRole.admin) {
          return AdminDashboard(profile: profile);
        }
        return const AuthErrorScreen(
          message:
              'Your account role has not been configured. Please contact the administrator.',
        );
      },
    );
  }
}

// Public role: ask the user to confirm their email in Firebase Auth.
class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key, required this.user});
  final User user;

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
              const Icon(Icons.mark_email_unread_outlined, size: 56, color: Color(0xFF2E7D32)),
              const SizedBox(height: 16),
              Text(
                'Verify ${user.email} to start reporting civic issues.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => AuthServices().sendVerificationEmail(),
                child: const Text('Resend verification email'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await AuthServices().reloadCurrentUser();
                  await FirebaseAuth.instance.currentUser?.reload();
                },
                child: const Text('I have verified'),
              ),
              TextButton(
                onPressed: () => AuthServices().signOut(),
                child: const Text('Back to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Staff accounts created by admin/official must set a new password first.
class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key, required this.profile});
  final UserProfile profile;

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

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
              const Text(
                'Set a new password before continuing.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _current,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Temporary or current password',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _next,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        try {
                          await AuthServices().changePassword(
                            currentPassword: _current.text,
                            newPassword: _next.text,
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AuthMessages.from(e))),
                          );
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
                child: Text(_busy ? 'Saving...' : 'Update password'),
              ),
            ],
          ),
        ),
      ),
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
              if (onRetry != null) ...[
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try again'),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton(
                onPressed: () => AuthServices().signOut(),
                style: FilledButton.styleFrom(
                  backgroundColor: onRetry == null
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF6D6D6D),
                  foregroundColor: Colors.white,
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
