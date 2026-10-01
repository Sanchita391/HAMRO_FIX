// ============================================================================
// HamroFix - Official / Ward Sign In Page
// Visual language matches Citizen Registration.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hamro_fix/core/l10n/app_locale.dart';
import 'package:hamro_fix/core/platform/app_target.dart';
import 'package:hamro_fix/screens/auth/landing_page.dart';
import 'package:hamro_fix/screens/auth/use_correct_app_page.dart';
import 'package:hamro_fix/screens/auth/official/official_signup.dart';
import 'package:hamro_fix/widgets/staff_auth_shell.dart';
import 'package:hamro_fix/widgets/web_narrow_body.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/auth_services.dart';

class OfficialLoginPage extends StatefulWidget {
  const OfficialLoginPage({super.key});

  @override
  State<OfficialLoginPage> createState() => _OfficialLoginPageState();
}

class _OfficialLoginPageState extends State<OfficialLoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _employeeIdController = TextEditingController();
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
    _employeeIdController.dispose();
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
      return _isEnglish
          ? 'Official Email ID is required'
          : 'कार्यालयीन इमेल आवश्यक छ';
    }
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(v.trim())) {
      return _isEnglish
          ? 'Enter a valid email address'
          : 'मान्य इमेल ठेगाना लेख्नुहोस्';
    }
    return null;
  }

  String? _validateEmployeeId(String? v) {
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.trim().isEmpty) {
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

    if (!_formKey.currentState!.validate()) {
      _showSnack(
        _isEnglish
            ? 'Please check the required fields above'
            : 'कृपया माथिका आवश्यक विवरणहरू जाँच्नुहोस्',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthServices().loginWithEmail(
        email: _emailController.text,
        password: _passwordController.text.trim(),
        expectedRole: UserRole.official,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack(AuthMessages.from(e), isError: true);
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFB71C1C)
            : const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB71C1C)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 2),
      ),
    );
  }

  Widget _sectionHeader(String titleEn, String titleNp) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isEnglish ? titleEn : titleNp,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppTarget.isMobileApp) {
      return const LoginPlatformGuard(
        staffWebPage: true,
        child: SizedBox.shrink(),
      );
    }
    return StaffAuthShell(
      onBack: _navigateBackToLanding,
      child: SafeArea(
        child: WebNarrowBody(
          child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isEnglish = !_isEnglish;
                        AppLocale.instance.setEnglish(_isEnglish);
                      });
                    },
                    child: Text(_isEnglish ? 'नेपाली' : 'English'),
                  ),
                ),
                Text(
                  _isEnglish ? 'Official Sign In' : 'आधिकारिक लगइन',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A3D1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isEnglish
                      ? 'Sign in with credentials issued by the municipality'
                      : 'नगरपालिकाले दिएको प्रमाणपत्रबाट लगइन गर्नुहोस्',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
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
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2E7D32,
                                ).withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _isEnglish ? 'Sign In' : 'लगइन',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => const OfficialSignupPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            child: Text(
                              _isEnglish ? 'Request Access' : 'पहुँच अनुरोध',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _sectionHeader('Official Credentials', 'आधिकारिक प्रमाणपत्र'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  decoration: _inputDecoration(
                    label: _isEnglish
                        ? 'Official Email ID'
                        : 'कार्यालयीन इमेल आईडी',
                    hint: 'official@gov.np',
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _employeeIdController,
                  validator: _validateEmployeeId,
                  decoration: _inputDecoration(
                    label: _isEnglish
                        ? 'Employee ID (optional)'
                        : 'कर्मचारी आईडी (ऐच्छिक)',
                    hint: 'EMP-102938',
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: _validatePassword,
                  decoration: _inputDecoration(
                    label: _isEnglish ? 'Password' : 'पासवर्ड',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _isEnglish ? 'Sign In' : 'लगइन गर्नुहोस्',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final email = _emailController.text.trim();
                          if (email.isEmpty) {
                            _showSnack(
                              _isEnglish
                                  ? 'Enter your official email first'
                                  : 'पहिले आधिकारिक इमेल लेख्नुहोस्',
                              isError: true,
                            );
                            return;
                          }
                          try {
                            await AuthServices().sendStaffLoginEmail(email);
                            if (!mounted) return;
                            _showSnack(
                              _isEnglish
                                  ? 'Password reset email sent. Set a new password, then sign in.'
                                  : 'पासवर्ड रिसेट इमेल पठाइयो।',
                            );
                          } catch (e) {
                            if (!mounted) return;
                            _showSnack(AuthMessages.from(e), isError: true);
                          }
                        },
                  child: Text(
                    _isEnglish ? 'Forgot password? Email a reset link' : 'पासवर्ड बिर्सनुभयो?',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isEnglish
                      ? 'Official accounts are issued by municipality administrators. Use Request Access if you need credentials.'
                      : 'आधिकारिक खाता नगरपालिका प्रशासकले दिन्छन्। प्रमाणपत्र चाहिने भए पहुँच अनुरोध गर्नुहोस्।',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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
