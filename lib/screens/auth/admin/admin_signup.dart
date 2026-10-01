// ============================================================================
// HamroFix - Admin Login
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hamro_fix/core/l10n/app_locale.dart';
import 'package:hamro_fix/core/platform/app_target.dart';
import 'package:hamro_fix/screens/auth/landing_page.dart';
import 'package:hamro_fix/screens/auth/use_correct_app_page.dart';
import 'package:hamro_fix/widgets/staff_auth_shell.dart';
import 'package:hamro_fix/widgets/web_narrow_body.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/auth_services.dart';

class AdminSignupPage extends StatefulWidget {
  const AdminSignupPage({super.key});

  @override
  State<AdminSignupPage> createState() => _AdminSignupPageState();
}

class _AdminSignupPageState extends State<AdminSignupPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isEnglish = true;
  bool _obscurePin = true;
  bool _isLoading = false;
  bool _signInTab = true;
  bool _bootstrapOpen = false;
  bool _checkingBootstrap = true;

  @override
  void initState() {
    super.initState();
    _isEnglish = AppLocale.instance.isEnglish;
    _loadBootstrap();
  }

  Future<void> _loadBootstrap() async {
    try {
      final open = await AuthServices().isAdminBootstrapOpen();
      if (!mounted) return;
      setState(() {
        _bootstrapOpen = open;
        _checkingBootstrap = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bootstrapOpen = false;
        _checkingBootstrap = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _isEnglish
          ? 'Admin email or username is required'
          : 'एडमिन इमेल वा प्रयोगकर्ता नाम आवश्यक छ';
    }
    return null;
  }

  String? _validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return _isEnglish ? 'Password is required' : 'पासवर्ड आवश्यक छ';
    }

    if (value.length < 6) {
      return _isEnglish
          ? 'Password must be at least 6 characters'
          : 'पासवर्ड कम्तीमा ६ अक्षरको हुनुपर्छ';
    }

    return null;
  }

  Future<void> _handleLogin() async {
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

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthServices().loginAdmin(
        identifier: _usernameController.text,
        password: _pinController.text,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showSnack(AuthMessages.from(e), isError: true);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _handleBootstrap() async {
    HapticFeedback.lightImpact();
    if (_nameController.text.trim().length < 3) {
      _showSnack(
        _isEnglish ? 'Enter the admin full name' : 'एडमिनको पूरा नाम लेख्नुहोस्',
        isError: true,
      );
      return;
    }
    final email = _emailController.text.trim();
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email)) {
      _showSnack(
        _isEnglish ? 'Enter a valid admin email' : 'मान्य एडमिन इमेल लेख्नुहोस्',
        isError: true,
      );
      return;
    }
    if (_passwordController.text.length < 6) {
      _showSnack(
        _isEnglish
            ? 'Password must be at least 6 characters'
            : 'पासवर्ड कम्तीमा ६ अक्षरको हुनुपर्छ',
        isError: true,
      );
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      _showSnack(
        _isEnglish ? 'Passwords do not match' : 'पासवर्ड मिलेन',
        isError: true,
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthServices().bootstrapFirstAdmin(
        fullName: _nameController.text,
        email: email,
        password: _passwordController.text,
        username: 'admin',
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack(AuthMessages.from(e), isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
                  _isEnglish ? 'Admin Sign In' : 'एडमिन लगइन',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A3D1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isEnglish
                      ? 'Sign in to access the administrative dashboard'
                      : 'प्रशासकीय ड्यासबोर्डमा पहुँच गर्न लगइन गर्नुहोस्',
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
                        child: InkWell(
                          onTap: () => setState(() => _signInTab = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: _signInTab
                                ? BoxDecoration(
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
                                  )
                                : null,
                            alignment: Alignment.center,
                            child: Text(
                              _isEnglish ? 'Sign In' : 'लगइन',
                              style: TextStyle(
                                color: _signInTab
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _signInTab = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: !_signInTab
                                ? BoxDecoration(
                                    color: const Color(0xFF2E7D32),
                                    borderRadius: BorderRadius.circular(10),
                                  )
                                : null,
                            alignment: Alignment.center,
                            child: Text(
                              _isEnglish ? 'Admin Access' : 'एडमिन पहुँच',
                              style: TextStyle(
                                color: !_signInTab
                                    ? Colors.white
                                    : Colors.grey.shade700,
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
                if (_signInTab) ...[
                  _sectionHeader('Admin Details', 'एडमिन विवरणहरू'),
                  TextFormField(
                    controller: _usernameController,
                    textCapitalization: TextCapitalization.none,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    validator: _validateUsername,
                    decoration: _inputDecoration(
                      label: _isEnglish
                          ? 'Email or username'
                          : 'इमेल वा प्रयोगकर्ता नाम',
                      hint: _isEnglish
                          ? 'admin or admin@email.com'
                          : 'admin वा admin@email.com',
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pinController,
                    obscureText: _obscurePin,
                    validator: _validatePin,
                    decoration: _inputDecoration(
                      label: _isEnglish ? 'Password' : 'पासवर्ड',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePin
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePin = !_obscurePin;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
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
                              _isEnglish
                                  ? 'Enter Dashboard'
                                  : 'ड्यासबोर्डमा प्रवेश गर्नुहोस्',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ] else ...[
                  _sectionHeader('Create first admin', 'पहिलो एडमिन बनाउनुहोस्'),
                  if (_checkingBootstrap)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (!_bootstrapOpen)
                    Text(
                      _isEnglish
                          ? 'An admin account already exists. Use Sign In with the email or username and password you created.'
                          : 'एडमिन खाता पहिले नै छ। साइन इन प्रयोग गर्नुहोस्।',
                    )
                  else ...[
                    Text(
                      _isEnglish
                          ? 'There is no hardcoded admin password. Create the first admin here, then use those credentials to sign in. Username will be: admin'
                          : 'तयार पासवर्ड छैन। यहाँ पहिलो एडमिन बनाउनुहोस्। प्रयोगकर्ता नाम: admin',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        label: _isEnglish ? 'Full name' : 'पूरा नाम',
                        hint: 'HamroFix Admin',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        label: _isEnglish ? 'Admin email' : 'एडमिन इमेल',
                        hint: 'admin@gmail.com',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: _inputDecoration(
                        label: _isEnglish ? 'Password' : 'पासवर्ड',
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration: _inputDecoration(
                        label: _isEnglish
                            ? 'Confirm password'
                            : 'पासवर्ड पुष्टि',
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleBootstrap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
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
                                _isEnglish
                                    ? 'Create Admin Account'
                                    : 'एडमिन खाता बनाउनुहोस्',
                              ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
