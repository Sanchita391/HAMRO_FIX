import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:hamro_fix/core/constants/app_constants.dart';
import 'package:hamro_fix/core/l10n/app_locale.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/screens/dashboards/dashboard_widgets.dart';
import 'package:hamro_fix/screens/dashboards/shared_tabs.dart';
import 'package:hamro_fix/screens/reports/report_details_page.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/location_service.dart';
import 'package:hamro_fix/services/notification_service.dart';
import 'package:hamro_fix/services/report_service.dart';
import 'package:hamro_fix/widgets/report_video_player.dart';
import 'package:hamro_fix/widgets/stored_image.dart';
import 'package:hamro_fix/widgets/xfile_preview.dart';
import 'package:hamro_fix/widgets/xfile_video_preview.dart';

// Brand Light Green Theme Colors
const Color kPrimaryGreen = Color(0xFF1B5E20);
const Color kLightGreenBg = Color(0xFFF1F8E9);
const Color kAccentGreen = Color(0xFFA5D6A7);

class PublicDashboard extends StatefulWidget {
  const PublicDashboard({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<PublicDashboard> createState() => _PublicDashboardState();
}

class _PublicDashboardState extends State<PublicDashboard> {
  int _currentIndex = 0;

  Future<void> _handleLogout(BuildContext context) async {
    HapticFeedback.lightImpact();
    await confirmAndLogout(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleScope.of(context);

    return StreamBuilder<List<AppNotification>>(
      stream: NotificationService().watchMine(widget.profile.uid),
      builder: (context, alertSnap) {
        final alerts = alertSnap.data ?? [];
        final unreadAlerts = AppNotification.unreadCount(
          alerts,
          profile: widget.profile,
        );
        final unreadReports = AppNotification.unreadCount(
          alerts,
          types: AlertType.reportBadge,
          profile: widget.profile,
        );
        final unreadBudgets = AppNotification.unreadCount(
          alerts,
          types: AlertType.budgetBadge,
          profile: widget.profile,
        );
        final reportBadge = unreadReports + unreadBudgets;

        return Scaffold(
      backgroundColor: kLightGreenBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: HamroFixBarTitle(
          subtitle: widget.profile.displayName,
          photoUrl: widget.profile.profileImageUrl,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFB71C1C)),
            tooltip: loc.t('Log out', 'लग आउट'),
            onPressed: () => _handleLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          InteractiveCreateReportTab(profile: widget.profile),
          _MyReportsTab(profile: widget.profile),
          FeedTab(profile: widget.profile),
          FeedTab(profile: widget.profile, mineOnly: true),
          NotificationsTab(uid: widget.profile.uid, profile: widget.profile),
          ProfileTab(profile: widget.profile),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          },
          selectedItemColor: kPrimaryGreen,
          unselectedItemColor: Colors.grey.shade600,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_location_alt_outlined),
              activeIcon: const Icon(Icons.add_location_alt_rounded),
              label: AppLocale.instance.t('Report', 'रिपोर्ट'),
            ),
            BottomNavigationBarItem(
              icon: badgedIcon(Icons.receipt_long_outlined, reportBadge),
              activeIcon: badgedIcon(Icons.receipt_long_rounded, reportBadge),
              label: AppLocale.instance.t('My Reports', 'मेरा रिपोर्ट'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.public_outlined),
              activeIcon: const Icon(Icons.public_rounded),
              label: AppLocale.instance.t('Public', 'सार्वजनिक'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.video_library_outlined),
              activeIcon: const Icon(Icons.video_library_rounded),
              label: AppLocale.instance.t('My Feed', 'मेरो फिड'),
            ),
            BottomNavigationBarItem(
              icon: badgedIcon(Icons.notifications_none_rounded, unreadAlerts),
              activeIcon: badgedIcon(Icons.notifications_rounded, unreadAlerts),
              label: AppLocale.instance.t('Alerts', 'सूचना'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: AppLocale.instance.t('Profile', 'प्रोफाइल'),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Interactive Report Creator Tab
// -----------------------------------------------------------------------------
class InteractiveCreateReportTab extends StatefulWidget {
  final UserProfile profile;
  const InteractiveCreateReportTab({super.key, required this.profile});

  @override
  State<InteractiveCreateReportTab> createState() =>
      _InteractiveCreateReportTabState();
}

class _InteractiveCreateReportTabState
    extends State<InteractiveCreateReportTab> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descController = TextEditingController();
  final MapController _mapController = MapController();

  XFile? _mediaFile;
  bool _isVideo = false;
  String? _selectedCategory;
  LatLng _selectedLocation = const LatLng(
    27.7172,
    85.3240,
  ); // Kathmandu default
  String _selectedMunicipality = 'Kathmandu Metropolitan';
  bool _isSubmitting = false;
  bool _locating = false;
  bool _locationPinned = false;
  bool _submitAnonymously = false;

  final List<String> _categories = ReportCategories.all;

  final List<String> _municipalities = [
    'Kathmandu Metropolitan',
    'Lalitpur Metropolitan',
    'Bhaktapur Municipality',
    'Pokhara Metropolitan',
    'Chandragiri Municipality',
    'Other',
  ];

  @override
  void dispose() {
    _descController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _pinLocation(LatLng point) {
    setState(() {
      _selectedLocation = point;
      _locationPinned = true;
    });
  }

  String _coordLabel() {
    return '${_selectedLocation.latitude.toStringAsFixed(5)}, ${_selectedLocation.longitude.toStringAsFixed(5)}';
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final location = await LocationService().captureCurrent();
      final point = LatLng(location.latitude, location.longitude);
      if (!mounted) return;
      _pinLocation(point);
      _mapController.move(point, 16);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    final file = isVideo
        ? await _picker.pickVideo(
            source: source,
            maxDuration: const Duration(seconds: 10),
          )
        : await _picker.pickImage(source: source, imageQuality: 85);

    if (file != null) {
      setState(() {
        _mediaFile = file;
        _isVideo = isVideo;
      });
    }
  }

  Future<void> _submitReport() async {
    if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a photo or video first!')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a problem category!')),
      );
      return;
    }
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue.')),
      );
      return;
    }
    if (!_locationPinned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocale.instance.t(
              'Pin the spot on the map or use your current location.',
              'नक्सामा पिन गर्नुहोस् वा आफ्नो हालको स्थान प्रयोग गर्नुहोस्।',
            ),
          ),
        ),
      );
      return;
    }
    if (widget.profile.isBlacklisted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This account cannot submit new reports.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ReportService().createReport(
        title: _selectedCategory!,
        description: _descController.text,
        category: _selectedCategory!,
        image: _isVideo ? null : _mediaFile,
        video: _isVideo ? _mediaFile : null,
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        locationTimestamp: DateTime.now(),
        municipality: _selectedMunicipality,
        address: _selectedMunicipality,
        isAnonymous: _submitAnonymously,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocale.instance.t(
              'Report submitted successfully!',
              'रिपोर्ट सफलतापूर्वक पठाइयो!',
            ),
          ),
          backgroundColor: kPrimaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      setState(() {
        _mediaFile = null;
        _selectedCategory = null;
        _descController.clear();
        _submitAnonymously = false;
        _locationPinned = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleScope.of(context);
    final name = widget.profile.displayName;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('Hello, $name', 'नमस्ते, $name'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _formCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader(
                  loc.t('Photo or video', 'फोटो वा भिडियो'),
                  Icons.photo_camera_rounded,
                ),
                const SizedBox(height: 10),
                Container(
                  height: _mediaFile != null && _isVideo ? 200 : 148,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FBF6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kAccentGreen),
                  ),
                  child: _mediaFile == null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildMediaTile(
                              icon: Icons.photo_camera_rounded,
                              label: loc.t('Camera', 'क्यामेरा'),
                              onTap: () => _pickMedia(ImageSource.camera),
                            ),
                            _buildMediaTile(
                              icon: Icons.videocam_rounded,
                              label: loc.t('Video (10s)', 'भिडियो (१० से.)'),
                              onTap: () => _pickMedia(
                                ImageSource.camera,
                                isVideo: true,
                              ),
                            ),
                            _buildMediaTile(
                              icon: Icons.collections_rounded,
                              label: loc.t('Gallery', 'ग्यालेरी'),
                              onTap: () => _pickMedia(ImageSource.gallery),
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _isVideo
                                  ? XFileVideoPreview(
                                      file: _mediaFile!,
                                      width: double.infinity,
                                      height: 200,
                                    )
                                  : XFilePreview(
                                      file: _mediaFile!,
                                      width: double.infinity,
                                      height: 148,
                                    ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => setState(() {
                                    _mediaFile = null;
                                    _isVideo = false;
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader(
                  loc.t('Category', 'श्रेणी'),
                  Icons.category_rounded,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  isExpanded: true,
                  menuMaxHeight: 280,
                  decoration: _fieldDecoration(
                    hint: loc.t('Select issue type', 'समस्याको प्रकार छान्नुहोस्'),
                  ),
                  hint: Text(
                    loc.t('Select issue type', 'समस्याको प्रकार छान्नुहोस्'),
                  ),
                  items: _categories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(
                            loc.category(cat),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader(
                  loc.t('Describe it', 'विवरण लेख्नुहोस्'),
                  Icons.edit_note_rounded,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: _fieldDecoration(
                    hint: loc.t(
                      'What happened, and where exactly?',
                      'के भयो, र कहाँ भयो?',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _formCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader(
                  loc.t('Pin the exact spot', 'ठ्याक्कै स्थान पिन गर्नुहोस्'),
                  Icons.my_location_rounded,
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _locating ? null : _useCurrentLocation,
                  style: FilledButton.styleFrom(
                    backgroundColor: _locationPinned
                        ? const Color(0xFF388E3C)
                        : kPrimaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _locating
                        ? loc.t('Finding you...', 'तपाईं खोजिँदै...')
                        : _locationPinned
                        ? loc.t('Location pinned', 'स्थान पिन भयो')
                        : loc.t(
                            'Use my current location',
                            'मेरो हालको स्थान प्रयोग गर्नुहोस्',
                          ),
                  ),
                ),
                if (_locationPinned) ...[
                  const SizedBox(height: 8),
                  Text(
                    loc.t(
                      'Pinned: ${_coordLabel()}  ·  tap the map or the button to change',
                      'पिन: ${_coordLabel()}  ·  परिवर्तन गर्न नक्सा वा बटन थिच्नुहोस्',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 180,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _selectedLocation,
                            initialZoom: 14.5,
                            onTap: (tapPosition, point) {
                              HapticFeedback.selectionClick();
                              _pinLocation(point);
                              _mapController.move(point, 16);
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'app.hamro_fix',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _selectedLocation,
                                  width: 48,
                                  height: 48,
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFFC62828),
                                    size: 44,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _locationPinned
                                  ? loc.t(
                                      'Location pinned · ${_coordLabel()}',
                                      'स्थान पिन भयो · ${_coordLabel()}',
                                    )
                                  : loc.t(
                                      'Tap the map to pin the spot',
                                      'स्थान पिन गर्न नक्सामा थिच्नुहोस्',
                                    ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedMunicipality,
                  isExpanded: true,
                  decoration: _fieldDecoration(
                    hint: loc.t('Municipality', 'नगरपालिका'),
                  ),
                  items: _municipalities
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedMunicipality = v);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _formCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                loc.t('Submit anonymously', 'बेनामी पेश गर्नुहोस्'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                loc.t(
                  'Officials will see the issue, not your name. Admin can still review your identity if needed for fraud.',
                  'अधिकारीले समस्या देख्छन्, तपाईंको नाम होइन। जालसाजी जाँचका लागि एडमिनले पहिचान हेर्न सक्छन्।',
                ),
                style: const TextStyle(fontSize: 12),
              ),
              value: _submitAnonymously,
              activeThumbColor: kPrimaryGreen,
              onChanged: (value) => setState(() => _submitAnonymously = value),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isSubmitting ? null : _submitReport,
            style: FilledButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    loc.t('Submit report', 'रिपोर्ट पठाउनुहोस्'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _formCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryGreen.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _fieldDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7FBF6),
      prefixIcon: icon == null ? null : Icon(icon, color: kPrimaryGreen),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimaryGreen, width: 1.4),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kPrimaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildMediaTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: kLightGreenBg,
              child: Icon(icon, color: kPrimaryGreen),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyReportsTab extends StatelessWidget {
  const _MyReportsTab({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReportIssue>>(
      stream: ReportService().watchMyReports(profile.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(AuthMessages.from(snapshot.error!)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data!;
        if (reports.isEmpty) {
          return Center(
            child: Text(
              LocaleScope.of(context).t(
                'Your reports will show up here.',
                'तपाईंका रिपोर्ट यहाँ देखिन्छन्।',
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final report = reports[index];
            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ReportDetailsPage(
                            report: report,
                            profile: profile,
                          ),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundImage: StoredImage.provider(report.imageUrl),
                      child: StoredImage.provider(report.imageUrl) == null
                          ? Icon(
                              report.hasPlayableVideo
                                  ? Icons.videocam_rounded
                                  : Icons.receipt_long_outlined,
                            )
                          : null,
                    ),
                    title: Text(report.publicId),
                    subtitle: Text(
                      [
                        if (report.isAnonymous) 'Anonymous',
                        AppLocale.instance.category(report.category),
                      ].join(' · '),
                    ),
                    trailing: _PublicReportStateChip(
                      state: report.publicWorkState,
                    ),
                  ),
                  if (report.hasPlayableVideo)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: ReportVideoPlayer(report, height: 180),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PublicReportStateChip extends StatelessWidget {
  const _PublicReportStateChip({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      'Completed' => const Color(0xFF2E7D32),
      'Closed' => const Color(0xFFB71C1C),
      _ => const Color(0xFFE65100),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        state,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
