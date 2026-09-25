import 'package:flutter/material.dart';

import 'package:hamro_fix/core/constants/app_constants.dart';
import 'package:hamro_fix/core/l10n/app_locale.dart';
import 'package:hamro_fix/core/theme/app_theme.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/screens/dashboards/dashboard_widgets.dart';
import 'package:hamro_fix/screens/dashboards/shared_tabs.dart';
import 'package:hamro_fix/screens/dashboards/worker_payments_page.dart';
import 'package:hamro_fix/screens/reports/report_details_page.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/notification_service.dart';
import 'package:hamro_fix/services/report_service.dart';
import 'package:hamro_fix/widgets/stored_image.dart';

bool _isOpenTask(ReportIssue item) {
  return item.status != ReportStatus.completed &&
      item.status != ReportStatus.workCompleted &&
      item.status != ReportStatus.publicFeed &&
      item.status != ReportStatus.verifiedFake &&
      item.status != ReportStatus.officialDeclined;
}

bool _isDoneTask(ReportIssue item) {
  return item.status == ReportStatus.workCompleted ||
      item.status == ReportStatus.completed ||
      item.status == ReportStatus.publicFeed;
}

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  int _index = 0;
  final Set<String> _seenTaskIds = {};

  Future<void> _onTab(int value, {List<ReportIssue> openTasks = const []}) async {
    setState(() {
      _index = value;
      if (value == 1) {
        _seenTaskIds.addAll(openTasks.map((item) => item.id));
      }
    });
    if (value == 3) {
      await NotificationService().markAllRead(widget.profile.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleScope.of(context);
    final reports = ReportService();
    return StreamBuilder<List<ReportIssue>>(
      stream: reports.watchAssignedReports(widget.profile.uid),
      builder: (context, snapshot) {
        final jobs = snapshot.data ?? [];
        final open = jobs.where(_isOpenTask).toList();
        if (_index == 1) {
          _seenTaskIds.addAll(open.map((item) => item.id));
        }
        final unseen = _index == 1
            ? 0
            : open.where((item) => !_seenTaskIds.contains(item.id)).length;
        return StreamBuilder<List<AppNotification>>(
          stream: NotificationService().watchMine(widget.profile.uid),
          builder: (context, alertSnap) {
            final unread = (alertSnap.data ?? [])
                .where((item) => !item.read)
                .length;
            return Scaffold(
              backgroundColor: HamroFixTheme.canvas,
              appBar: AppBar(
                backgroundColor: HamroFixTheme.canvas,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                title: HamroFixBarTitle(
                  subtitle: widget.profile.displayName,
                ),
                actions: [
                  IconButton(
                    tooltip: loc.t('Log out', 'लग आउट'),
                    onPressed: () => confirmAndLogout(context),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: HamroFixTheme.mediumGreen,
                    ),
                  ),
                ],
              ),
              body: IndexedStack(
                index: _index,
                children: [
                  _WorkerHome(
                    profile: widget.profile,
                    jobs: jobs,
                    loading:
                        snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData,
                    error: snapshot.hasError
                        ? AuthMessages.from(snapshot.error!)
                        : null,
                    onOpenTasks: () => _onTab(1, openTasks: open),
                  ),
                  _WorkerTaskList(
                    reports: open,
                    profile: widget.profile,
                    loading:
                        snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData,
                    error: snapshot.hasError
                        ? AuthMessages.from(snapshot.error!)
                        : null,
                  ),
                  WorkerPaymentsTab(profile: widget.profile),
                  NotificationsTab(uid: widget.profile.uid),
                  SafeArea(
                    child: ProfileTab(profile: widget.profile),
                  ),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (value) =>
                    _onTab(value, openTasks: open),
                indicatorColor: const Color(0xFFC8E6C9),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.handyman_outlined),
                    selectedIcon: const Icon(Icons.handyman_rounded),
                    label: loc.t('Home', 'गृह'),
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: unseen > 0,
                      label: Text('$unseen'),
                      child: const Icon(Icons.assignment_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: unseen > 0,
                      label: Text('$unseen'),
                      child: const Icon(Icons.assignment_rounded),
                    ),
                    label: loc.t('Task', 'काम'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.payments_outlined),
                    selectedIcon: const Icon(Icons.payments_rounded),
                    label: loc.t('Pay', 'भुक्तानी'),
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: const Icon(Icons.notifications_rounded),
                    ),
                    label: loc.t('Alerts', 'सूचना'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline),
                    selectedIcon: const Icon(Icons.person_rounded),
                    label: loc.t('Profile', 'प्रोफाइल'),
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

class _WorkerTaskList extends StatelessWidget {
  const _WorkerTaskList({
    required this.reports,
    required this.profile,
    required this.loading,
    this.error,
  });

  final List<ReportIssue> reports;
  final UserProfile profile;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: HamroFixTheme.mediumGreen),
      );
    }
    if (error != null) {
      return Center(child: Text(error!));
    }
    if (reports.isEmpty) {
      return const Center(child: Text('No open tasks.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
          child: ListTile(
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
              backgroundColor: const Color(0xFFE8F5E9),
              backgroundImage: StoredImage.provider(report.imageUrl),
              child: StoredImage.provider(report.imageUrl) == null
                  ? const Icon(
                      Icons.assignment_rounded,
                      color: HamroFixTheme.mediumGreen,
                    )
                  : null,
            ),
            title: Text(
              report.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(report.publicId),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        );
      },
    );
  }
}

class _WorkerHome extends StatelessWidget {
  const _WorkerHome({
    required this.profile,
    required this.jobs,
    required this.loading,
    required this.error,
    required this.onOpenTasks,
  });

  final UserProfile profile;
  final List<ReportIssue> jobs;
  final bool loading;
  final String? error;
  final VoidCallback onOpenTasks;

  @override
  Widget build(BuildContext context) {
    final loc = LocaleScope.of(context);
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: HamroFixTheme.mediumGreen),
      );
    }
    if (error != null) {
      return Center(child: Text(error!));
    }
    final open = jobs.where(_isOpenTask).toList();
    final done = jobs.where(_isDoneTask).length;
    final hour = DateTime.now().hour;
    final hello = hour < 12
        ? loc.t('Good morning', 'शुभ प्रभात')
        : hour < 17
        ? loc.t('Good afternoon', 'शुभ दिउँसो')
        : loc.t('Good evening', 'शुभ सन्ध्या');
    final name = profile.name.trim().isEmpty
        ? loc.t('Worker', 'कामदार')
        : profile.name.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hello.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: loc.t('Open tasks', 'खुला काम'),
                value: '${open.length}',
                icon: Icons.assignment_late_outlined,
                onTap: onOpenTasks,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                label: loc.t('Completed', 'सम्पन्न'),
                value: '$done',
                icon: Icons.verified_outlined,
                onTap: onOpenTasks,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              loc.t('Next up', 'अर्को काम'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const Spacer(),
            TextButton(
              onPressed: onOpenTasks,
              child: Text(loc.t('See all', 'सबै हेर्नुहोस्')),
            ),
          ],
        ),
        if (open.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: HamroFixTheme.mediumGreen,
                ),
                const SizedBox(height: 8),
                Text(loc.t('No open tasks right now.', 'अहिले खुला काम छैन।')),
              ],
            ),
          )
        else
          ...open.take(4).map(
            (report) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
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
                    backgroundColor: const Color(0xFFE8F5E9),
                    backgroundImage: StoredImage.provider(report.imageUrl),
                    child: StoredImage.provider(report.imageUrl) == null
                        ? const Icon(
                            Icons.handyman_rounded,
                            color: HamroFixTheme.mediumGreen,
                          )
                        : null,
                  ),
                  title: Text(
                    report.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(report.publicId),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: HamroFixTheme.mediumGreen),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(label, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
