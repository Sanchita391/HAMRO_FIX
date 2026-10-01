import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hamro_fix/core/l10n/app_locale.dart';
import 'package:hamro_fix/core/platform/app_target.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/screens/auth/landing_page.dart';
import 'package:hamro_fix/screens/auth/use_correct_app_page.dart';
import 'package:hamro_fix/screens/auth/worker/worker_signup.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/auth_services.dart';

class WorkerLoginPage extends StatefulWidget {
  const WorkerLoginPage({super.key});

  @override
  State<WorkerLoginPage> createState() => _WorkerLoginPageState();
}

class _WorkerLoginPageState extends State<WorkerLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isEnglish = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEnglish = AppLocale.instance.isEnglish;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateBackToLanding() {
    HapticFeedback.lightImpact();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LandingPage()),
      );
    }
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) {
      return _isEnglish ? 'Email is required' : 'इमेल आवश्यक छ';
    }
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(v.trim())) {
      return _isEnglish
          ? 'Enter a valid email address'
          : 'मान्य इमेल ठेगाना लेख्नुहोस्';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) {
      return _isEnglish ? 'Password is required' : 'पासवर्ड आवश्यक छ';
    }
    if (v.trim().length < 6) {
      return _isEnglish
          ? 'Password must be at least 6 characters'
          : 'पासवर्ड कम्तीमा ६ अक्षरको हुनुपर्छ';
    }
    return null;
  }

  Future<void> _handleSignIn() async {
    HapticFeedback.lightImpact();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthServices().loginWithEmail(
        email: _emailController.text,
        password: _passwordController.text.trim(),
        expectedRole: UserRole.worker,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthMessages.from(e)),
          backgroundColor: const Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  InputDecoration _field({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFE8F5E9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFA5D6A7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFA5D6A7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppTarget.isWeb) {
      return const LoginPlatformGuard(
        staffWebPage: false,
        child: SizedBox.shrink(),
      );
    }
    return Theme(
      data: kHamroFixLightGreenTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FBF4),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF6FBF4),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
            onPressed: _navigateBackToLanding,
          ),
          title: Text(
            _isEnglish ? 'Worker Sign In' : 'कामदार लगइन',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isEnglish = !_isEnglish;
                    AppLocale.instance.setEnglish(_isEnglish);
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                ),
                child: Text(_isEnglish ? 'नेपाली' : 'English'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFA5D6A7),
                              width: 1.2,
                            ),
                          ),
                          child: const HamroFixLogo(size: 52),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'HamroFix',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEnglish
                              ? 'Field worker sign in'
                              : 'फिल्ड कामदार लगइन',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF5EC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFC2C9BF).withValues(alpha: 0.6),
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _isEnglish ? 'Sign In' : 'लगइन',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => const WorkerSignupPage(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              child: Text(
                                _isEnglish ? 'Create Account' : 'नयाँ खाता',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    decoration: _field(
                      label: _isEnglish ? 'Email Address' : 'इमेल ठेगाना',
                      icon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                    decoration: _field(
                      label: _isEnglish ? 'Password' : 'पासवर्ड',
                      icon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _handleSignIn,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEnglish ? 'Sign In' : 'लगइन गर्नुहोस्'),
                    ),
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
