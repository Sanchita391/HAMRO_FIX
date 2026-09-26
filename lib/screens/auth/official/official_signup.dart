// ============================================================================
// HamroFix - Official Access Request (invite / admin-issued accounts)
// ============================================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hamro_fix/core/l10n/app_locale.dart';
import 'package:hamro_fix/screens/auth/landing_page.dart';
import 'package:hamro_fix/screens/auth/official/official_login.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/auth_services.dart';

class OfficialSignupPage extends StatefulWidget {
  const OfficialSignupPage({super.key});

  @override
  State<OfficialSignupPage> createState() => _OfficialSignupPageState();
}

class _OfficialSignupPageState extends State<OfficialSignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _municipalityController = TextEditingController();

  bool _isEnglish = true;
  bool _isLoading = false;
  XFile? _profileImage;

  @override
  void initState() {
    super.initState();
    _isEnglish = AppLocale.instance.isEnglish;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    _municipalityController.dispose();
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

  String? _validatePhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return _isEnglish ? 'Mobile number is required' : 'मोबाइल नम्बर आवश्यक छ';
    }
    if (digits.length < 10) {
      return _isEnglish
          ? 'Enter a valid 10-digit mobile number'
          : 'मान्य १० अङ्कको मोबाइल नम्बर लेख्नुहोस्';
    }
    return null;
  }

  String? _validateEmployeeId(String? v) {
    if (v == null || v.trim().isEmpty) {
      return _isEnglish
          ? 'Employee/Department ID is required'
          : 'कर्मचारी/शाखा आईडी आवश्यक छ';
    }
    return null;
  }

  Future<void> _handleRequestAccess() async {
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
    if (_profileImage == null) {
      _showSnack(
        _isEnglish
            ? 'Please upload your profile photo for verification'
            : 'प्रमाणीकरणका लागि प्रोफाइल तस्बिर हाल्नुहोस्',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthServices().requestOfficialAccess(
        fullName: _fullNameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        employeeId: _employeeIdController.text,
        department: _departmentController.text.trim(),
        municipality: _municipalityController.text.trim(),
        profileImage: _profileImage,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack(AuthMessages.from(e), isError: true);
      return;
    }
    if (!mounted) return;

    setState(() => _isLoading = false);
    _showSnack(
      _isEnglish
          ? 'Access request submitted successfully!'
          : 'पहुँच अनुरोध सफलतापूर्वक पेश गरियो!',
    );

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const OfficialLoginPage()),
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
          _isEnglish ? 'Official Registration' : 'आधिकारिक दर्ता',
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
                setState(() {
                  _isEnglish = !_isEnglish;
                  AppLocale.instance.setEnglish(_isEnglish);
                });
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
                            Icons.admin_panel_settings_rounded,
                            size: 46,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isEnglish ? 'Official Account' : 'आधिकारिक खाता',
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
                            ? 'Request administrative & official access'
                            : 'प्रशासकीय तथा आधिकारिक पहुँचको लागि अनुरोध गर्नुहोस्',
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
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => const OfficialLoginPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            child: Text(
                              _isEnglish ? 'Sign In' : 'लगइन',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
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
                            _isEnglish ? 'Request Access' : 'पहुँच अनुरोध',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _sectionHeader('Official Details', 'आधिकारिक विवरणहरू'),
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final file = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (file != null) setState(() => _profileImage = file);
                    },
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: const Color(0xFFE8F5E9),
                      backgroundImage: _profileImage == null
                          ? null
                          : FileImage(File(_profileImage!.path)),
                      child: _profileImage == null
                          ? const Icon(
                              Icons.camera_alt_outlined,
                              color: Color(0xFF2E7D32),
                              size: 28,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _isEnglish
                        ? 'Upload profile photo (required)'
                        : 'प्रोफाइल तस्बिर हाल्नुहोस् (आवश्यक)',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                    label: _isEnglish
                        ? 'Official Email ID'
                        : 'कार्यालयीन इमेल आईडी',
                    hint: 'official@gov.np',
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                  decoration: _inputDecoration(
                    label: _isEnglish ? 'Mobile number' : 'मोबाइल नम्बर',
                    hint: '98XXXXXXXX',
                    icon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _employeeIdController,
                  validator: _validateEmployeeId,
                  decoration: _inputDecoration(
                    label: _isEnglish
                        ? 'Employee/Department ID'
                        : 'कर्मचारी/शाखा आईडी',
                    hint: 'EMP-102938',
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _departmentController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: _isEnglish
                        ? 'Department / ward office'
                        : 'शाखा / वडा कार्यालय',
                    hint: _isEnglish ? 'Ward 5 office' : 'वडा ५ कार्यालय',
                    icon: Icons.apartment_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _municipalityController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: _isEnglish ? 'Municipality' : 'नगरपालिका',
                    hint: _isEnglish
                        ? 'Kathmandu Metropolitan'
                        : 'काठमाडौं महानगरपालिका',
                    icon: Icons.location_city_outlined,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 8),
                  child: Text(
                    'No password is needed here. After an admin approves your request, you will receive an email to set your password.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRequestAccess,
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
                                ? 'Request Access'
                                : 'पहुँच अनुरोध गर्नुहोस्',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
}
