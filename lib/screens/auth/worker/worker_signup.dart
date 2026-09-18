import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// ── Worker Signup Page ───────────────────────────────────────────────────────
class WorkerSignupPage extends StatefulWidget {
  const WorkerSignupPage({super.key});

  @override
  State<WorkerSignupPage> createState() => _WorkerSignupPageState();
}

class _WorkerSignupPageState extends State<WorkerSignupPage>
    with TickerProviderStateMixin {
  // Form
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0; // 0 = Personal, 1 = Work Details, 2 = Identity Docs

  // Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _citizenshipController = TextEditingController();
  final _experienceController = TextEditingController();

  // State
  bool _isEnglish = true;
  bool _obscurePassword = true;
  bool _attempted = false;
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedDistrict;
  String? _selectedMunicipality;
  String? _selectedSpecialization;

  // Photos
  File? _passportPhoto;
  File? _citizenshipFront;
  File? _citizenshipBack;
  final ImagePicker _picker = ImagePicker();

  // Animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Colors
  static const Color darkGreen = Color(0xFF1A3D1A);
  static const Color medGreen = Color(0xFF2E6B2E);
  static const Color bgGreen = Color(0xFFB8D8B8);
  static const Color accentOrange = Color(0xFFE65100);

  // Data
  final List<String> _specializations = [
    'Plumber / प्लम्बर',
    'Electrician / इलेक्ट्रिसियन',
    'Road Repair / सडक मर्मत',
    'Garbage Collection / फोहोर संकलन',
    'Water Supply / पानी आपूर्ति',
    'Sewage / ढल व्यवस्थापन',
    'Construction / निर्माण',
    'Carpenter / सिकर्मी',
    'Painter / रंगकर्मी',
    'Other / अन्य',
  ];

  final List<String> _genders = [
    'Male / पुरुष',
    'Female / महिला',
    'Other / अन्य',
  ];

  final List<String> _districts = [
    'Kathmandu',
    'Lalitpur',
    'Bhaktapur',
    'Chitwan',
    'Pokhara',
    'Butwal',
    'Dharan',
    'Biratnagar',
    'Birgunj',
    'Janakpur',
    'Hetauda',
    'Itahari',
  ];

  final Map<String, List<String>> _municipalities = {
    'Kathmandu': [
      'Kathmandu Metropolitan',
      'Kirtipur',
      'Tokha',
      'Budhanilkantha',
    ],
    'Lalitpur': ['Lalitpur Metropolitan', 'Godawari', 'Mahalaxmi'],
    'Bhaktapur': ['Bhaktapur Municipality', 'Madhyapur Thimi', 'Changunarayan'],
    'Chitwan': ['Bharatpur Metropolitan', 'Ratnanagar', 'Khairahani'],
    'Pokhara': ['Pokhara Metropolitan', 'Annapurna', 'Machhapuchchhre'],
    'Butwal': ['Butwal Sub-Metropolitan', 'Lumbini', 'Sainamaina'],
    'Dharan': ['Dharan Sub-Metropolitan', 'Itahari', 'Biratnagar'],
    'Biratnagar': ['Biratnagar Metropolitan', 'Urlabari', 'Sundarharaicha'],
    'Birgunj': ['Birgunj Metropolitan', 'Parwanipur', 'Pkali'],
    'Janakpur': [
      'Janakpur Sub-Metropolitan',
      'Dhanushadham',
      'Chhireshwornath',
    ],
    'Hetauda': ['Hetauda Sub-Metropolitan', 'Thaha', 'Makwanpurgadhi'],
    'Itahari': ['Itahari Sub-Metropolitan', 'Sunsari', 'Dharan'],
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _fadeController.forward();
    _slideController.forward();
  }

  void _animateStep() {
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _citizenshipController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  // ── Image Picker ─────────────────────────────────────────────
  Future<void> _pickImage(String type) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      if (type == 'passport') _passportPhoto = File(file.path);
      if (type == 'front') _citizenshipFront = File(file.path);
      if (type == 'back') _citizenshipBack = File(file.path);
    });
  }

  // ── Validators ───────────────────────────────────────────────
  String? _validateFullName(String? v) {
    if (v == null || v.trim().isEmpty) {
      return _isEnglish ? 'Full name is required' : 'पूरा नाम आवश्यक छ';
    }
    if (v.trim().length < 3) {
      return _isEnglish ? 'Name is too short' : 'नाम धेरै छोटो छ';
    }
    if (!RegExp(r"^[a-zA-Z\u0900-\u097F\s]+$").hasMatch(v.trim())) {
      return _isEnglish ? 'Only letters allowed' : 'केवल अक्षरहरू मात्र मान्य';
    }
    if (v.trim().split(' ').where((w) => w.isNotEmpty).length < 2) {
      return _isEnglish
          ? 'Enter first and last name'
          : 'पहिलो र थर नाम लेख्नुहोस्';
    }
    return null;
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

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) {
      return _isEnglish ? 'Phone number is required' : 'फोन नम्बर आवश्यक छ';
    }
    final phone = v.trim().replaceAll(' ', '').replaceAll('-', '');
    if (!RegExp(r'^(98|97|96)\d{8}$').hasMatch(phone)) {
      return _isEnglish
          ? 'Enter valid Nepali mobile number (98XXXXXXXX)'
          : 'मान्य नेपाली मोबाइल नम्बर लेख्नुहोस्';
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
    if (!RegExp(r'[A-Z]').hasMatch(v)) {
      return _isEnglish
          ? 'Add at least one uppercase letter'
          : 'कम्तीमा एउटा ठूलो अक्षर राख्नुहोस्';
    }
    if (!RegExp(r'[0-9]').hasMatch(v)) {
      return _isEnglish
          ? 'Add at least one number'
          : 'कम्तीमा एउटा अंक राख्नुहोस्';
    }
    if (!RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|;:,.<>?]').hasMatch(v)) {
      return _isEnglish
          ? 'Add at least one special character'
          : 'कम्तीमा एउटा विशेष चिन्ह राख्नुहोस्';
    }
    return null;
  }

  String? _validateCitizenship(String? v) {
    if (v == null || v.trim().isEmpty) {
      return _isEnglish
          ? 'Citizenship number is required'
          : 'नागरिकता नम्बर आवश्यक छ';
    }
    final clean = v.trim().replaceAll('-', '').replaceAll(' ', '');
    if (!RegExp(r'^\d{7,15}$').hasMatch(clean)) {
      return _isEnglish
          ? 'Enter valid citizenship number (e.g. 12-34-56789)'
          : 'मान्य नागरिकता नम्बर लेख्नुहोस् (जस्तै: १२-३४-५६७८९)';
    }
    return null;
  }

  String? _validateExperience(String? v) {
    if (v == null || v.trim().isEmpty) {
      return _isEnglish ? 'Experience is required' : 'अनुभव आवश्यक छ';
    }
    final years = int.tryParse(v.trim());
    if (years == null || years < 0 || years > 60) {
      return _isEnglish
          ? 'Enter valid years (0-60)'
          : 'मान्य वर्ष लेख्नुहोस् (०-६०)';
    }
    return null;
  }

  String? _validateAge() {
    if (_selectedDate == null) return null;
    final now = DateTime.now();
    int age = now.year - _selectedDate!.year;
    if (now.month < _selectedDate!.month ||
        (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
      age--;
    }
    if (age < 18) {
      return _isEnglish
          ? 'Worker must be at least 18 years old'
          : 'कामदारको उमेर कम्तीमा १८ वर्ष हुनुपर्छ';
    }
    if (age > 65) {
      return _isEnglish
          ? 'Age cannot exceed 65 years'
          : 'उमेर ६५ वर्षभन्दा बढी हुन सक्दैन';
    }
    return null;
  }

  // ── Step Validation ──────────────────────────────────────────
  bool _validateStep0() {
    bool valid = _formKey.currentState!.validate();
    if (_selectedDate == null) {
      _showSnack(
        _isEnglish
            ? 'Please select date of birth'
            : 'कृपया जन्म मिति छान्नुहोस्',
      );
      return false;
    }
    final ageErr = _validateAge();
    if (ageErr != null) {
      _showSnack(ageErr);
      return false;
    }
    if (_selectedGender == null) {
      _showSnack(
        _isEnglish ? 'Please select gender' : 'कृपया लिङ्ग छान्नुहोस्',
      );
      return false;
    }
    return valid;
  }

  bool _validateStep1() {
    if (_selectedSpecialization == null) {
      _showSnack(
        _isEnglish
            ? 'Please select specialization'
            : 'कृपया विशेषज्ञता छान्नुहोस्',
      );
      return false;
    }
    if (_selectedDistrict == null) {
      _showSnack(
        _isEnglish ? 'Please select district' : 'कृपया जिल्ला छान्नुहोस्',
      );
      return false;
    }
    if (_selectedMunicipality == null) {
      _showSnack(
        _isEnglish
            ? 'Please select municipality'
            : 'कृपया नगरपालिका छान्नुहोस्',
      );
      return false;
    }
    if (_experienceController.text.trim().isEmpty) {
      _showSnack(
        _isEnglish ? 'Please enter experience' : 'कृपया अनुभव लेख्नुहोस्',
      );
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_citizenshipController.text.trim().isEmpty) {
      _showSnack(
        _isEnglish
            ? 'Citizenship number is required'
            : 'नागरिकता नम्बर आवश्यक छ',
      );
      return false;
    }
    if (_passportPhoto == null) {
      _showSnack(
        _isEnglish
            ? 'Please upload your passport size photo'
            : 'कृपया पासपोर्ट साइज फोटो अपलोड गर्नुहोस्',
      );
      return false;
    }
    if (_citizenshipFront == null) {
      _showSnack(
        _isEnglish
            ? 'Please upload citizenship front photo'
            : 'कृपया नागरिकता अगाडिको फोटो अपलोड गर्नुहोस्',
      );
      return false;
    }
    if (_citizenshipBack == null) {
      _showSnack(
        _isEnglish
            ? 'Please upload citizenship back photo'
            : 'कृपया नागरिकता पछाडिको फोटो अपलोड गर्नुहोस्',
      );
      return false;
    }
    return true;
  }

  void _handleNext() {
    setState(() => _attempted = true);
    if (_currentStep == 0 && _validateStep0()) {
      setState(() {
        _currentStep = 1;
        _attempted = false;
      });
      _animateStep();
    } else if (_currentStep == 1 && _validateStep1()) {
      setState(() {
        _currentStep = 2;
        _attempted = false;
      });
      _animateStep();
    } else if (_currentStep == 2 && _validateStep2()) {
      // Navigate to pending verification screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PendingVerificationPage()),
      );
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _attempted = false;
      });
      _animateStep();
    } else {
      Navigator.pop(context);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: darkGreen,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── UI Helpers ───────────────────────────────────────────────
  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
        prefixIcon: Icon(icon, color: darkGreen, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        errorStyle: const TextStyle(fontSize: 11, color: Colors.redAccent),
        errorMaxLines: 2,
      );

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: darkGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: darkGreen,
            letterSpacing: 0.4,
          ),
        ),
      ],
    ),
  );

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?)? onChanged,
    bool showError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: showError && value == null
                  ? Colors.redAccent
                  : value != null
                  ? darkGreen
                  : Colors.white,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: darkGreen, size: 20),
              const SizedBox(width: 4),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    hint: Text(
                      hint,
                      style: TextStyle(
                        fontSize: 14,
                        color: showError && value == null
                            ? Colors.redAccent
                            : Colors.black38,
                      ),
                    ),
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.black38,
                    ),
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    items: items
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(
                              item,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showError && value == null)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 4),
            child: Text(
              _isEnglish ? 'This field is required' : 'यो क्षेत्र आवश्यक छ',
              style: const TextStyle(fontSize: 11, color: Colors.redAccent),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoUpload({
    required String label,
    required String sublabel,
    required IconData icon,
    required File? file,
    required VoidCallback onTap,
    bool showError = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: showError && file == null
                ? Colors.redAccent
                : file != null
                ? darkGreen
                : Colors.white,
            width: 2,
          ),
        ),
        child: file != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      file,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: darkGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: darkGreen.withValues(alpha: 0.75),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        '✓ ${_isEnglish ? "Uploaded" : "अपलोड भयो"}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: showError
                            ? Colors.redAccent.withValues(alpha: 0.1)
                            : bgGreen.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: showError ? Colors.redAccent : darkGreen,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: showError ? Colors.redAccent : darkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sublabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: showError ? Colors.redAccent : darkGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isEnglish
                            ? 'Choose from Gallery'
                            : 'ग्यालरीबाट छान्नुहोस्',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Step Progress Bar ────────────────────────────────────────
  Widget _buildStepBar() {
    final steps = _isEnglish
        ? ['Personal Info', 'Work Details', 'Identity Docs']
        : ['व्यक्तिगत', 'कार्य विवरण', 'परिचयपत्र'];
    return Column(
      children: [
        Row(
          children: List.generate(3, (i) {
            final isActive = i <= _currentStep;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (i < 2) const SizedBox(width: 4),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final isActive = i <= _currentStep;
            return Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.25),
                  ),
                  child: Center(
                    child: isActive && i < _currentStep
                        ? const Icon(Icons.check, color: darkGreen, size: 13)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isActive ? darkGreen : Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                if (i < 2) const SizedBox(width: 12),
              ],
            );
          }),
        ),
      ],
    );
  }

  // ── Steps ────────────────────────────────────────────────────
  Widget _buildStep0() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _sectionLabel(_isEnglish ? 'Personal Information' : 'व्यक्तिगत जानकारी'),

      TextFormField(
        controller: _fullNameController,
        style: const TextStyle(fontSize: 14),
        textCapitalization: TextCapitalization.words,
        validator: _validateFullName,
        decoration: _inputDecoration(
          _isEnglish ? 'Full Name (e.g. Ram Bahadur Shrestha)' : 'पूरा नाम',
          Icons.person_outline_rounded,
        ),
      ),
      const SizedBox(height: 14),

      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(fontSize: 14),
        validator: _validateEmail,
        decoration: _inputDecoration(
          _isEnglish ? 'Email Address' : 'इमेल ठेगाना',
          Icons.email_outlined,
        ),
      ),
      const SizedBox(height: 14),

      TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(fontSize: 14),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        validator: _validatePhone,
        decoration: _inputDecoration(
          _isEnglish
              ? 'Mobile Number (98XXXXXXXX)'
              : 'मोबाइल नम्बर (98XXXXXXXX)',
          Icons.phone_outlined,
        ),
      ),
      const SizedBox(height: 14),

      TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(fontSize: 14),
        validator: _validatePassword,
        decoration:
            _inputDecoration(
              _isEnglish ? 'Password (min 8 chars)' : 'पासवर्ड',
              Icons.lock_outline_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: Colors.black45,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 14, top: 5),
        child: Text(
          _isEnglish
              ? '• Min 8 chars  • 1 uppercase  • 1 number  • 1 special char'
              : '• कम्तीमा ८ अक्षर  • १ ठूलो अक्षर  • १ अंक  • १ विशेष चिन्ह',
          style: TextStyle(fontSize: 11, color: darkGreen.withValues(alpha: 0.6)),
        ),
      ),
      const SizedBox(height: 14),

      // Date of Birth
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _pickDate,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _attempted && _selectedDate == null
                      ? Colors.redAccent
                      : _selectedDate != null
                      ? darkGreen
                      : Colors.white,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: darkGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null
                        ? (_isEnglish
                              ? 'Date of Birth (must be 18+)'
                              : 'जन्म मिति (१८+ वर्ष)')
                        : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedDate == null
                          ? Colors.black38
                          : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: Colors.black38),
                ],
              ),
            ),
          ),
          if (_attempted && _selectedDate == null)
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 4),
              child: Text(
                _isEnglish ? 'Date of birth is required' : 'जन्म मिति आवश्यक छ',
                style: const TextStyle(fontSize: 11, color: Colors.redAccent),
              ),
            ),
        ],
      ),
      const SizedBox(height: 14),

      _buildDropdown(
        hint: _isEnglish ? 'Select Gender' : 'लिङ्ग छान्नुहोस्',
        value: _selectedGender,
        items: _genders,
        icon: Icons.wc_outlined,
        showError: _attempted,
        onChanged: (val) => setState(() => _selectedGender = val),
      ),
    ],
  );

  Widget _buildStep1() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _sectionLabel(_isEnglish ? 'Work Details' : 'कार्य विवरण'),

      _buildDropdown(
        hint: _isEnglish ? 'Select Specialization' : 'विशेषज्ञता छान्नुहोस्',
        value: _selectedSpecialization,
        items: _specializations,
        icon: Icons.construction_outlined,
        showError: _attempted,
        onChanged: (val) => setState(() => _selectedSpecialization = val),
      ),
      const SizedBox(height: 14),

      TextFormField(
        controller: _experienceController,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 14),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        validator: _validateExperience,
        decoration: _inputDecoration(
          _isEnglish
              ? 'Years of Experience (e.g. 3)'
              : 'अनुभवका वर्षहरू (जस्तै: ३)',
          Icons.work_history_outlined,
        ),
      ),
      const SizedBox(height: 24),

      _sectionLabel(_isEnglish ? 'Work Location' : 'कार्य स्थान'),

      _buildDropdown(
        hint: _isEnglish ? 'Select District' : 'जिल्ला छान्नुहोस्',
        value: _selectedDistrict,
        items: _districts,
        icon: Icons.map_outlined,
        showError: _attempted,
        onChanged: (val) => setState(() {
          _selectedDistrict = val;
          _selectedMunicipality = null;
        }),
      ),
      const SizedBox(height: 14),

      _buildDropdown(
        hint: _isEnglish ? 'Select Municipality' : 'नगरपालिका छान्नुहोस्',
        value: _selectedMunicipality,
        items: _selectedDistrict != null
            ? (_municipalities[_selectedDistrict] ?? [])
            : [],
        icon: Icons.location_city_outlined,
        showError: _attempted,
        onChanged: _selectedDistrict == null
            ? null
            : (val) => setState(() => _selectedMunicipality = val),
      ),

      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accentOrange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentOrange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: accentOrange, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isEnglish
                    ? 'Your registration will be reviewed by an Official before you can start working.'
                    : 'काम सुरु गर्नु अघि तपाईंको दर्ता एक अधिकारीद्वारा समीक्षा गरिनेछ।',
                style: TextStyle(
                  fontSize: 12,
                  color: accentOrange.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildStep2() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _sectionLabel(
        _isEnglish
            ? 'National Identity Verification'
            : 'राष्ट्रिय परिचय प्रमाणीकरण',
      ),

      // Citizenship Number
      TextFormField(
        controller: _citizenshipController,
        keyboardType: TextInputType.text,
        style: const TextStyle(fontSize: 14),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d\-]')),
          LengthLimitingTextInputFormatter(20),
        ],
        validator: _validateCitizenship,
        decoration: _inputDecoration(
          _isEnglish
              ? 'Citizenship No. (e.g. 12-34-56789)'
              : 'नागरिकता नं. (जस्तै: १२-३४-५६७८९)',
          Icons.badge_outlined,
        ),
      ),
      const SizedBox(height: 20),

      // Passport Photo
      Text(
        _isEnglish ? 'Passport Size Photo' : 'पासपोर्ट साइज फोटो',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: darkGreen.withValues(alpha: 0.8),
        ),
      ),
      const SizedBox(height: 8),
      _buildPhotoUpload(
        label: _isEnglish ? 'Your Passport Photo' : 'तपाईंको पासपोर्ट फोटो',
        sublabel: _isEnglish
            ? 'Clear face photo on white background'
            : 'सेतो पृष्ठभूमिमा स्पष्ट अनुहार फोटो',
        icon: Icons.person_pin_outlined,
        file: _passportPhoto,
        showError: _attempted && _passportPhoto == null,
        onTap: () => _pickImage('passport'),
      ),
      if (_attempted && _passportPhoto == null)
        Padding(
          padding: const EdgeInsets.only(left: 14, top: 4),
          child: Text(
            _isEnglish
                ? 'Passport photo is required'
                : 'पासपोर्ट फोटो आवश्यक छ',
            style: const TextStyle(fontSize: 11, color: Colors.redAccent),
          ),
        ),
      const SizedBox(height: 20),

      // Citizenship Front
      Text(
        _isEnglish
            ? 'Citizenship Card — Front Side'
            : 'नागरिकता कार्ड — अगाडिको भाग',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: darkGreen.withValues(alpha: 0.8),
        ),
      ),
      const SizedBox(height: 8),
      _buildPhotoUpload(
        label: _isEnglish ? 'Front of Citizenship' : 'नागरिकता अगाडिको भाग',
        sublabel: _isEnglish
            ? 'Make sure all text is clearly visible'
            : 'सबै पाठ स्पष्ट देखिने गरी फोटो लिनुहोस्',
        icon: Icons.credit_card_outlined,
        file: _citizenshipFront,
        showError: _attempted && _citizenshipFront == null,
        onTap: () => _pickImage('front'),
      ),
      if (_attempted && _citizenshipFront == null)
        Padding(
          padding: const EdgeInsets.only(left: 14, top: 4),
          child: Text(
            _isEnglish
                ? 'Citizenship front photo is required'
                : 'नागरिकता अगाडिको फोटो आवश्यक छ',
            style: const TextStyle(fontSize: 11, color: Colors.redAccent),
          ),
        ),
      const SizedBox(height: 20),

      // Citizenship Back
      Text(
        _isEnglish
            ? 'Citizenship Card — Back Side'
            : 'नागरिकता कार्ड — पछाडिको भाग',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: darkGreen.withValues(alpha: 0.8),
        ),
      ),
      const SizedBox(height: 8),
      _buildPhotoUpload(
        label: _isEnglish ? 'Back of Citizenship' : 'नागरिकता पछाडिको भाग',
        sublabel: _isEnglish
            ? 'Make sure all text is clearly visible'
            : 'सबै पाठ स्पष्ट देखिने गरी फोटो लिनुहोस्',
        icon: Icons.credit_card,
        file: _citizenshipBack,
        showError: _attempted && _citizenshipBack == null,
        onTap: () => _pickImage('back'),
      ),
      if (_attempted && _citizenshipBack == null)
        Padding(
          padding: const EdgeInsets.only(left: 14, top: 4),
          child: Text(
            _isEnglish
                ? 'Citizenship back photo is required'
                : 'नागरिकता पछाडिको फोटो आवश्यक छ',
            style: const TextStyle(fontSize: 11, color: Colors.redAccent),
          ),
        ),

      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: darkGreen.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: darkGreen.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.security_outlined, color: darkGreen, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isEnglish
                    ? 'Your documents are encrypted and only visible to authorized officials.'
                    : 'तपाईंका कागजातहरू इन्क्रिप्ट गरिएका छन् र केवल अधिकृत अधिकारीहरूलाई मात्र देखिन्छ।',
                style: TextStyle(
                  fontSize: 12,
                  color: darkGreen.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGreen,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                color: darkGreen,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: darkGreen.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _handleBack,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEnglish
                                  ? 'Worker Registration'
                                  : 'कामदार दर्ता',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _isEnglish
                                  ? 'Step ${_currentStep + 1} of 3'
                                  : 'चरण ${_currentStep + 1} / ३',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Language toggle
                      GestureDetector(
                        onTap: () => setState(() => _isEnglish = !_isEnglish),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isEnglish ? 'नेपाली' : 'English',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStepBar(),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_currentStep == 0) _buildStep0(),
                          if (_currentStep == 1) _buildStep1(),
                          if (_currentStep == 2) _buildStep2(),
                          const SizedBox(height: 28),

                          // ── Next / Submit Button ──
                          GestureDetector(
                            onTap: _handleNext,
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [darkGreen, medGreen],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: darkGreen.withValues(alpha: 0.45),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentStep < 2
                                        ? (_isEnglish ? 'Next' : 'अर्को')
                                        : (_isEnglish
                                              ? 'Submit Registration'
                                              : 'दर्ता पेश गर्नुहोस्'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _currentStep < 2
                                        ? Icons.arrow_forward_rounded
                                        : Icons.check_circle_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pending Verification Page ────────────────────────────────────────────────
class PendingVerificationPage extends StatefulWidget {
  const PendingVerificationPage({super.key});

  @override
  State<PendingVerificationPage> createState() =>
      _PendingVerificationPageState();
}

class _PendingVerificationPageState extends State<PendingVerificationPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  static const Color darkGreen = Color(0xFF1A3D1A);
  static const Color bgGreen = Color(0xFFB8D8B8);
  static const Color accentOrange = Color(0xFFE65100);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGreen,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pulsing icon
                Center(
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: darkGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: darkGreen.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                const Text(
                  'Registration Submitted!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'दर्ता पेश गरियो!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkGreen.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 28),

                // Status Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: darkGreen.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _statusRow(
                        Icons.pending_outlined,
                        accentOrange,
                        'Pending Verification',
                        'प्रमाणीकरण बाँकी',
                      ),
                      const Divider(height: 24),
                      _infoRow(
                        Icons.admin_panel_settings_outlined,
                        'Reviewed by Officials',
                        'अधिकारीहरूद्वारा समीक्षा',
                      ),
                      const SizedBox(height: 12),
                      _infoRow(
                        Icons.access_time_outlined,
                        'Processing: 2-5 business days',
                        'प्रक्रिया: २-५ कार्य दिन',
                      ),
                      const SizedBox(height: 12),
                      _infoRow(
                        Icons.notifications_outlined,
                        'You will be notified via SMS/Email',
                        'SMS/Email मार्फत सूचित गरिनेछ',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // What happens next
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentOrange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentOrange.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: accentOrange,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'What happens next?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: accentOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _nextStep(
                        '1.',
                        'Official reviews your documents & citizenship',
                      ),
                      _nextStep('2.', 'Identity verification is completed'),
                      _nextStep('3.', 'You receive approval notification'),
                      _nextStep(
                        '4.',
                        'Login and start accepting work requests',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Back to Home
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [darkGreen, Color(0xFF2E6B2E)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: darkGreen.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(
                        color: Colors.white,
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

  Widget _statusRow(IconData icon, Color color, String en, String np) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            en,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            np,
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7)),
          ),
        ],
      ),
    ],
  );

  Widget _infoRow(IconData icon, String en, String np) => Row(
    children: [
      Icon(icon, color: darkGreen, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              en,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              np,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _nextStep(String num, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          num,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accentOrange,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      ],
    ),
  );
}
