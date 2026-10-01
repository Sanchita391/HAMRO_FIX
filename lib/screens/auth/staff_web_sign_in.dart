import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hamro_fix/core/l10n/app_locale.dart';
import 'package:hamro_fix/screens/auth/admin/admin_signup.dart';
import 'package:hamro_fix/screens/auth/official/official_login.dart';
import 'package:hamro_fix/screens/auth/official/official_signup.dart';
import 'package:hamro_fix/widgets/staff_auth_shell.dart';

/// Web landing: Official and Admin open their own sign-in pages.
class StaffWebSignInPage extends StatefulWidget {
  const StaffWebSignInPage({super.key});

  @override
  State<StaffWebSignInPage> createState() => _StaffWebSignInPageState();
}

class _StaffWebSignInPageState extends State<StaffWebSignInPage> {
  int _localeIndex = 1;
  bool get _np => _localeIndex == 2;

  @override
  void initState() {
    super.initState();
    _localeIndex = AppLocale.instance.isEnglish ? 1 : 2;
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return StaffAuthShell(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _localeIndex = _np ? 1 : 2;
                        AppLocale.instance.setEnglish(!_np);
                      });
                    },
                    child: Text(_np ? 'English' : 'नेपाली'),
                  ),
                ),
                Text(
                  _np ? 'स्वागत छ' : 'Welcome Back',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A3D1A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _np
                      ? 'हाम्रोफिक्स व्यवस्थापन प्रणाली'
                      : 'Sign in to the HamroFix Management System',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _np
                      ? 'अधिकारी र एडमिनका लागि छुट्टाछुट्टै लगइन पृष्ठ छन्।'
                      : 'Official and Admin each have their own sign-in page.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 28),
                _choiceCard(
                  title: _np ? 'अधिकारी' : 'Official',
                  body: _np
                      ? 'वडा अधिकारी खाताबाट लगइन गर्नुहोस्।'
                      : 'Sign in with your ward official account.',
                  action: _np ? 'अधिकारी लगइन' : 'Official sign in',
                  onTap: () => _open(const OfficialLoginPage()),
                ),
                const SizedBox(height: 16),
                _choiceCard(
                  title: _np ? 'एडमिन' : 'Admin',
                  body: _np
                      ? 'प्रणाली प्रशासक खाताबाट लगइन गर्नुहोस्।'
                      : 'Sign in with your administrator account.',
                  action: _np ? 'एडमिन लगइन' : 'Admin sign in',
                  onTap: () => _open(const AdminSignupPage()),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _open(const OfficialSignupPage()),
                    child: Text(
                      _np
                          ? 'अधिकारी खाता चाहिन्छ? पहुँच अनुरोध गर्नुहोस्'
                          : 'Need an official account? Request access',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _choiceCard({
    required String title,
    required String body,
    required String action,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFA5D6A7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A3D1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(body, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A3D1A),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}
