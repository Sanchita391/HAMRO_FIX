import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hamro_fix/screens/auth/landing_page.dart';

import 'package:hamro_fix/screens/auth/public/public_signup.dart';

class PublicLoginPage extends StatefulWidget {
  const PublicLoginPage({super.key});

  @override
  State<PublicLoginPage> createState() => _PublicLoginPageState();
}

class _PublicLoginPageState extends State<PublicLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isEnglish = true;
  bool _obscurePassword = true;
  bool _usePhone = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
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

  String? _validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _isEnglish
          ? (_usePhone
                ? 'Mobile number is required'
                : 'Email address is required')
          : (_usePhone ? 'मोबाइल नम्बर आवश्यक छ' : 'इमेल ठेगाना आवश्यक छ');
    }
    final trimmed = value.trim();
    if (_usePhone) {
      final sanitized = trimmed.replaceAll(RegExp(r'[\s-]'), '');
      if (!RegExp(r'^(98|97|96)\d{8}$').hasMatch(sanitized)) {
        return _isEnglish
            ? 'Enter valid Nepali mobile number (98XXXXXXXX)'
            : 'मान्य नेपाली मोबाइल नम्बर लेख्नुहोस् (98XXXXXXXX)';
      }
    } else {
      if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(trimmed)) {
        return _isEnglish
            ? 'Enter a valid email address'
            : 'मान्य इमेल ठेगाना लेख्नुहोस्';
      }
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return _isEnglish ? 'Password is required' : 'पासवर्ड आवश्यक छ';
    }
    if (value.length < 8) {
      return _isEnglish
          ? 'Password must be at least 8 characters'
          : 'पासवर्ड कम्तीमा ८ अक्षरको हुनुपर्छ';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    HapticFeedback.lightImpact();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate authentication call
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEnglish
              ? 'Login successful! Welcome to HamroFix.'
              : 'लगइन सफल भयो! हाम्रोफिक्समा स्वागत छ।',
        ),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleForgotPassword() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _ForgotPasswordSheet(isEnglish: _isEnglish),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrapped in the app-wide Light Green Theme (guarantees zero purple)
    return Theme(
      data: kHamroFixLightGreenTheme,
      child: Builder(
        builder: (themedContext) {
          final theme = Theme.of(themedContext);
          final colorScheme = theme.colorScheme;

          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: _isEnglish
                    ? 'Back to Landing Page'
                    : 'गृहपृष्ठमा फर्कनुहोस्',
                onPressed: _navigateBackToLanding,
              ),
              title: Text(
                _isEnglish ? 'Citizen Login' : 'नागरिक लगइन',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              actions: [
                // Top language switch chip
                Padding(
                  padding: const EdgeInsets.only(right: 14),
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
                      foregroundColor: colorScheme.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo & Branding
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFA5D6A7),
                                  width: 1.2,
                                ),
                              ),
                              child: const HamroFixLogo(size: 48),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'HamroFix',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isEnglish
                                  ? 'Public Citizen Problem Reporting'
                                  : 'सार्वजनिक नागरिक समस्या रिपोर्टिङ पोर्टल',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Auth Navigation Pill (Login vs Sign Up)
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.25,
                                      ),
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
                                      builder: (_) => const PublicSignupPage(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _isEnglish ? 'Create Account' : 'नयाँ खाता',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
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
                      const SizedBox(height: 24),

                      // Method Selector (Email vs Phone)
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment<bool>(
                            value: false,
                            icon: const Icon(Icons.email_outlined, size: 18),
                            label: Text(_isEnglish ? 'Email' : 'इमेल'),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            icon: const Icon(
                              Icons.phone_iphone_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _isEnglish ? 'Mobile Phone' : 'फोन नम्बर',
                            ),
                          ),
                        ],
                        selected: {_usePhone},
                        onSelectionChanged: (set) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _usePhone = set.first;
                            _identifierController.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 18),

                      // Identifier Input (Email or Mobile)
                      TextFormField(
                        key: ValueKey(_usePhone),
                        controller: _identifierController,
                        keyboardType: _usePhone
                            ? TextInputType.phone
                            : TextInputType.emailAddress,
                        inputFormatters: _usePhone
                            ? [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ]
                            : [],
                        validator: _validateIdentifier,
                        decoration: InputDecoration(
                          labelText: _usePhone
                              ? (_isEnglish ? 'Mobile Number' : 'मोबाइल नम्बर')
                              : (_isEnglish ? 'Email Address' : 'इमेल ठेगाना'),
                          hintText: _usePhone
                              ? '98XXXXXXXX'
                              : 'citizen@example.com',
                          prefixIcon: Icon(
                            _usePhone
                                ? Icons.phone_android_rounded
                                : Icons.alternate_email_rounded,
                            color: colorScheme.primary,
                          ),
                          prefixText: _usePhone ? '+977 ' : null,
                          prefixStyle: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
                        decoration: InputDecoration(
                          labelText: _isEnglish ? 'Password' : 'पासवर्ड',
                          hintText: '••••••••',
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            color: colorScheme.primary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: colorScheme.outline,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                          ),
                          child: Text(
                            _isEnglish
                                ? 'Forgot Password?'
                                : 'पासवर्ड बिर्सनुभयो?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Submit Button
                      FilledButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEnglish ? 'Sign In' : 'लगइन गर्नुहोस्',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Bottom switch to Register
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isEnglish
                                ? "Don't have an account? "
                                : 'नयाँ प्रयोगकर्ता हुनुहुन्छ? ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => const PublicSignupPage(),
                                ),
                              );
                            },
                            child: Text(
                              _isEnglish ? 'Register' : 'दर्ता गर्नुहोस्',
                              style: TextStyle(
                                color: colorScheme.primary,
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
        },
      ),
    );
  }
}

class _ForgotPasswordSheet extends StatefulWidget {
  final bool isEnglish;
  const _ForgotPasswordSheet({required this.isEnglish});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _resetFormKey = GlobalKey<FormState>();
  final _resetController = TextEditingController();
  bool _usePhone = false;
  bool _isSending = false;

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _sendReset() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEnglish
              ? 'Reset link sent! Check your ${_usePhone ? "phone SMS" : "email"}.'
              : 'रिसेट लिङ्क पठाइयो! आफ्नो ${_usePhone ? "मोबाइल सन्देश" : "इमेल"} जाँच गर्नुहोस्।',
        ),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _resetFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock_reset_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEnglish
                            ? 'Password Recovery'
                            : 'पासवर्ड पुनःप्राप्ति',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.isEnglish
                            ? 'Enter your registered email or phone'
                            : 'दर्ता भएको इमेल वा फोन नम्बर प्रविष्ट गर्नुहोस्',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(widget.isEnglish ? 'Email' : 'इमेल'),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(widget.isEnglish ? 'Phone' : 'फोन'),
                ),
              ],
              selected: {_usePhone},
              onSelectionChanged: (set) => setState(() {
                _usePhone = set.first;
                _resetController.clear();
              }),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _resetController,
              keyboardType: _usePhone
                  ? TextInputType.phone
                  : TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return widget.isEnglish
                      ? 'This field is required'
                      : 'यो विवरण आवश्यक छ';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: _usePhone ? '98XXXXXXXX' : 'user@example.com',
                prefixIcon: Icon(
                  _usePhone
                      ? Icons.phone_android_rounded
                      : Icons.alternate_email_rounded,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _isSending ? null : _sendReset,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.isEnglish ? 'Send Recovery Link' : 'लिङ्क पठाउनुहोस्',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
