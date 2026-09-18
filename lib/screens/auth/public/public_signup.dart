// ============================================================================
// HamroFix - Citizen Registration Page
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hamro_fix/screens/auth/landing_page.dart';
import 'package:hamro_fix/screens/auth/public/public_login.dart';

class PublicSignupPage extends StatefulWidget {
  const PublicSignupPage({super.key});

  @override
  State<PublicSignupPage> createState() => _PublicSignupPageState();
}

class _PublicSignupPageState extends State<PublicSignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isEnglish = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  void _goToLogin() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const PublicLoginPage()),
    );
  }

  String? _validateFullName(String? v) {
    if (v == null || v.trim().isEmpty) {
      return _isEnglish ? 'Full name is required' : 'पूरा नाम आवश्यक छ';
    }
    if (v.trim().length < 3) {
      return _isEnglish ? 'Name is too short' : 'नाम धेरै छोटो छ';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) {
      return _isEnglish ? 'Email address is required' : 'इमेल ठेगाना आवश्यक छ';
    }
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(v.trim())) {
      return _isEnglish
          ? 'Enter a valid email address'
          : 'मान्य इमेल ठेगाना लेख्नुहोस्';
    }
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) {
      return _isEnglish ? 'Mobile number is required' : 'मोबाइल नम्बर आवश्यक छ';
    }
    final sanitized = v.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^(98|97|96)\d{8}$').hasMatch(sanitized)) {
      return _isEnglish
          ? 'Enter valid Nepali mobile number (98XXXXXXXX)'
          : 'मान्य नेपाली मोबाइल नम्बर लेख्नुहोस् (98XXXXXXXX)';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) {
      return _isEnglish ? 'Password is required' : 'पासवर्ड आवश्यक छ';
    }
    if (v.length < 8) {
      return _isEnglish
          ? 'Minimum 8 characters required'
          : 'कम्तीमा ८ अक्षर चाहिन्छ';
    }
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) {
      return _isEnglish
          ? 'Please confirm your password'
          : 'पासवर्ड पुष्टि गर्नुहोस्';
    }
    if (v != _passwordController.text) {
      return _isEnglish ? 'Passwords do not match' : 'पासवर्ड मिलेन';
    }
    return null;
  }

  Future<void> _handleRegister() async {
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
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;

    setState(() => _isLoading = false);
    _showSnack(
      _isEnglish
          ? 'Registration successful! You can now sign in.'
          : 'दर्ता सफल भयो! अब लगइन गर्न सक्नुहुन्छ।',
    );

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const PublicLoginPage()),
    );
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
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.bold,
      ),
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

  Widget _authTabs({required bool registerSelected}) {
    return Container(
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
              borderRadius: BorderRadius.circular(10),
              onTap: registerSelected ? _goToLogin : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: registerSelected
                    ? null
                    : BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                child: Text(
                  _isEnglish ? 'Sign In' : 'लगइन',
                  style: TextStyle(
                    color: registerSelected ? Colors.grey.shade700 : Colors.white,
                    fontWeight: registerSelected
                        ? FontWeight.w600
                        : FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: registerSelected
                  ? BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    )
                  : null,
              alignment: Alignment.center,
              child: Text(
                _isEnglish ? 'Register' : 'दर्ता',
                style: TextStyle(
                  color: registerSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6FBF6),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          tooltip: _isEnglish
              ? 'Back to Landing Page'
              : 'गृहपृष्ठमा फर्कनुहोस्',
          onPressed: _navigateBackToLanding,
        ),
        title: Text(
          _isEnglish ? 'Citizen Registration' : 'नागरिक दर्ता',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _isEnglish = !_isEnglish);
              },
              icon: const Icon(Icons.language_rounded, size: 18),
              label: Text(
                _isEnglish ? 'नेपाली' : 'English',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                visualDensity: VisualDensity.compact,
              ),
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
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 46,
                          width: 46,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.campaign_rounded,
                            size: 46,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isEnglish ? 'Public Citizen Account' : 'नागरिक खाता',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEnglish
                            ? 'Create an account to report and track local issues'
                            : 'स्थानीय समस्या रिपोर्ट र ट्र्याक गर्न खाता बनाउनुहोस्',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _authTabs(registerSelected: true),
                _sectionHeader('Personal Details', 'व्यक्तिगत विवरणहरू'),
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  validator: _validateFullName,
                  decoration: _inputDecoration(
                    label: _isEnglish ? 'Full Name' : 'पूरा नाम',
                    hint: _isEnglish
                        ? 'Ram Bahadur Shrestha'
                        : 'राम बहादुर श्रेष्ठ',
                    icon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  decoration: _inputDecoration(
                    label: _isEnglish ? 'Email Address' : 'इमेल ठेगाना',
                    hint: 'citizen@example.com',
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: _validatePhone,
                  decoration: _inputDecoration(
                    label: _isEnglish ? 'Mobile Number' : 'मोबाइल नम्बर',
                    hint: '98XXXXXXXX',
                    icon: Icons.phone_android_rounded,
                    prefixText: '+977 ',
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  validator: _validateConfirmPassword,
                  decoration: _inputDecoration(
                    label: _isEnglish
                        ? 'Confirm Password'
                        : 'पासवर्ड पुष्टि गर्नुहोस्',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
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
                            _isEnglish ? 'Create Account' : 'खाता बनाउनुहोस्',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isEnglish
                          ? 'Already have an account? '
                          : 'पहिलेदेखि खाता छ? ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    TextButton(
                      onPressed: _goToLogin,
                      child: Text(
                        _isEnglish ? 'Sign In' : 'लगइन गर्नुहोस्',
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
