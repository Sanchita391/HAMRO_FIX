import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'package:hamro_fix/core/l10n/app_locale.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/budget_service.dart';
import 'package:hamro_fix/services/feed_service.dart';
import 'package:hamro_fix/services/notification_service.dart';
import 'package:hamro_fix/services/report_service.dart';
import 'package:hamro_fix/widgets/stored_image.dart';

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key, required this.uid, this.profile});

  final String uid;
  final UserProfile? profile;

  bool _canPost(AppNotification item) {
    if (profile == null || item.relatedId == null || item.relatedId!.isEmpty) {
      return false;
    }
    return item.type == 'budget' ||
        item.type == 'completed' ||
        item.type == 'task';
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleScope.of(context);
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
          return Center(
            child: Text(
              loc.t('No notifications yet.', 'अहिले सूचना छैन।'),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              color: item.read ? Colors.white : const Color(0xFFE8F5E9),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(item.body),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (!item.read)
                          TextButton(
                            onPressed: () =>
                                NotificationService().markRead(item.id),
                            child: Text(loc.t('Mark read', 'पढियो')),
                          ),
                        const Spacer(),
                        if (_canPost(item))
                          ReportFeedPostButton(
                            profile: profile!,
                            reportId: item.relatedId!,
                            onPosted: () =>
                                NotificationService().markRead(item.id),
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

class ReportFeedPostButton extends StatelessWidget {
  const ReportFeedPostButton({
    super.key,
    required this.profile,
    required this.reportId,
    this.onPosted,
  });

  final UserProfile profile;
  final String reportId;
  final VoidCallback? onPosted;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ReportService().watchReport(reportId),
      builder: (context, snapshot) {
        final doc = snapshot.data;
        if (doc == null || !doc.exists) {
          return const SizedBox.shrink();
        }
        final report = ReportIssue.fromFirestore(doc);
        final canShow =
            report.canPublicPostBudget || report.canPublicPostAfter;
        if (!canShow) return const SizedBox.shrink();
        final posted = report.isFeedActionPosted;
        return FilledButton(
          onPressed: posted
              ? null
              : () async {
                  onPosted?.call();
                  if (!context.mounted) return;
                  await openReportFeedComposer(
                    context: context,
                    profile: profile,
                    reportId: reportId,
                  );
                },
          style: FilledButton.styleFrom(
            backgroundColor: posted
                ? const Color(0xFF9E9E9E)
                : const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF9E9E9E),
            disabledForegroundColor: Colors.white,
          ),
          child: Text(report.feedActionLabel),
        );
      },
    );
  }
}

class FeedTab extends StatelessWidget {
  const FeedTab({
    super.key,
    required this.profile,
    this.mineOnly = false,
  });

  final UserProfile profile;
  final bool mineOnly;

  @override
  Widget build(BuildContext context) {
    return mineOnly
        ? _MyFeedPage(profile: profile)
        : _PublicFeedPage(profile: profile);
  }
}

class _PublicFeedPage extends StatelessWidget {
  const _PublicFeedPage({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FeedPost>>(
      stream: FeedService().watchPosts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(AuthMessages.from(snapshot.error!)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final posts = snapshot.data!;
        if (posts.isEmpty) {
          return Center(
            child: Text(
              LocaleScope.of(context).t('No posts yet.', 'अहिले पोस्ट छैन।'),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _FeedPostCard(
              key: ValueKey(posts[index].id),
              post: posts[index],
              profile: profile,
            );
          },
        );
      },
    );
  }
}

class _MyFeedPage extends StatefulWidget {
  const _MyFeedPage({required this.profile});

  final UserProfile profile;

  @override
  State<_MyFeedPage> createState() => _MyFeedPageState();
}

class _MyFeedPageState extends State<_MyFeedPage> {
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
    if (_text.text.trim().isEmpty && _image == null) return;
    setState(() => _saving = true);
    try {
      await FeedService().createPost(
        authorName: widget.profile.displayName,
        text: _text.text.trim().isEmpty ? 'Update' : _text.text,
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
    final name = widget.profile.displayName;
    final initial = name.isEmpty ? 'P' : name[0].toUpperCase();
    return StreamBuilder<List<FeedPost>>(
      stream: FeedService().watchMyPosts(widget.profile.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(AuthMessages.from(snapshot.error!)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final loc = LocaleScope.of(context);
        final posts = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: posts.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        loc.t("What's new today", 'आज के नयाँ छ'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFC8E6C9),
                            backgroundImage: StoredImage.provider(
                              widget.profile.profileImageUrl,
                            ),
                            child:
                                StoredImage.provider(
                                      widget.profile.profileImageUrl,
                                    ) ==
                                    null
                                ? Text(
                                    initial,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  loc.t('Write a caption', 'क्याप्सन लेख्नुहोस्'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _text,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: loc.t(
                                      "What's on your mind, $name?",
                                      '$name, तपाईं के सोच्दै हुनुहुन्छ?',
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF0F2F5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_image != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Chip(
                            label: Text(loc.t('Photo attached', 'फोटो जोडियो')),
                            onDeleted: () => setState(() => _image = null),
                          ),
                        ),
                      ],
                      const Divider(height: 22),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: _pick,
                            icon: const Icon(
                              Icons.photo_library_outlined,
                              color: Color(0xFF2E7D32),
                            ),
                            label: Text(loc.t('Photo', 'फोटो')),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: _saving ? null : _post,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              _saving
                                  ? loc.t('Posting...', 'पोस्ट हुँदै...')
                                  : loc.t('Post', 'पोस्ट'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
            return _FeedPostCard(
              key: ValueKey(posts[index - 1].id),
              post: posts[index - 1],
              profile: widget.profile,
              canManage: true,
            );
          },
        );
      },
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
                    foregroundColor: Colors.white,
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

Future<void> openReportFeedComposer({
  required BuildContext context,
  required UserProfile profile,
  required String reportId,
}) async {
  try {
    final report = await ReportService().fetchReport(reportId);
    if (!context.mounted) return;
    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocale.instance.t(
              'That report was not found.',
              'त्यो रिपोर्ट भेटिएन।',
            ),
          ),
        ),
      );
      return;
    }
    if (report.uid != profile.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocale.instance.t(
              'You can only post your own reports.',
              'तपाईं आफ्नै रिपोर्ट मात्र पोस्ट गर्न सक्नुहुन्छ।',
            ),
          ),
        ),
      );
      return;
    }
    if (report.isFeedActionPosted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocale.instance.t(
              'This update is already posted.',
              'यो अपडेट पहिले नै पोस्ट भइसकेको छ।',
            ),
          ),
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _FeedCaptionSheet(profile: profile, report: report),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
  }
}

class _FeedCaptionSheet extends StatefulWidget {
  const _FeedCaptionSheet({required this.profile, required this.report});

  final UserProfile profile;
  final ReportIssue report;

  @override
  State<_FeedCaptionSheet> createState() => _FeedCaptionSheetState();
}

class _FeedCaptionSheetState extends State<_FeedCaptionSheet> {
  late final TextEditingController _caption;
  bool _anonymous = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final report = widget.report;
    _caption = TextEditingController(
      text: report.approvedBudgetAmount == null
          ? '${report.category} in ${report.municipality ?? 'our ward'}.'
          : '${report.category} is funded. Final budget NPR ${report.approvedBudgetAmount!.toStringAsFixed(0)}.',
    );
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    try {
      await ReportService().publishToFeed(
        report: widget.report,
        anonymous: _anonymous,
        caption: _caption.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.report.canPublicPostAfter
                ? 'Your post now shows before and after photos.'
                : 'Posted to the public feed.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleScope.of(context);
    final report = widget.report;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, inset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            report.canPublicPostAfter
                ? loc.t('Post before & after', 'अघि र पछिको तस्बिर पोस्ट गर्नुहोस्')
                : loc.t('Post on your feed', 'आफ्नो फिडमा पोस्ट गर्नुहोस्'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            loc.t(
              'Other public users will see this caption, likes, and comments.',
              'अन्य सार्वजनिक प्रयोगकर्ताले यो क्याप्सन, लाइक र टिप्पणी देख्नेछन्।',
            ),
            style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
          ),
          if (report.publicId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              report.publicId,
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _caption,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: loc.t('Write a caption', 'क्याप्सन लेख्नुहोस्'),
              hintText: loc.t(
                'Tell other public users what happened…',
                'अन्य सार्वजनिक प्रयोगकर्तालाई के भयो भन्नुहोस्…',
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(loc.t('Post anonymously', 'बेनामी पोस्ट गर्नुहोस्')),
            value: _anonymous,
            onChanged: (value) => setState(() => _anonymous = value),
          ),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(
              _busy
                  ? loc.t('Posting...', 'पोस्ट हुँदै...')
                  : loc.t(
                      'Post for other public to see',
                      'अन्य सार्वजनिकलाई देखिने गरी पोस्ट गर्नुहोस्',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

String _feedTimeAgo(DateTime? time) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${time.day}/${time.month}/${time.year}';
}

class _FeedPostCard extends StatefulWidget {
  const _FeedPostCard({
    super.key,
    required this.post,
    required this.profile,
    this.canManage = false,
  });

  final FeedPost post;
  final UserProfile profile;
  final bool canManage;

  @override
  State<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<_FeedPostCard> {
  late bool _liked;
  late int _likes;
  late int _comments;
  bool _likeBusy = false;
  int? _syncedCount;

  @override
  void initState() {
    super.initState();
    _syncLikes(widget.post);
  }

  @override
  void didUpdateWidget(covariant _FeedPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_likeBusy) _syncLikes(widget.post);
  }

  void _syncLikes(FeedPost post) {
    _liked = post.likedByUser(widget.profile.uid);
    _likes = post.likeCount;
    _comments = post.commentCount;
  }

  Future<void> _edit() async {
    final loc = AppLocale.instance;
    final controller = TextEditingController(text: widget.post.text);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.t('Edit post', 'पोस्ट सम्पादन')),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: loc.t('Caption', 'क्याप्सन'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.t('Cancel', 'रद्द')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(loc.t('Save', 'सेभ')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (next == null || next.isEmpty || !mounted) return;
    try {
      await FeedService().updatePost(postId: widget.post.id, text: next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.instance.t('Post updated.', 'पोस्ट अपडेट भयो।')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
    }
  }

  Future<void> _delete() async {
    final loc = AppLocale.instance;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.t('Delete post?', 'पोस्ट मेट्ने हो?')),
        content: Text(
          loc.t(
            'This removes the post from your feed and the public feed.',
            'यो पोस्ट तपाईंको फिड र सार्वजनिक फिडबाट हट्छ।',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.t('Cancel', 'रद्द')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.t('Delete', 'मेटाउनुहोस्')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await FeedService().deletePost(widget.post.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.instance.t('Post deleted.', 'पोस्ट मेटियो।')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
    }
  }

  Future<void> _toggleLike() async {
    final wasLiked = _liked;
    setState(() {
      _likeBusy = true;
      _liked = !wasLiked;
      _likes += wasLiked ? -1 : 1;
      if (_likes < 0) _likes = 0;
    });
    try {
      await FeedService().toggleLike(widget.post.id, liked: wasLiked);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _liked = wasLiked;
        _likes = widget.post.likeCount;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  void _openComments() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _FeedCommentsSheet(
        post: widget.post,
        profile: widget.profile,
        onAdded: () {
          if (mounted) setState(() => _comments += 1);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleScope.of(context);
    final post = widget.post;
    final mine = widget.canManage && post.uid == widget.profile.uid;
    final initial = post.authorName.trim().isEmpty
        ? 'P'
        : post.authorName.trim()[0].toUpperCase();
    final time = _feedTimeAgo(post.createdAt);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFC8E6C9),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName.isEmpty
                            ? loc.t('Public', 'सार्वजनिक')
                            : post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (post.trackingCode != null || time.isNotEmpty)
                        Text(
                          [
                            if (post.trackingCode != null) post.trackingCode!,
                            if (time.isNotEmpty) time,
                          ].join(' · '),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (mine)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _edit();
                      if (value == 'delete') _delete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(loc.t('Edit', 'सम्पादन')),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(loc.t('Delete', 'मेटाउनुहोस्')),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          _FeedLinkedMedia(post: post),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _toggleLike,
                      icon: Icon(
                        _liked ? Icons.favorite : Icons.favorite_border,
                        color: _liked
                            ? const Color(0xFFC62828)
                            : Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: _openComments,
                      icon: const Icon(Icons.mode_comment_outlined),
                    ),
                  ],
                ),
                StreamBuilder<int>(
                  stream: FeedService().watchCommentCount(post.id),
                  initialData: widget.post.commentCount,
                  builder: (context, commentSnap) {
                    final comments = commentSnap.data ?? 0;
                    if (comments != widget.post.commentCount &&
                        _syncedCount != comments) {
                      _syncedCount = comments;
                      FeedService().syncCommentCount(post.id, comments);
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Text(
                                _likes == 1
                                    ? loc.t('1 like', '१ लाइक')
                                    : loc.t(
                                        '$_likes likes',
                                        '$_likes लाइक',
                                      ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                comments == 1
                                    ? loc.t('1 comment', '१ टिप्पणी')
                                    : loc.t(
                                        '$comments comments',
                                        '$comments टिप्पणी',
                                      ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (post.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            child: Text(
                              post.text,
                              style: const TextStyle(height: 1.35),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedLinkedMedia extends StatelessWidget {
  const _FeedLinkedMedia({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final before = post.imageUrl;
    final after = post.afterImageUrl;
    if ((before == null || before.isEmpty) &&
        (after == null || after.isEmpty)) {
      return const SizedBox.shrink();
    }
    return _FeedMedia(before: before, after: after);
  }
}

class _FeedMedia extends StatelessWidget {
  const _FeedMedia({this.before, this.after});

  final String? before;
  final String? after;

  @override
  Widget build(BuildContext context) {
    final loc = LocaleScope.of(context);
    final images = <(String, String)>[
      if (before != null) (loc.t('Before', 'अघि'), before!),
      if (after != null && after != before) (loc.t('After', 'पछि'), after!),
    ];
    if (images.isEmpty) return const SizedBox.shrink();
    if (images.length == 1) {
      return StoredImage(images.first.$2, height: 260, width: double.infinity);
    }
    return SizedBox(
      height: 260,
      child: PageView(
        children: [
          for (final item in images)
            Stack(
              fit: StackFit.expand,
              children: [
                StoredImage(item.$2, height: 260, width: double.infinity),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.$1,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FeedCommentsSheet extends StatefulWidget {
  const _FeedCommentsSheet({
    required this.post,
    required this.profile,
    this.onAdded,
  });

  final FeedPost post;
  final UserProfile profile;
  final VoidCallback? onAdded;

  @override
  State<_FeedCommentsSheet> createState() => _FeedCommentsSheetState();
}

class _FeedCommentsSheetState extends State<_FeedCommentsSheet> {
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await FeedService().addComment(
        postId: widget.post.id,
        authorName: widget.profile.name,
        text: text,
      );
      _comment.clear();
      widget.onAdded?.call();
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
    final loc = LocaleScope.of(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loc.t('Comments', 'टिप्पणी'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<FeedComment>>(
                stream: FeedService().watchComments(widget.post.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(AuthMessages.from(snapshot.error!)));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final comments = snapshot.data!;
                  if (comments.isEmpty) {
                    return Center(
                      child: Text(loc.t('No comments yet.', 'अहिले टिप्पणी छैन।')),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.authorName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(comment.text),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _comment,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: loc.t('Write a comment…', 'टिप्पणी लेख्नुहोस्…'),
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      icon: Icon(
                        Icons.send_rounded,
                        color: _sending
                            ? Colors.black26
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

