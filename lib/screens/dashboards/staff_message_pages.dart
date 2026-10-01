import 'package:flutter/material.dart';

import 'package:hamro_fix/core/theme/app_theme.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/screens/dashboards/shared_tabs.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/notification_service.dart';
import 'package:hamro_fix/widgets/web_narrow_body.dart';

void openNotificationsPage(BuildContext context, UserProfile profile) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => WebPageScaffold(
        title: 'Notifications',
        maxWidth: 720,
        body: NotificationsTab(uid: profile.uid, profile: profile),
      ),
    ),
  );
}

void openStaffMessagesPage(BuildContext context, UserProfile profile) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => WebPageScaffold(
        title: 'Messages',
        maxWidth: 720,
        body: NotificationsTab(
          uid: profile.uid,
          profile: profile,
          staffMessagesOnly: true,
        ),
      ),
    ),
  );
}

void openSendAlertPage(BuildContext context, UserProfile profile) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SendAlertPage(profile: profile),
    ),
  );
}

class SendAlertPage extends StatelessWidget {
  const SendAlertPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final hint = switch (profile.staffRole) {
      UserRole.worker => 'Send an extra note to an official',
      UserRole.official => 'Send an extra note to a worker or admin',
      UserRole.admin => 'Send an extra note to an official or worker',
      _ => 'Send an extra alert',
    };
    return Scaffold(
      backgroundColor: HamroFixTheme.canvas,
      appBar: AppBar(title: const Text('Send alert')),
      body: WebNarrowBody(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(hint, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            _ComposeAlertCard(sender: profile),
          ],
        ),
      ),
    );
  }
}

class StaffAlertsHub extends StatelessWidget {
  const StaffAlertsHub({
    super.key,
    required this.profile,
    required this.unreadNotifications,
    required this.unreadMessages,
  });

  final UserProfile profile;
  final int unreadNotifications;
  final int unreadMessages;

  String get _inboxSubtitle {
    switch (profile.staffRole) {
      case UserRole.worker:
        return 'Messages from officials';
      case UserRole.official:
        return 'Messages from workers and admin';
      case UserRole.admin:
        return 'Messages from officials';
      default:
        return 'Staff messages';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _HubTile(
          icon: Icons.notifications_rounded,
          color: const Color(0xFFE65100),
          title: 'Notifications',
          subtitle: 'Report, budget, and task updates',
          badge: unreadNotifications,
          onTap: () => openNotificationsPage(context, profile),
        ),
        const SizedBox(height: 10),
        _HubTile(
          icon: Icons.mail_rounded,
          color: const Color(0xFF1565C0),
          title: 'Messages',
          subtitle: _inboxSubtitle,
          badge: unreadMessages,
          onTap: () => openStaffMessagesPage(context, profile),
        ),
        const SizedBox(height: 10),
        _HubTile(
          icon: Icons.send_rounded,
          color: HamroFixTheme.mediumGreen,
          title: 'Send alert',
          subtitle: 'Write an extra message to staff',
          onTap: () => openSendAlertPage(context, profile),
        ),
      ],
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge > 0)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Badge(label: Text('$badge')),
              ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _ComposeAlertCard extends StatefulWidget {
  const _ComposeAlertCard({required this.sender});

  final UserProfile sender;

  @override
  State<_ComposeAlertCard> createState() => _ComposeAlertCardState();
}

class _ComposeAlertCardState extends State<_ComposeAlertCard> {
  final _message = TextEditingController();
  List<UserProfile> _people = [];
  UserProfile? _to;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final people = await NotificationService().listAlertRecipients(
        widget.sender,
      );
      if (!mounted) return;
      setState(() {
        _people = people;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final person = _to;
    if (person == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose who should receive this alert.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await NotificationService().sendStaffMessage(
        sender: widget.sender,
        recipient: person,
        message: _message.text,
      );
      if (!mounted) return;
      _message.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alert sent to ${person.displayName}.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else if (_people.isEmpty)
              const Text('No matching staff accounts to message yet.')
            else
              DropdownButtonFormField<String>(
                initialValue: _to?.uid,
                decoration: const InputDecoration(
                  labelText: 'Send to',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final person in _people)
                    DropdownMenuItem(
                      value: person.uid,
                      child: Text(
                        '${person.displayName} · ${person.staffRole}',
                      ),
                    ),
                ],
                onChanged: _sending
                    ? null
                    : (value) {
                        setState(() {
                          _to = _people
                              .where((person) => person.uid == value)
                              .firstOrNull;
                        });
                      },
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _message,
              enabled: !_sending && _people.isNotEmpty,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: _sending || _people.isEmpty ? null : _send,
                child: Text(_sending ? 'Sending...' : 'Send alert'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
