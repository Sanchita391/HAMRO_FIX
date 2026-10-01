import 'package:flutter/material.dart';

import 'package:hamro_fix/core/platform/app_target.dart';
import 'package:hamro_fix/core/theme/app_theme.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/screens/auth/landing_page.dart';
import 'package:hamro_fix/services/auth_services.dart';

class LoginPlatformGuard extends StatelessWidget {
  const LoginPlatformGuard({
    super.key,
    required this.staffWebPage,
    required this.child,
  });

  final bool staffWebPage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final allowed = staffWebPage ? AppTarget.isWeb : AppTarget.isMobileApp;
    if (allowed) return child;
    final title = staffWebPage
        ? 'Open this page in a web browser'
        : 'Open this page in the HamroFix phone app';
    final body = staffWebPage
        ? 'Official and Admin sign in on the HamroFix website, not on the phone.'
        : 'Public and worker sign in on the HamroFix phone app, not on this website.';
    return Scaffold(
      backgroundColor: HamroFixTheme.canvas,
      appBar: AppBar(
        title: const Text('HamroFix'),
        backgroundColor: HamroFixTheme.canvas,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HamroFixLogoBadge(size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(body, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Signed-in user opened the other product: public/worker use the phone app,
// official/admin use the website.
class UseCorrectAppPage extends StatelessWidget {
  const UseCorrectAppPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final role = profile.normalizedRole ?? profile.role ?? 'this account';
    final onWeb = AppTarget.isWeb;
    final title = onWeb
        ? 'Use the HamroFix mobile app'
        : 'Use the HamroFix website';
    final body = onWeb
        ? 'Public and worker accounts open on the phone app. This website is only for Official and Admin.'
        : 'Official and Admin accounts open in a web browser. This phone app is only for Public and Worker.';

    return Scaffold(
      backgroundColor: HamroFixTheme.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HamroFixLogoBadge(size: 56),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Signed in as $role.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () => AuthServices().signOut(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
