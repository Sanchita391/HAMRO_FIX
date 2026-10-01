import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hamro_fix/core/l10n/app_locale.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/screens/auth/landing_page.dart';
import 'package:hamro_fix/screens/reports/report_details_page.dart';
import 'package:hamro_fix/widgets/stored_image.dart';
import 'package:hamro_fix/widgets/web_narrow_body.dart';
import 'package:hamro_fix/widgets/xfile_preview.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/auth_services.dart';
import 'package:hamro_fix/services/report_service.dart';

Widget badgedIcon(IconData icon, int count) {
  return Badge(
    isLabelVisible: count > 0,
    label: Text('$count'),
    child: Icon(icon),
  );
}

class DashboardShell extends StatelessWidget {
  const DashboardShell({
    super.key,
    required this.title,
    required this.profile,
    required this.tabs,
  });

  final String title;
  final UserProfile profile;
  final List<DashboardTab> tabs;

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FBF6),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF6FBF6),
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          actions: [
            const LanguageToggle(),
            IconButton(
              tooltip: AppLocale.instance.t('Log out', 'लग आउट'),
              onPressed: () => confirmAndLogout(context),
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF2E7D32)),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: const Color(0xFF2E7D32),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF2E7D32),
            tabs: [for (final tab in tabs) Tab(text: tab.label)],
          ),
        ),
        body: TabBarView(children: [for (final tab in tabs) tab.child]),
      ),
    );
  }
}

class DashboardTab {
  const DashboardTab({required this.label, required this.child});
  final String label;
  final Widget child;
}

Future<void> confirmAndLogout(BuildContext context) async {
  final loc = AppLocale.instance;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(loc.t('Log out?', 'लग आउट गर्ने हो?')),
      content: Text(
        loc.t(
          'Are you sure you want to log out from HamroFix?',
          'के तपाईं हाम्रो फिक्सबाट लग आउट गर्न चाहनुहुन्छ?',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(loc.t('Stay', 'बस्नुहोस्')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(loc.t('Log out', 'लग आउट')),
        ),
      ],
    ),
  );
  if (ok == true) await AuthServices().signOut();
}

class UserPhotoAvatar extends StatelessWidget {
  const UserPhotoAvatar({
    super.key,
    required this.url,
    required this.name,
    this.radius = 20,
  });

  final String? url;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final provider = StoredImage.provider(url);
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFC8E6C9),
      backgroundImage: provider,
      child: provider == null
          ? Text(
              initial,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.85,
                color: const Color(0xFF1B5E20),
              ),
            )
          : null,
    );
  }
}

class HamroFixBarTitle extends StatelessWidget {
  const HamroFixBarTitle({
    super.key,
    required this.subtitle,
    this.title = 'HamroFix',
    this.photoUrl,
  });

  final String title;
  final String subtitle;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    return Row(
      children: [
        UserPhotoAvatar(url: photoUrl, name: subtitle, radius: 16),
        const SizedBox(width: 10),
        const HamroFixLogoBadge(size: 28, padding: 6),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const LanguageToggle(),
      ],
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _username;
  bool _saving = false;
  XFile? _newPhoto;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
    _phone = TextEditingController(
      text: widget.profile.phone.replaceFirst('+977', ''),
    );
    _username = TextEditingController(text: widget.profile.username ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null) setState(() => _newPhoto = file);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AuthServices().updateOwnProfile(
        uid: widget.profile.uid,
        name: _name.text,
        phone: _phone.text,
        profileImage: _newPhoto,
      );
      if (widget.profile.normalizedRole == UserRole.admin &&
          _username.text.trim().isNotEmpty) {
        await AuthServices().saveAdminUsername(_username.text);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final media = MediaQuery.of(context);
    final hasPhoto =
        _newPhoto != null ||
        (widget.profile.profileImageUrl != null &&
            widget.profile.profileImageUrl!.isNotEmpty);
    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.1),
      ),
      child: WebNarrowBody(
        maxWidth: 520,
        child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          AppLocale.instance.t(
            'Role: ${widget.profile.normalizedRole ?? 'unknown'}',
            'भूमिका: ${widget.profile.normalizedRole ?? 'unknown'}',
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _pickPhoto,
            child: _newPhoto != null
                ? XFileCircleImage(file: _newPhoto!, radius: 44)
                : UserPhotoAvatar(
                    url: widget.profile.profileImageUrl,
                    name: widget.profile.name,
                    radius: 44,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _pickPhoto,
            child: Text(
              hasPhoto
                  ? AppLocale.instance.t('Change photo', 'फोटो परिवर्तन गर्नुहोस्')
                  : AppLocale.instance.t(
                      'Add profile photo',
                      'प्रोफाइल फोटो थप्नुहोस्',
                    ),
            ),
          ),
        ),
        if (!widget.profile.hideContactEmail) ...[
          Text(
            AppLocale.instance.t(
              'Email: ${widget.profile.email}',
              'इमेल: ${widget.profile.email}',
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: AppLocale.instance.t('Name', 'नाम'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          decoration: InputDecoration(
            labelText: AppLocale.instance.t('Mobile Number', 'मोबाइल नम्बर'),
            prefixText: '+977 ',
          ),
        ),
        if (widget.profile.normalizedRole == UserRole.admin) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _username,
            decoration: const InputDecoration(
              labelText: 'Login username',
              hintText: 'admin',
              helperText:
                  'After saving, you can sign in with this username instead of email.',
            ),
          ),
        ],
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              _saving
                  ? AppLocale.instance.t('Saving...', 'सेभ हुँदै...')
                  : AppLocale.instance.t('Save profile', 'प्रोफाइल सेभ गर्नुहोस्'),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          AppLocale.instance.t('Change password', 'पासवर्ड परिवर्तन'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChangePasswordPage(profile: widget.profile),
                ),
              );
            },
            child: Text(AppLocale.instance.t('Change password', 'पासवर्ड परिवर्तन')),
          ),
        ),
      ],
      ),
      ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _changingPassword = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_currentPassword.text.isEmpty || _newPassword.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter your current password and a new password of at least 6 characters.',
          ),
        ),
      );
      return;
    }
    if (_newPassword.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match.')),
      );
      return;
    }
    setState(() => _changingPassword = true);
    try {
      await AuthServices().changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF6),
      appBar: AppBar(title: const Text('Change password')),
      body: WebNarrowBody(
        maxWidth: 480,
        child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!widget.profile.hideContactEmail) ...[
            Text(
              widget.profile.email,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _currentPassword,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Current password',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPassword,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New password',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPassword,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _changingPassword ? null : _changePassword,
              child: Text(_changingPassword ? 'Updating...' : 'Update password'),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class ReportList extends StatelessWidget {
  const ReportList({
    super.key,
    required this.stream,
    required this.profile,
    this.onAccept,
    this.onReject,
    this.onDuplicate,
    this.onComplete,
    this.onAssign,
    this.workers = const [],
  });

  final Stream<List<ReportIssue>> stream;
  final UserProfile profile;
  final Future<void> Function(ReportIssue report)? onAccept;
  final Future<void> Function(ReportIssue report)? onReject;
  final Future<void> Function(ReportIssue report)? onDuplicate;
  final Future<void> Function(ReportIssue report)? onComplete;
  final Future<void> Function(ReportIssue report, UserProfile worker)? onAssign;
  final List<UserProfile> workers;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReportIssue>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(AuthMessages.from(snapshot.error!)));
        }
        final reports = snapshot.data ?? [];
        if (reports.isEmpty) {
          return const Center(child: Text('No reports yet.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final report = reports[index];
            return Card(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ReportDetailsPage(report: report, profile: profile),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(report.description),
                      const SizedBox(height: 6),
                      Text('Status: ${report.status}'),
                      if (report.crewLabel.isNotEmpty)
                        Text('Workers: ${report.crewLabel}'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (onAccept != null)
                            TextButton(
                              onPressed: () => onAccept!(report),
                              child: const Text('Accept'),
                            ),
                          if (onReject != null)
                            TextButton(
                              onPressed: () => onReject!(report),
                              child: const Text('Reject'),
                            ),
                          if (onDuplicate != null)
                            TextButton(
                              onPressed: () => onDuplicate!(report),
                              child: const Text('Duplicate'),
                            ),
                          if (onComplete != null)
                            TextButton(
                              onPressed: () => onComplete!(report),
                              child: const Text('Complete'),
                            ),
                          if (onAssign != null && workers.isNotEmpty)
                            DropdownButton<UserProfile>(
                              hint: const Text('Assign worker'),
                              items: [
                                for (final worker in workers)
                                  DropdownMenuItem(
                                    value: worker,
                                    child: Text(worker.name),
                                  ),
                              ],
                              onChanged: (worker) {
                                if (worker != null) onAssign!(report, worker);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class CreateReportTab extends StatefulWidget {
  const CreateReportTab({super.key});

  @override
  State<CreateReportTab> createState() => _CreateReportTabState();
}

class _CreateReportTabState extends State<CreateReportTab> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _category = 'Road';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _description.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ReportService().createReport(
        title: _title.text,
        description: _description.text,
        category: _category,
      );
      if (!mounted) return;
      _title.clear();
      _description.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report submitted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Issue title'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _category,
          items: const [
            DropdownMenuItem(value: 'Road', child: Text('Road')),
            DropdownMenuItem(value: 'Water', child: Text('Water')),
            DropdownMenuItem(value: 'Electricity', child: Text('Electricity')),
            DropdownMenuItem(value: 'Waste', child: Text('Waste')),
          ],
          onChanged: (value) => setState(() => _category = value ?? 'Road'),
          decoration: const InputDecoration(labelText: 'Category'),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
          child: Text(_saving ? 'Submitting...' : 'Submit report'),
        ),
      ],
    );
  }
}
