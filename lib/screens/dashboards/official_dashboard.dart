import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:hamro_fix/core/constants/app_constants.dart';
import 'package:hamro_fix/core/l10n/app_locale.dart';
import 'package:hamro_fix/core/theme/app_theme.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/screens/dashboards/dashboard_widgets.dart';
import 'package:hamro_fix/screens/dashboards/staff_message_pages.dart';
import 'package:hamro_fix/screens/reports/budget_details_page.dart';
import 'package:hamro_fix/screens/reports/report_details_page.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/auth_services.dart';
import 'package:hamro_fix/services/budget_service.dart';
import 'package:hamro_fix/services/notification_service.dart';
import 'package:hamro_fix/services/report_service.dart';
import 'package:hamro_fix/services/task_service.dart';
import 'package:hamro_fix/widgets/application_review.dart';
import 'package:hamro_fix/widgets/login_invite_sheet.dart';
import 'package:hamro_fix/widgets/staff_dashboard_frame.dart';
import 'package:hamro_fix/widgets/report_video_player.dart';
import 'package:hamro_fix/widgets/stored_image.dart';
import 'package:hamro_fix/widgets/web_narrow_body.dart';
import 'package:hamro_fix/widgets/worker_payment.dart';

class OfficialDashboard extends StatefulWidget {
  const OfficialDashboard({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<OfficialDashboard> createState() => _OfficialDashboardState();
}

class _OfficialDashboardState extends State<OfficialDashboard> {
  int _index = 0;
  String _reportsFilter = 'completed';

  Future<void> _logout() async {
    await confirmAndLogout(context);
  }

  void _openPage(int page, {String? reportsFilter}) {
    setState(() {
      _index = page;
      if (reportsFilter != null) _reportsFilter = reportsFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleScope.of(context);
    return StreamBuilder<List<AppNotification>>(
      stream: NotificationService().watchMine(widget.profile.uid),
      builder: (context, alertSnap) {
        final alerts = alertSnap.data ?? [];
        final unreadCount = AppNotification.unreadCount(alerts);
        final unreadNotifications = AppNotification.unreadCount(
          alerts,
          excludeTypes: AlertType.messageBadge,
        );
        final unreadMessages = AppNotification.unreadCount(
          alerts,
          types: AlertType.messageBadge,
        );
        final unreadReports = AppNotification.unreadCount(
          alerts,
          types: AlertType.reportBadge,
        );
        final unreadBudgets = AppNotification.unreadCount(
          alerts,
          types: AlertType.budgetBadge,
        );
        return StreamBuilder<List<WorkerApplication>>(
          stream: AuthServices().watchWorkerApplications(),
          builder: (context, crewSnap) {
            final pendingCrew = (crewSnap.data ?? [])
                .where((item) => item.status == AccountStatus.pending)
                .length;
            return StaffDashboardFrame(
              title: loc.t(
                'Official Dashboard',
                'अधिकारी ड्यासबोर्ड',
              ),
              subtitle: widget.profile.displayName,
              photoUrl: widget.profile.profileImageUrl,
              selectedIndex: _index,
              onSelect: (value) => setState(() => _index = value),
              onLogout: _logout,
              items: [
                StaffNavItem(
                  icon: const Icon(Icons.account_balance_outlined),
                  selectedIcon: const Icon(Icons.account_balance_rounded),
                  label: loc.t('Home', 'गृह'),
                ),
                StaffNavItem(
                  icon: badgedIcon(Icons.assignment_outlined, unreadReports),
                  selectedIcon: badgedIcon(
                    Icons.assignment_rounded,
                    unreadReports,
                  ),
                  label: loc.t('Reports', 'रिपोर्ट'),
                ),
                StaffNavItem(
                  icon: Badge(
                    isLabelVisible: pendingCrew > 0,
                    label: Text('$pendingCrew'),
                    child: const Icon(Icons.engineering_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: pendingCrew > 0,
                    label: Text('$pendingCrew'),
                    child: const Icon(Icons.engineering_rounded),
                  ),
                  label: loc.t('Worker', 'कामदार'),
                ),
                StaffNavItem(
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    child: const Icon(Icons.apps_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    child: const Icon(Icons.apps_rounded),
                  ),
                  label: loc.t('More', 'थप'),
                ),
              ],
              body: IndexedStack(
                index: _index,
                children: [
                  _OfficialHome(
                    profile: widget.profile,
                    onOpen: _openPage,
                  ),
                  _OfficialReports(
                    profile: widget.profile,
                    initialFilter: _reportsFilter,
                  ),
                  _WorkerApprovalList(profile: widget.profile),
                  _MoreTab(
                    profile: widget.profile,
                    unreadCount: unreadCount,
                    unreadBudgets: unreadBudgets,
                    unreadNotifications: unreadNotifications,
                    unreadMessages: unreadMessages,
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

class _OfficialHome extends StatelessWidget {
  const _OfficialHome({required this.profile, required this.onOpen});

  final UserProfile profile;
  final void Function(int page, {String? reportsFilter}) onOpen;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReportIssue>>(
      stream: ReportService().watchAllReports(),
      builder: (context, reportsSnap) {
        return StreamBuilder<List<WorkerApplication>>(
          stream: AuthServices().watchWorkerApplications(),
          builder: (context, crewSnap) {
            return StreamBuilder<List<BudgetRequest>>(
              stream: BudgetService().watchBudgetRequests(),
              builder: (context, budgetSnap) {
                if (reportsSnap.hasError) {
                  return Center(
                    child: Text(AuthMessages.from(reportsSnap.error!)),
                  );
                }
                final reports = List<ReportIssue>.from(
                  reportsSnap.data ?? const <ReportIssue>[],
                )..sort(ReportIssue.compareOfficialPriority);
                final crew = crewSnap.data ?? [];
                final budgets = budgetSnap.data ?? [];
                final review = reports.where(_needsOfficialReview).toList();
                final assign = reports.where(_needsAssignment).toList();
                final funded = reports.where(_needsFundedDispatch).toList();
                final completedWork = reports
                    .where(_needsCompletionDispatch)
                    .toList();
                final pendingCrew = crew
                    .where((item) => item.status == AccountStatus.pending)
                    .toList();
                final pendingBudgets = budgets
                    .where(_canForwardBudget)
                    .toList();
                final openReports = reports
                    .where(
                      (item) =>
                          item.status != ReportStatus.completed &&
                          item.status != ReportStatus.verifiedFake &&
                          item.status != ReportStatus.officialDeclined,
                    )
                    .toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  children: [
                    _HeroBanner(name: profile.name),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'To review',
                            value: '${review.length}',
                            icon: Icons.fact_check_rounded,
                            color: const Color(0xFFE65100),
                            onTap: () => onOpen(1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Workers waiting',
                            value: '${pendingCrew.length}',
                            icon: Icons.how_to_reg_rounded,
                            color: HamroFixTheme.mediumGreen,
                            onTap: () => onOpen(2),
                          ),
                        ),
                        if (MediaQuery.sizeOf(context).width >= 900) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'Need worker',
                              value: '${assign.length}',
                              icon: Icons.person_add_alt_1_rounded,
                              color: const Color(0xFF1565C0),
                              onTap: () => onOpen(1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'Completed',
                              value: '${completedWork.length}',
                              icon: Icons.task_alt_rounded,
                              color: const Color(0xFF2E7D32),
                              onTap: () =>
                                  onOpen(1, reportsFilter: 'completed'),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (MediaQuery.sizeOf(context).width < 900) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Need worker',
                            value: '${assign.length}',
                            icon: Icons.person_add_alt_1_rounded,
                            color: const Color(0xFF1565C0),
                            onTap: () => onOpen(1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Completed',
                            value: '${completedWork.length}',
                            icon: Icons.task_alt_rounded,
                            color: const Color(0xFF2E7D32),
                            onTap: () =>
                                onOpen(1, reportsFilter: 'completed'),
                          ),
                        ),
                      ],
                    ),
                    ],
                    const SizedBox(height: 22),
                    _SectionHeader(
                      title: 'Needs your decision',
                      action: review.isEmpty ? null : 'See all',
                      onAction: () => onOpen(1),
                    ),
                    if (review.isEmpty)
                      const _EmptyHint(
                        icon: Icons.verified_outlined,
                        text: 'No public reports waiting for review.',
                      )
                    else
                      ...review
                          .take(3)
                          .map(
                            (report) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _HomeReportTile(
                                report: report,
                                profile: profile,
                              ),
                            ),
                          ),
                    const SizedBox(height: 12),
                    _SectionHeader(
                      title: 'Worker applications',
                      action: pendingCrew.isEmpty ? null : 'See all',
                      onAction: () => onOpen(2),
                    ),
                    if (pendingCrew.isEmpty)
                      const _EmptyHint(
                        icon: Icons.engineering_outlined,
                        text: 'No worker applications waiting.',
                      )
                    else
                      ...pendingCrew
                          .take(3)
                          .map(
                            (app) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _WorkerAppCard(application: app),
                            ),
                          ),
                    const SizedBox(height: 12),
                    _SectionHeader(
                      title: 'Budget to forward',
                      action: pendingBudgets.isEmpty ? null : 'See all',
                      onAction: () => onOpen(3),
                    ),
                    if (pendingBudgets.isEmpty)
                      const _EmptyHint(
                        icon: Icons.account_balance_wallet_outlined,
                        text: 'No budgets waiting to send to admin.',
                      )
                    else
                      ...pendingBudgets
                          .take(3)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _OfficialBudgetCard(item: item),
                            ),
                          ),
                    const SizedBox(height: 12),
                    _SectionHeader(
                      title: 'Completed by worker',
                      action: completedWork.isEmpty ? null : 'See all',
                      onAction: () =>
                          onOpen(1, reportsFilter: 'completed'),
                    ),
                    if (completedWork.isEmpty)
                      const _EmptyHint(
                        icon: Icons.task_alt_rounded,
                        text: 'No completed work waiting to send to the public.',
                      )
                    else
                      ...completedWork
                          .take(5)
                          .map(
                            (report) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _HomeReportTile(
                                report: report,
                                profile: profile,
                              ),
                            ),
                          ),
                    const SizedBox(height: 12),
                    _SectionHeader(
                      title: 'Admin-approved budget',
                      action: funded.isEmpty ? null : 'Send to field',
                      onAction: () => onOpen(1),
                    ),
                    if (funded.isEmpty)
                      const _EmptyHint(
                        icon: Icons.verified_outlined,
                        text: 'No approved budgets waiting to send to workers.',
                      )
                    else
                      ...funded
                          .take(3)
                          .map(
                            (report) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _HomeReportTile(
                                report: report,
                                profile: profile,
                              ),
                            ),
                          ),
                    const SizedBox(height: 8),
                    Text(
                      '${openReports.length} open civic jobs in this ward',
                      style: const TextStyle(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final greetingName = name.trim().isEmpty ? 'Official' : name.trim();
    final hour = DateTime.now().hour;
    final hello = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D3B1E),
                  Color(0xFF2E7D32),
                  Color(0xFF66BB6A),
                ],
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
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Official Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  greetingName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -18,
            top: -22,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
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
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 12),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const Spacer(),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: HamroFixTheme.mediumGreen, size: 28),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _HomeReportTile extends StatelessWidget {
  const _HomeReportTile({required this.report, required this.profile});

  final ReportIssue report;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ReportDetailsPage(report: report, profile: profile),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE8F5E9),
              backgroundImage: StoredImage.provider(report.imageUrl),
              child: StoredImage.provider(report.imageUrl) == null
                  ? Icon(
                      report.hasPlayableVideo
                          ? Icons.videocam_rounded
                          : Icons.report_outlined,
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
            subtitle: Text(
              [
                if (report.isAnonymous) 'Anonymous',
                report.category,
                if (_needsCompletionDispatch(report))
                  'Worker completed · send to public'
                else
                  _pretty(report.status),
              ].join(' · '),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
          if (report.hasPlayableVideo)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ReportVideoPlayer(report, height: 180),
            ),
        ],
      ),
    );
  }
}

class _OfficialReports extends StatefulWidget {
  const _OfficialReports({
    required this.profile,
    required this.initialFilter,
  });

  final UserProfile profile;
  final String initialFilter;

  @override
  State<_OfficialReports> createState() => _OfficialReportsState();
}

class _OfficialReportsState extends State<_OfficialReports> {
  late String _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  void didUpdateWidget(covariant _OfficialReports oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      _filter = widget.initialFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reports = ReportService();
    return StreamBuilder<List<UserProfile>>(
      stream: AuthServices().watchUsers(),
      builder: (context, usersSnap) {
        final workers = (usersSnap.data ?? [])
            .where(
              (user) =>
                  user.hasRole(UserRole.worker) &&
                  user.isApproved &&
                  !user.isRestricted,
            )
            .toList();
        return StreamBuilder<List<ReportIssue>>(
          stream: reports.watchAllReports(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(AuthMessages.from(snapshot.error!)));
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: HamroFixTheme.mediumGreen,
                ),
              );
            }
            final all = List<ReportIssue>.from(
              snapshot.data ?? const <ReportIssue>[],
            );
            final items = List<ReportIssue>.from(switch (_filter) {
              'review' => all.where(_needsOfficialReview),
              'assign' => all.where(_needsAssignment),
              'funded' => all.where(_needsFundedDispatch),
              'completed' => all.where(_needsCompletionDispatch),
              _ => all,
            })..sort(ReportIssue.compareOfficialPriority);
            return Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      for (final entry in [
                        ('review', 'Review'),
                        ('assign', 'Assign'),
                        ('funded', 'Funded'),
                        ('completed', 'Completed'),
                        ('all', 'All'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(entry.$2),
                            selected: _filter == entry.$1,
                            onSelected: (_) =>
                                setState(() => _filter = entry.$1),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? const _EmptyHint(
                          icon: Icons.assignment_outlined,
                          text: 'No reports in this view.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) => _OfficialReportCard(
                            report: items[index],
                            profile: widget.profile,
                            workers: workers,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _OfficialReportCard extends StatefulWidget {
  const _OfficialReportCard({
    required this.report,
    required this.profile,
    required this.workers,
  });

  final ReportIssue report;
  final UserProfile profile;
  final List<UserProfile> workers;

  @override
  State<_OfficialReportCard> createState() => _OfficialReportCardState();
}

class _OfficialReportCardState extends State<_OfficialReportCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(done)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickWorker() async {
    final selected = await showAssignWorkersSheet(
      context: context,
      workers: widget.workers,
      selectedIds: widget.report.crewIds,
      reportCategory: widget.report.category,
    );
    if (selected == null || selected.isEmpty) return;
    await _run(
      () => ReportService().assignWorkers(
        reportId: widget.report.id,
        workerIds: selected.map((person) => person.uid).toList(),
        workerNames: selected.map((person) => person.name).toList(),
        report: widget.report,
      ),
      widget.report.crewIds.isEmpty
          ? 'Assigned ${selected.length} worker(s).'
          : 'Extra worker(s) added to this task.',
    );
  }

  Future<void> _sendFunded() async {
    final report = widget.report;
    await _run(
      () => TaskService().assignFundedTask(
        report: report,
        workerId: report.inspectorIds.isEmpty
            ? ''
            : report.inspectorIds.first,
        workerIds: report.inspectorIds,
        instructions:
            'Complete funded work for ${report.publicId}. Approved budget NPR ${report.approvedBudgetAmount?.toStringAsFixed(0) ?? '0'}.',
      ),
      'Approved budget sent to the worker and the public reporter.',
    );
  }

  Future<void> _sendCompletion() async {
    await _run(
      () => ReportService().shareCompletionWithPublic(widget.report),
      'Completed photos sent to the public reporter.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final review = _needsOfficialReview(report);
    final assign = _needsAssignment(report);
    return Card(
      elevation: 0,
      color: report.isAnonymous ? const Color(0xFFEEEEEE) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReportDetailsPage(
                      report: report,
                      profile: widget.profile,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFE8F5E9),
                        backgroundImage: StoredImage.provider(report.imageUrl),
                        child: StoredImage.provider(report.imageUrl) == null
                            ? Icon(
                                report.hasPlayableVideo
                                    ? Icons.videocam_rounded
                                    : Icons.report_outlined,
                                color: HamroFixTheme.mediumGreen,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              [
                                report.publicId,
                                report.category,
                                if (report.isAnonymous) 'Anonymous',
                              ].join(' · '),
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusChip(status: report.status),
                    ],
                  ),
                  if (report.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      report.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (report.crewLabel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Workers: ${report.crewLabel}',
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            ReportVideoPlayer(report, height: 200),
              if (review) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                () => ReportService().officialDecision(
                                  report: report,
                                  status: ReportStatus.officialDeclined,
                                  reason: 'Declined by official',
                                ),
                                'Report declined.',
                              ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                () => ReportService().officialDecision(
                                  report: report,
                                  status: ReportStatus.officialAccepted,
                                ),
                                'Report accepted.',
                              ),
                        child: Text(_busy ? 'Working...' : 'Accept'),
                      ),
                    ),
                  ],
                ),
              ],
              if (assign) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _pickWorker,
                    child: Text(
                      _busy
                          ? 'Working...'
                          : report.crewIds.isEmpty
                          ? 'Assign workers'
                          : 'Add more workers',
                    ),
                  ),
                ),
              ],
              if (_needsFundedDispatch(report)) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _sendFunded,
                    child: Text(
                      _busy
                          ? 'Sending...'
                          : 'Send budget to worker & public',
                    ),
                  ),
                ),
              ] else if (report.isFundedBudgetSent) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: null,
                    child: const Text('Done · budget sent'),
                  ),
                ),
              ],
              if (_needsCompletionDispatch(report)) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _sendCompletion,
                    child: Text(
                      _busy
                          ? 'Sending...'
                          : 'Send completed photos to public',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
    );
  }
}

class _OfficialBudgets extends StatelessWidget {
  const _OfficialBudgets();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BudgetRequest>>(
      stream: BudgetService().watchBudgetRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(AuthMessages.from(snapshot.error!)));
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: HamroFixTheme.mediumGreen),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const _EmptyHint(
            icon: Icons.payments_outlined,
            text: 'No budget requests yet.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              _OfficialBudgetCard(item: items[index]),
        );
      },
    );
  }
}

class _OfficialBudgetCard extends StatefulWidget {
  const _OfficialBudgetCard({required this.item});

  final BudgetRequest item;

  @override
  State<_OfficialBudgetCard> createState() => _OfficialBudgetCardState();
}

class _OfficialBudgetCardState extends State<_OfficialBudgetCard> {
  bool _busy = false;

  Future<void> _forward() async {
    setState(() => _busy = true);
    try {
      await BudgetService().forwardToAdmin(widget.item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget forwarded to admin.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendFunded() async {
    setState(() => _busy = true);
    try {
      final report = await ReportService().fetchReport(widget.item.reportId);
      if (report == null) {
        throw const AuthReportFailure('Related report was not found.');
      }
      await TaskService().assignFundedTask(
        report: report,
        workerId: report.inspectorIds.isEmpty ? '' : report.inspectorIds.first,
        workerIds: report.inspectorIds,
        instructions:
            'Complete funded work for ${report.publicId}. Approved budget NPR ${report.approvedBudgetAmount?.toStringAsFixed(0) ?? widget.item.estimatedTotal.toStringAsFixed(0)}.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Approved budget sent to the worker and the public reporter.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final actionable = _canForwardBudget(item);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFEDE7F6),
                  child: Icon(Icons.payments_rounded, color: Color(0xFF6A1B9A)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NPR ${item.estimatedTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        item.reportId.isEmpty
                            ? 'Civic budget request'
                            : 'Report ${item.reportId}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: item.status),
              ],
            ),
            if (item.remarks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(item.remarks),
            ],
            if (item.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final line in item.items)
                Text(
                  '${line['name'] ?? 'Item'} × ${line['quantity'] ?? 1} @ NPR ${line['unitCost'] ?? 0}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
            ],
            if (item.items.isNotEmpty || item.itemsSubtotal > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Budget NPR ${(item.itemsSubtotal > 0 ? item.itemsSubtotal : WorkerPay.itemsTotal(item.items)).toStringAsFixed(0)} · worker salary NPR ${WorkerPay.salaryOf(item.itemsSubtotal > 0 ? item.itemsSubtotal : WorkerPay.itemsTotal(item.items)).toStringAsFixed(0)} (15%)',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BudgetDetailsPage(request: item),
                    ),
                  );
                },
                child: const Text('View details'),
              ),
            ),
            if (actionable) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _forward,
                  child: Text(_busy ? 'Sending...' : 'Forward to admin'),
                ),
              ),
            ],
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: ReportService().watchReport(item.reportId),
              builder: (context, snap) {
                ReportIssue? linked;
                final doc = snap.data;
                if (doc != null && doc.exists) {
                  linked = ReportIssue.fromFirestore(doc);
                }
                final sent = item.status == BudgetStatus.sentToWorker ||
                    (linked?.isFundedBudgetSent ?? false);
                final canSend =
                    item.status == BudgetStatus.finalApproved && !sent;
                if (!canSend && !sent) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: sent || _busy ? null : _sendFunded,
                        child: Text(
                          _busy
                              ? 'Sending...'
                              : sent
                              ? 'Done · budget sent'
                              : 'Send to worker & public',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTab extends StatelessWidget {
  const _MoreTab({
    required this.profile,
    required this.unreadCount,
    required this.unreadBudgets,
    required this.unreadNotifications,
    required this.unreadMessages,
  });

  final UserProfile profile;
  final int unreadCount;
  final int unreadBudgets;
  final int unreadNotifications;
  final int unreadMessages;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _MoreTile(
          icon: Icons.payments_rounded,
          color: const Color(0xFF6A1B9A),
          title: 'Budgets',
          subtitle: 'Review worker estimates and forward to admin',
          badge: unreadBudgets,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => WebPageScaffold(
                  title: 'Budgets',
                  maxWidth: 720,
                  body: _OfficialBudgets(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _MoreTile(
          icon: Icons.notifications_rounded,
          color: const Color(0xFFE65100),
          title: 'Notifications',
          subtitle: unreadNotifications == 0
              ? 'Report and budget updates'
              : '$unreadNotifications unread notification${unreadNotifications == 1 ? '' : 's'}',
          badge: unreadNotifications,
          onTap: () => openNotificationsPage(context, profile),
        ),
        const SizedBox(height: 10),
        _MoreTile(
          icon: Icons.mail_rounded,
          color: const Color(0xFF1565C0),
          title: 'Messages',
          subtitle: 'From workers and admin',
          badge: unreadMessages,
          onTap: () => openStaffMessagesPage(context, profile),
        ),
        const SizedBox(height: 10),
        _MoreTile(
          icon: Icons.send_rounded,
          color: HamroFixTheme.mediumGreen,
          title: 'Send alert',
          subtitle: 'Write an extra note to a worker or admin',
          onTap: () => openSendAlertPage(context, profile),
        ),
        const SizedBox(height: 10),
        _MoreTile(
          icon: Icons.person_rounded,
          color: HamroFixTheme.mediumGreen,
          title: 'Profile',
          subtitle: 'Name, phone, and password',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => WebPageScaffold(
                  title: 'Profile',
                  maxWidth: 640,
                  body: ProfileTab(profile: profile),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final value = _pretty(status);
    final color = switch (status) {
      'pending' ||
      'official_review' ||
      'submitted' ||
      'submitted_to_official' => const Color(0xFFE65100),
      'approved' ||
      'official_accepted' ||
      'completed' ||
      'available' ||
      'final_approved' => HamroFixTheme.mediumGreen,
      'rejected' ||
      'official_declined' ||
      'verified_fake' ||
      'blacklisted' ||
      'removed' => const Color(0xFFB71C1C),
      _ => const Color(0xFF1565C0),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value.isEmpty ? 'unknown' : value,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WorkerApprovalList extends StatefulWidget {
  const _WorkerApprovalList({required this.profile});

  final UserProfile profile;

  @override
  State<_WorkerApprovalList> createState() => _WorkerApprovalListState();
}

class _WorkerApprovalListState extends State<_WorkerApprovalList> {
  String _filter = 'pending';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WorkerApplication>>(
      stream: AuthServices().watchWorkerApplications(),
      builder: (context, appsSnap) {
        return StreamBuilder<List<UserProfile>>(
          stream: AuthServices().watchUsers(),
          builder: (context, usersSnap) {
            return StreamBuilder<List<ReportIssue>>(
              stream: ReportService().watchAllReports(),
              builder: (context, reportsSnap) {
                if (appsSnap.hasError) {
                  return Center(child: Text(AuthMessages.from(appsSnap.error!)));
                }
                if (usersSnap.hasError) {
                  return Center(
                    child: Text(AuthMessages.from(usersSnap.error!)),
                  );
                }
                if (reportsSnap.hasError) {
                  return Center(
                    child: Text(AuthMessages.from(reportsSnap.error!)),
                  );
                }
                if ((appsSnap.connectionState == ConnectionState.waiting &&
                        !appsSnap.hasData) ||
                    !usersSnap.hasData ||
                    !reportsSnap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: HamroFixTheme.mediumGreen,
                    ),
                  );
                }
                final apps = List<WorkerApplication>.from(
                  appsSnap.data ?? const <WorkerApplication>[],
                );
                apps.sort((a, b) {
                  if (a.status == AccountStatus.pending &&
                      b.status != AccountStatus.pending) {
                    return -1;
                  }
                  if (b.status == AccountStatus.pending &&
                      a.status != AccountStatus.pending) {
                    return 1;
                  }
                  return 0;
                });
                final openJobs = (reportsSnap.data ?? [])
                    .where(_isBusyJob)
                    .toList();
                final busyIds = <String>{};
                for (final report in openJobs) {
                  busyIds.addAll(report.crewIds);
                }
                final approvedWorkers = (usersSnap.data ?? [])
                    .where(
                      (user) =>
                          user.hasRole(UserRole.worker) &&
                          user.isApproved &&
                          !user.isRestricted,
                    )
                    .toList();
                final freeWorkers = approvedWorkers
                    .where((user) => !busyIds.contains(user.uid))
                    .toList();
                final busyWorkers = approvedWorkers
                    .where((user) => busyIds.contains(user.uid))
                    .toList();
                final waiting = apps
                    .where((item) => item.status == AccountStatus.pending)
                    .toList();

                return Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        children: [
                          for (final entry in [
                            ('pending', 'Waiting'),
                            ('approved', 'Active'),
                            ('busy', 'In task'),
                            ('all', 'All'),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(entry.$2),
                                selected: _filter == entry.$1,
                                onSelected: (_) =>
                                    setState(() => _filter = entry.$1),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(child: _workerListBody(
                      waiting: waiting,
                      freeWorkers: freeWorkers,
                      busyWorkers: busyWorkers,
                      openJobs: openJobs,
                      apps: apps,
                    )),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _workerListBody({
    required List<WorkerApplication> waiting,
    required List<UserProfile> freeWorkers,
    required List<UserProfile> busyWorkers,
    required List<ReportIssue> openJobs,
    required List<WorkerApplication> apps,
  }) {
    if (_filter == 'pending') {
      if (waiting.isEmpty) {
        return const _EmptyHint(
          icon: Icons.engineering_outlined,
          text: 'No worker applications waiting.',
        );
      }
      return _applicationList(waiting);
    }
    if (_filter == 'approved') {
      if (freeWorkers.isEmpty) {
        return const _EmptyHint(
          icon: Icons.person_off_outlined,
          text: 'No free workers. Assigned workers are under In task.',
        );
      }
      return _workerCards(freeWorkers, openJobs);
    }
    if (_filter == 'busy') {
      if (busyWorkers.isEmpty) {
        return const _EmptyHint(
          icon: Icons.handyman_outlined,
          text: 'No workers are assigned to an open task.',
        );
      }
      return _workerCards(busyWorkers, openJobs);
    }
    if (apps.isEmpty) {
      return const _EmptyHint(
        icon: Icons.engineering_outlined,
        text: 'No workers in this view.',
      );
    }
    return _applicationList(apps);
  }

  Widget _applicationList(List<WorkerApplication> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _WorkerAppCard(application: items[index]),
    );
  }

  Widget _workerCards(List<UserProfile> workers, List<ReportIssue> openJobs) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: workers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final worker = workers[index];
        final jobs = openJobs
            .where((item) => item.isAssignedTo(worker.uid))
            .toList();
        return _BusyWorkerCard(
          worker: worker,
          jobs: jobs,
          official: widget.profile,
        );
      },
    );
  }
}

class _BusyWorkerCard extends StatelessWidget {
  const _BusyWorkerCard({
    required this.worker,
    required this.jobs,
    required this.official,
  });

  final UserProfile worker;
  final List<ReportIssue> jobs;
  final UserProfile official;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: StoredImage.provider(worker.profileImageUrl),
                child: StoredImage.provider(worker.profileImageUrl) == null
                    ? Text(worker.name.isEmpty ? '?' : worker.name[0])
                    : null,
              ),
              title: Text(
                worker.displayName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                [
                  if (worker.specialtyLabel.isNotEmpty) worker.specialtyLabel,
                  jobs.isEmpty
                      ? 'Available · not assigned to any task'
                      : '${jobs.length} open task${jobs.length == 1 ? '' : 's'}',
                ].join('\n'),
              ),
              isThreeLine: true,
              trailing: _StatusChip(
                status: jobs.isEmpty ? 'available' : 'in_task',
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (context) => _BusyWorkerDetailsSheet(
                      worker: worker,
                      jobs: jobs,
                      official: official,
                    ),
                  );
                },
                child: const Text('View details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusyWorkerDetailsSheet extends StatelessWidget {
  const _BusyWorkerDetailsSheet({
    required this.worker,
    required this.jobs,
    required this.official,
  });

  final UserProfile worker;
  final List<ReportIssue> jobs;
  final UserProfile official;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            worker.displayName,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          if ((worker.phone).isNotEmpty) Text(worker.phone),
          if ((worker.specialization ?? '').isNotEmpty)
            Text(worker.specialization!),
          const SizedBox(height: 16),
          Text(
            jobs.isEmpty ? 'Current tasks' : 'Open tasks',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (jobs.isEmpty)
            const Text('This worker is available and not assigned to any task.')
          else
            for (final job in jobs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(job.publicId),
              subtitle: Text(
                '${job.category} · ${_pretty(job.status)}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ReportDetailsPage(report: job, profile: official),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _WorkerAppCard extends StatefulWidget {
  const _WorkerAppCard({required this.application});

  final WorkerApplication application;

  @override
  State<_WorkerAppCard> createState() => _WorkerAppCardState();
}

class _WorkerAppCardState extends State<_WorkerAppCard> {
  bool _busy = false;

  Future<void> _invite() {
    final app = widget.application;
    return showStaffLoginInvite(
      context: context,
      name: app.name,
      email: app.email,
      roleLabel: 'worker',
      temporaryPassword: app.temporaryPassword,
    );
  }

  Future<void> _reasonAction({
    required String title,
    required String hint,
    required String confirmLabel,
    required Future<void> Function(String reason) onConfirm,
    required String done,
    bool destructive = false,
  }) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    String? reason;
    try {
      reason = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 4,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final ready = controller.text.trim().length >= 8;
                Future<void> close([String? value]) async {
                  focusNode.unfocus();
                  FocusManager.instance.primaryFocus?.unfocus();
                  await Future<void>.delayed(const Duration(milliseconds: 120));
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext, value);
                  }
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setSheetState(() {}),
                      onEditingComplete: ready
                          ? () => close(controller.text.trim())
                          : null,
                      decoration: InputDecoration(
                        hintText: hint,
                        alignLabelWithHint: true,
                        labelText: 'Valid reason',
                        helperText: 'At least 8 characters',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => close(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            style: destructive
                                ? FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFB71C1C),
                                    foregroundColor: Colors.white,
                                  )
                                : null,
                            onPressed: ready
                                ? () => close(controller.text.trim())
                                : null,
                            child: Text(confirmLabel),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    } finally {
      focusNode.dispose();
      controller.dispose();
    }
    if (reason == null || reason.length < 8) {
      return;
    }
    setState(() => _busy = true);
    try {
      await onConfirm(reason);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(done)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    final pending = app.status == AccountStatus.pending;
    final restricted =
        app.status == AccountStatus.blacklisted || app.status == 'removed';
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: StoredImage.provider(app.profileImageUrl),
                child: StoredImage.provider(app.profileImageUrl) == null
                    ? Text(app.name.isEmpty ? '?' : app.name[0])
                    : null,
              ),
              title: Text(
                app.displayName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                [
                  if (app.specialtyLabel.isNotEmpty) app.specialtyLabel,
                  if (app.municipality != null && app.municipality!.isNotEmpty)
                    app.municipality!,
                  if (app.phone.isNotEmpty) app.phone,
                ].join('\n'),
              ),
              isThreeLine: true,
              trailing: _StatusChip(status: app.status),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => showWorkerApplicationReview(
                  context: context,
                  application: app,
                ),
                child: const Text('View all details & photos'),
              ),
            ),
            const SizedBox(height: 8),
            if (pending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              setState(() => _busy = true);
                              try {
                                await AuthServices().rejectWorkerApplication(
                                  app,
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AuthMessages.from(e)),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _busy = false);
                              }
                            },
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              setState(() => _busy = true);
                              try {
                                await AuthServices().approveWorkerApplication(
                                  app,
                                );
                                if (context.mounted) await _invite();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AuthMessages.from(e)),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _busy = false);
                              }
                            },
                      child: Text(_busy ? 'Working...' : 'Approve'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy ? null : _invite,
                child: const Text('Send email & password'),
              ),
            ),
            if (!pending &&
                !restricted &&
                app.status != AccountStatus.rejected) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _reasonAction(
                              title: 'Blacklist worker',
                              hint: 'Why is this worker being blacklisted?',
                              confirmLabel: 'Blacklist',
                              destructive: true,
                              onConfirm: (reason) =>
                                  AuthServices().blacklistWorker(
                                    application: app,
                                    reason: reason,
                                  ),
                              done: 'Worker blacklisted.',
                            ),
                      child: const Text('Blacklist'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _reasonAction(
                              title: 'Delete worker profile',
                              hint: 'Why is this worker profile being deleted?',
                              confirmLabel: 'Delete profile',
                              destructive: true,
                              onConfirm: (reason) =>
                                  AuthServices().deleteWorkerProfile(
                                    application: app,
                                    reason: reason,
                                  ),
                              done: 'Worker profile deleted.',
                            ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _needsOfficialReview(ReportIssue report) {
  return report.status == ReportStatus.submitted ||
      report.status == ReportStatus.officialReview ||
      report.status == ReportStatus.officialFinalReview;
}

bool _needsAssignment(ReportIssue report) {
  if (report.crewIds.isNotEmpty) return _isBusyJob(report);
  return report.status == ReportStatus.officialAccepted ||
      report.status == ReportStatus.verifiedValid ||
      report.status == ReportStatus.workerAssigned ||
      report.status == ReportStatus.workerInspection;
}

bool _needsFundedDispatch(ReportIssue report) {
  return report.status == ReportStatus.budgetApproved;
}

bool _needsCompletionDispatch(ReportIssue report) {
  return report.awaitingOfficialCompletion;
}

bool _isBusyJob(ReportIssue report) {
  if (report.crewIds.isEmpty) return false;
  return report.status != ReportStatus.workCompleted &&
      report.status != ReportStatus.completed &&
      report.status != ReportStatus.publicFeed &&
      report.status != ReportStatus.verifiedFake &&
      report.status != ReportStatus.officialDeclined;
}

bool _canForwardBudget(BudgetRequest item) {
  return item.status == BudgetStatus.submittedToOfficial ||
      item.status == BudgetStatus.draft;
}

String _pretty(String status) => status.replaceAll('_', ' ');
