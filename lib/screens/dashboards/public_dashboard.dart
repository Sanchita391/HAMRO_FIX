import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/screens/dashboards/dashboard_widgets.dart';
import 'package:hamro_fix/services/report_service.dart';

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out from HamroFix?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();

    final List<Widget> pages = [
      InteractiveCreateReportTab(profile: widget.profile),
      TikTokReportFeed(
        stream: reportService.watchMyReports(widget.profile.uid),
      ),
      const NotificationsTab(),
      ProfileTab(profile: widget.profile),
    ];

    return Scaffold(
      backgroundColor: kLightGreenBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kLightGreenBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.build_circle_rounded,
                color: kPrimaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'HamroFix',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF1C1B1F),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFB71C1C)),
            tooltip: 'Log Out',
            onPressed: () => _handleLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: pages[_currentIndex],
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.add_location_alt_outlined),
              activeIcon: Icon(Icons.add_location_alt_rounded),
              label: 'Report',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_library_outlined),
              activeIcon: Icon(Icons.video_library_rounded),
              label: 'My Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none_rounded),
              activeIcon: Icon(Icons.notifications_rounded),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
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

  XFile? _mediaFile;
  bool _isVideo = false;
  String? _selectedCategory;
  LatLng _selectedLocation = const LatLng(
    27.7172,
    85.3240,
  ); // Kathmandu default
  String _selectedMunicipality = 'Kathmandu Metropolitan';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Pothole / Road Damage',
    'Garbage & Waste',
    'Water Pipe Leak',
    'Streetlight Fault',
    'Drainage Blockage',
    'Public Safety / Other',
  ];

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
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    final file = isVideo
        ? await _picker.pickVideo(source: source)
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

    setState(() => _isSubmitting = true);
    try {
      await Future<void>.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report submitted successfully!'),
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
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Report a Public Issue',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: kPrimaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Follow simple steps to alert local government authorities.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // 1. Media Upload
          _buildSectionHeader(
            '1. Media Proof (Photo / Video)',
            Icons.camera_alt_rounded,
          ),
          const SizedBox(height: 10),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kAccentGreen, width: 1.5),
            ),
            child: _mediaFile == null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMediaTile(
                        icon: Icons.photo_camera_rounded,
                        label: 'Take Photo',
                        onTap: () => _pickMedia(ImageSource.camera),
                      ),
                      _buildMediaTile(
                        icon: Icons.videocam_rounded,
                        label: 'Record Video',
                        onTap: () =>
                            _pickMedia(ImageSource.camera, isVideo: true),
                      ),
                      _buildMediaTile(
                        icon: Icons.collections_rounded,
                        label: 'Gallery',
                        onTap: () => _pickMedia(ImageSource.gallery),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_mediaFile!.path),
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() => _mediaFile = null),
                          ),
                        ),
                      ),
                      if (_isVideo)
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),

          // 2. Category Selection
          _buildSectionHeader('2. Issue Category', Icons.category_rounded),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                selectedColor: kPrimaryGreen,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? kPrimaryGreen : Colors.grey.shade300,
                  ),
                ),
                onSelected: (val) =>
                    setState(() => _selectedCategory = val ? cat : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 3. Live Map
          _buildSectionHeader('3. Live Map Location', Icons.map_rounded),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: kAccentGreen, width: 1.5),
              ),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _selectedLocation,
                  initialZoom: 14.0,
                  onTap: (tapPosition, point) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedLocation = point);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.hamrofix.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4. Municipality & Details
          _buildSectionHeader(
            '4. Local Municipality & Details',
            Icons.business_rounded,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedMunicipality,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            items: _municipalities
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedMunicipality = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe the problem clearly...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Submit Button
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitReport,
            style: FilledButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _isSubmitting
                ? const SizedBox.shrink()
                : const Icon(Icons.send_rounded, color: Colors.white),
            label: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'SUBMIT REPORT',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
          const SizedBox(height: 16),
        ],
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

// -----------------------------------------------------------------------------
// TikTok-Style Feed
// -----------------------------------------------------------------------------
class TikTokReportFeed extends StatelessWidget {
  final Stream<List<dynamic>> stream;
  const TikTokReportFeed({super.key, required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryGreen),
          );
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_collection_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No reports filed yet',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Reports you submit will appear here in video feed.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final report = items[index];
            return Stack(
              children: [
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Icon(
                      Icons.image_rounded,
                      size: 100,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 80,
                  bottom: 30,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          report is Map && report.containsKey('category')
                              ? report['category'].toString()
                              : 'General',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report is Map && report.containsKey('title')
                            ? report['title'].toString()
                            : 'Public Infrastructure Issue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        report is Map && report.containsKey('description')
                            ? report['description'].toString()
                            : 'No detailed description provided.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 40,
                  child: Column(
                    children: [
                      _buildIconButton(Icons.favorite_rounded, '24'),
                      const SizedBox(height: 18),
                      _buildIconButton(Icons.comment_rounded, '8'),
                      const SizedBox(height: 18),
                      _buildIconButton(Icons.share_rounded, 'Share'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildIconButton(IconData icon, String count) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.black45,
          radius: 22,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Notifications Tab Component
// -----------------------------------------------------------------------------
class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildNotificationCard(
          title: 'Status Update: Ward #4 Road Repair',
          subtitle: 'Your report status changed to "In Progress".',
          time: '2 hours ago',
          icon: Icons.alt_route_rounded,
        ),
        _buildNotificationCard(
          title: 'Report Verified',
          subtitle: 'Lalitpur Metropolitan municipality verified your report.',
          time: '1 day ago',
          icon: Icons.verified_rounded,
        ),
      ],
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kLightGreenBg,
          child: Icon(icon, color: kPrimaryGreen),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Text(
          time,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ),
    );
  }
}
