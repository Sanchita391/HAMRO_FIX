import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/budget_service.dart';
import 'package:hamro_fix/services/feed_service.dart';
import 'package:hamro_fix/services/notification_service.dart';
import 'package:hamro_fix/services/report_service.dart';

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppNotification>>(
      stream: NotificationService().watchMine(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(AuthMessages.from(snapshot.error!)));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No notifications yet.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              color: item.read ? Colors.white : const Color(0xFFE8F5E9),
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(item.body),
                trailing: item.read
                    ? null
                    : TextButton(
                        onPressed: () => NotificationService().markRead(item.id),
                        child: const Text('Mark read'),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class FeedTab extends StatefulWidget {
  const FeedTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  final _text = TextEditingController();
  XFile? _image;
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _image = file);
  }

  Future<void> _post() async {
    if (_text.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await FeedService().createPost(
        authorName: widget.profile.name,
        text: _text.text,
        image: _image,
      );
      _text.clear();
      _image = null;
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _text,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Share an update',
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _pick,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(_image == null ? 'Photo' : 'Photo selected'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving ? null : _post,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                    child: Text(_saving ? 'Posting...' : 'Post'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<FeedPost>>(
            stream: FeedService().watchPosts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final posts = snapshot.data!;
              if (posts.isEmpty) {
                return const Center(child: Text('No posts yet.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(post.text),
                          if (post.imageUrl != null) ...[
                            const SizedBox(height: 8),
                            Image.network(post.imageUrl!, height: 180),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class BudgetTab extends StatefulWidget {
  const BudgetTab({super.key, this.canEdit = false});

  final bool canEdit;

  @override
  State<BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends State<BudgetTab> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String _category = 'Infrastructure';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    if (_title.text.trim().isEmpty || amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title and valid amount.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await BudgetService().createBudget(
        title: _title.text,
        category: _category,
        amount: amount,
        notes: _notes.text,
      );
      _title.clear();
      _amount.clear();
      _notes.clear();
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
    return Column(
      children: [
        if (widget.canEdit)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Budget title'),
                ),
                TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (NPR)'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  items: const [
                    DropdownMenuItem(
                      value: 'Infrastructure',
                      child: Text('Infrastructure'),
                    ),
                    DropdownMenuItem(value: 'Water', child: Text('Water')),
                    DropdownMenuItem(value: 'Waste', child: Text('Waste')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setState(() => _category = value ?? 'Infrastructure'),
                ),
                TextField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                  child: Text(_saving ? 'Saving...' : 'Add budget item'),
                ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<List<BudgetItem>>(
            stream: BudgetService().watchBudgets(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const Center(child: Text('No budget items yet.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      title: Text(item.title),
                      subtitle: Text('${item.category}\n${item.notes}'),
                      trailing: Text('NPR ${item.amount.toStringAsFixed(0)}'),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ReportsMapTab extends StatelessWidget {
  const ReportsMapTab({super.key, required this.stream});

  final Stream<List<ReportIssue>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReportIssue>>(
      stream: stream,
      builder: (context, snapshot) {
        final reports = (snapshot.data ?? [])
            .where((report) => report.hasLocation)
            .toList();
        final center = reports.isNotEmpty
            ? LatLng(reports.first.latitude!, reports.first.longitude!)
            : const LatLng(27.7172, 85.3240);
        return FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 12),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'app.hamro_fix',
            ),
            MarkerLayer(
              markers: [
                for (final report in reports)
                  Marker(
                    point: LatLng(report.latitude!, report.longitude!),
                    width: 40,
                    height: 40,
                    child: Tooltip(
                      message: report.title,
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFF2E7D32),
                        size: 36,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
