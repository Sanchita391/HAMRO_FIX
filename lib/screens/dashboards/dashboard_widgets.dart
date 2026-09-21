import 'package:flutter/material.dart';

import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/auth_services.dart';
import 'package:hamro_fix/services/report_service.dart';

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
            IconButton(
              tooltip: 'Log out',
              onPressed: () async {
                await AuthServices().signOut();
              },
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

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
    _phone = TextEditingController(
      text: widget.profile.phone.replaceFirst('+977', ''),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AuthServices().updateOwnProfile(
        uid: widget.profile.uid,
        name: _name.text,
        phone: _phone.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthMessages.from(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Role: ${widget.profile.normalizedRole ?? 'unknown'}'),
        const SizedBox(height: 8),
        Text('Email: ${widget.profile.email}'),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          decoration: const InputDecoration(
            labelText: 'Mobile Number',
            prefixText: '+977 ',
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
          child: Text(_saving ? 'Saving...' : 'Save profile'),
        ),
      ],
    );
  }
}

class ReportList extends StatelessWidget {
  const ReportList({
    super.key,
    required this.stream,
    this.onAccept,
    this.onReject,
    this.onDuplicate,
    this.onComplete,
    this.onAssign,
    this.workers = const [],
  });

  final Stream<List<ReportIssue>> stream;
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
                    if (report.assignedWorkerName != null)
                      Text('Worker: ${report.assignedWorkerName}'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthMessages.from(e))),
      );
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
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
          child: Text(_saving ? 'Submitting...' : 'Submit report'),
        ),
      ],
    );
  }
}
