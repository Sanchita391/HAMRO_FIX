import 'package:flutter/material.dart';

import 'package:hamro_fix/core/constants/app_constants.dart';
import 'package:hamro_fix/core/l10n/app_locale.dart';
import 'package:hamro_fix/core/theme/app_theme.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/screens/dashboards/dashboard_widgets.dart';
import 'package:hamro_fix/screens/dashboards/shared_tabs.dart';
import 'package:hamro_fix/screens/reports/budget_details_page.dart';
import 'package:hamro_fix/screens/reports/report_details_page.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/auth_services.dart';
import 'package:hamro_fix/services/budget_service.dart';
import 'package:hamro_fix/services/notification_service.dart';
import 'package:hamro_fix/services/report_service.dart';
import 'package:hamro_fix/widgets/application_review.dart';
import 'package:hamro_fix/widgets/login_invite_sheet.dart';
import 'package:hamro_fix/widgets/stored_image.dart';
import 'package:hamro_fix/widgets/worker_payment.dart';

void openAdminBudgets(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        backgroundColor: HamroFixTheme.canvas,
        appBar: AppBar(title: const Text('Budgets')),
        body: const _AdminBudgets(),
      ),
    ),
  );
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final loc = LocaleScope.of(context);
    final unread = NotificationService().watchMine(widget.profile.uid);
    return StreamBuilder<List<AppNotification>>(
      stream: unread,
      builder: (context, alertSnap) {
        final unreadCount = (alertSnap.data ?? [])
            .where((item) => !item.read)
            .length;
        return Scaffold(
          backgroundColor: HamroFixTheme.canvas,
          appBar: AppBar(
            backgroundColor: HamroFixTheme.canvas,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            titleSpacing: 16,
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
              _OverviewTab(
                profile: widget.profile,
                onOpen: (page) => setState(() => _index = page),
              ),
              _UsersManager(admin: widget.profile),
              _AccessRequestsTab(admin: widget.profile),
              _AdminReports(profile: widget.profile),
              _MoreTab(profile: widget.profile, unreadCount: unreadCount),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            indicatorColor: const Color(0xFFC8E6C9),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard_rounded),
                label: loc.t('Home', 'गृह'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.groups_outlined),
                selectedIcon: const Icon(Icons.groups_rounded),
                label: loc.t('People', 'प्रयोगकर्ता'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.verified_user_outlined),
                selectedIcon: const Icon(Icons.verified_user_rounded),
                label: loc.t('Approvals', 'स्वीकृति'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.report_outlined),
                selectedIcon: const Icon(Icons.report_rounded),
                label: loc.t('Reports', 'रिपोर्ट'),
              ),
              NavigationDestination(
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
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.profile, required this.onOpen});

  final UserProfile profile;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProfile>>(
      stream: AuthServices().watchUsers(),
      builder: (context, usersSnap) {
        return StreamBuilder<List<AccessRequest>>(
          stream: AuthServices().watchOfficialApplications(),
          builder: (context, officialSnap) {
            return StreamBuilder<List<ReportIssue>>(
              stream: ReportService().watchAllReports(),
              builder: (context, reportsSnap) {
                return StreamBuilder<List<BudgetRequest>>(
                  stream: BudgetService().watchBudgetRequests(),
                  builder: (context, budgetSnap) {
                    final users = usersSnap.data ?? [];
                    final officials = officialSnap.data ?? [];
                    final reports = reportsSnap.data ?? [];
                    final budgets = budgetSnap.data ?? [];
                    final pendingOfficials = officials
                        .where((item) => item.status == 'pending')
                        .toList();
                    final pendingBudgets = budgets
                        .where(_isBudgetActionable)
                        .toList();
                    final openReports = reports
                        .where(
                          (item) =>
                              item.status != ReportStatus.completed &&
                              item.status != ReportStatus.verifiedFake,
                        )
                        .toList();

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _HeroBanner(name: profile.name),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'People',
                                value: '${users.length}',
                                icon: Icons.groups_rounded,
                                color: HamroFixTheme.mediumGreen,
                                onTap: () => onOpen(1),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                label: 'Approvals',
                                value: '${pendingOfficials.length}',
                                icon: Icons.how_to_reg_rounded,
                                color: const Color(0xFFE65100),
                                onTap: () => onOpen(2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Open reports',
                                value: '${openReports.length}',
                                icon: Icons.assignment_rounded,
                                color: const Color(0xFF1565C0),
                                onTap: () => onOpen(3),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                label: 'Budgets',
                                value: '${pendingBudgets.length}',
                                icon: Icons.payments_rounded,
                                color: const Color(0xFF6A1B9A),
                                onTap: () => openAdminBudgets(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _HomeAction(
                          icon: Icons.how_to_reg_rounded,
                          color: const Color(0xFFE65100),
                          title: 'Approvals',
                          subtitle: pendingOfficials.isEmpty
                              ? 'No applications waiting'
                              : '${pendingOfficials.length} official application${pendingOfficials.length == 1 ? '' : 's'} to review',
                          onTap: () => onOpen(2),
                        ),
                        const SizedBox(height: 10),
                        _HomeAction(
                          icon: Icons.payments_rounded,
                          color: const Color(0xFF6A1B9A),
                          title: 'Budgets',
                          subtitle: pendingBudgets.isEmpty
                              ? 'No budget decisions waiting'
                              : '${pendingBudgets.length} request${pendingBudgets.length == 1 ? '' : 's'} need a decision',
                          onTap: () => openAdminBudgets(context),
                        ),
                        const SizedBox(height: 10),
                        _HomeAction(
                          icon: Icons.assignment_rounded,
                          color: const Color(0xFF1565C0),
                          title: 'Reports',
                          subtitle: openReports.isEmpty
                              ? 'No open reports'
                              : '${openReports.length} open · search and open from Reports',
                          onTap: () => onOpen(3),
                        ),
                        const SizedBox(height: 10),
                        _HomeAction(
                          icon: Icons.groups_rounded,
                          color: HamroFixTheme.mediumGreen,
                          title: 'People',
                          subtitle: '${users.length} accounts · search by name or role',
                          onTap: () => onOpen(1),
                        ),
                      ],
                    );
                  },
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
    final greetingName = name.trim().isEmpty ? 'Administrator' : name.trim();
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
                Text(
                  greetingName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
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

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
        trailing: const Icon(Icons.chevron_right_rounded),
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

class _UsersManager extends StatefulWidget {
  const _UsersManager({required this.admin});

  final UserProfile admin;

  @override
  State<_UsersManager> createState() => _UsersManagerState();
}

class _UsersManagerState extends State<_UsersManager> {
  String _query = '';
  String _role = 'all';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProfile>>(
      stream: AuthServices().watchUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: HamroFixTheme.mediumGreen),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text(AuthMessages.from(snapshot.error!)));
        }
        var users = [...(snapshot.data ?? [])];
        users.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        if (_role != 'all') {
          users = users.where((user) => user.normalizedRole == _role).toList();
        }
        if (_query.trim().isNotEmpty) {
          final q = _query.trim().toLowerCase();
          users = users
              .where(
                (user) =>
                    user.name.toLowerCase().contains(q) ||
                    user.email.toLowerCase().contains(q) ||
                    user.phone.toLowerCase().contains(q),
              )
              .toList();
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search name, email, or phone',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  for (final entry in [
                    ('all', 'All'),
                    (UserRole.public, 'Public'),
                    (UserRole.worker, 'Workers'),
                    (UserRole.official, 'Officials'),
                    (UserRole.admin, 'Admins'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.$2),
                        selected: _role == entry.$1,
                        onSelected: (_) => setState(() => _role = entry.$1),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: users.isEmpty
                  ? const _EmptyHint(
                      icon: Icons.person_search_outlined,
                      text: 'No people match that filter.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _UserCard(user: user, admin: widget.admin);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.admin});

  final UserProfile user;
  final UserProfile admin;

  @override
  Widget build(BuildContext context) {
    final role = user.normalizedRole ?? 'unknown';
    final isSelf = user.uid == admin.uid;
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
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFC8E6C9),
                  backgroundImage: StoredImage.provider(user.profileImageUrl),
                  child: StoredImage.provider(user.profileImageUrl) == null
                      ? Text(
                          user.displayName.characters.first.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (!user.hideContactEmail)
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      if (user.hideContactEmail &&
                          (user.municipality ?? '').isNotEmpty)
                        Text(
                          user.municipality!,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                _StatusChip(status: user.status),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _MetaChip(icon: Icons.badge_outlined, label: _prettyRole(role)),
                if (user.phone.isNotEmpty)
                  _MetaChip(icon: Icons.phone_outlined, label: user.phone),
                if (user.municipality != null && user.municipality!.isNotEmpty)
                  _MetaChip(
                    icon: Icons.location_city_outlined,
                    label: user.municipality!,
                  ),
              ],
            ),
            if (!isSelf && role != UserRole.admin) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Role', style: TextStyle(color: Colors.black54)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: UserRole.isKnown(user.role)
                          ? user.normalizedRole
                          : null,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final value in [
                          UserRole.public,
                          UserRole.worker,
                          UserRole.official,
                        ])
                          DropdownMenuItem(
                            value: value,
                            child: Text(_prettyRole(value)),
                          ),
                      ],
                      onChanged: (roleValue) async {
                        if (roleValue == null ||
                            roleValue == user.normalizedRole) {
                          return;
                        }
                        final ok = await _confirm(
                          context,
                          title: 'Change role?',
                          message:
                              'Assign ${_prettyRole(roleValue)} to ${user.displayName}?',
                        );
                        if (ok != true) return;
                        try {
                          await AuthServices().setUserRole(
                            uid: user.uid,
                            role: roleValue,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Role updated.')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AuthMessages.from(e))),
                            );
                          }
                        }
                      },
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

class _AccessRequestsTab extends StatelessWidget {
  const _AccessRequestsTab({required this.admin});

  final UserProfile admin;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AccessRequest>>(
      stream: AuthServices().watchOfficialApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: HamroFixTheme.mediumGreen),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text(AuthMessages.from(snapshot.error!)));
        }
        final requests = [...(snapshot.data ?? [])];
        requests.sort((a, b) {
          if (a.status == 'pending' && b.status != 'pending') return -1;
          if (b.status == 'pending' && a.status != 'pending') return 1;
          return (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          );
        });
        if (requests.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: _EmptyHint(
              icon: Icons.how_to_reg_outlined,
              text: 'No official access requests yet.',
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _OfficialCard(request: requests[index]);
          },
        );
      },
    );
  }
}

class _OfficialCard extends StatefulWidget {
  const _OfficialCard({required this.request});

  final AccessRequest request;

  @override
  State<_OfficialCard> createState() => _OfficialCardState();
}

class _OfficialCardState extends State<_OfficialCard> {
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

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final pending = request.status == 'pending';
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
                GestureDetector(
                  onTap: () => showOfficialApplicationReview(
                    context: context,
                    request: request,
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFC8E6C9),
                    backgroundImage: StoredImage.provider(
                      request.profileImageUrl,
                    ),
                    child: StoredImage.provider(request.profileImageUrl) == null
                        ? Text(
                            request.name.isEmpty
                                ? '?'
                                : request.name.characters.first.toUpperCase(),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        request.email,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: request.status),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (request.employeeId.isNotEmpty)
                  _MetaChip(
                    icon: Icons.badge_outlined,
                    label: 'ID ${request.employeeId}',
                  ),
                if ((request.department ?? '').isNotEmpty)
                  _MetaChip(
                    icon: Icons.apartment_outlined,
                    label: request.department!,
                  ),
                if ((request.municipality ?? '').isNotEmpty)
                  _MetaChip(
                    icon: Icons.location_city_outlined,
                    label: request.municipality!,
                  ),
                if ((request.phone ?? '').isNotEmpty)
                  _MetaChip(icon: Icons.phone_outlined, label: request.phone!),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showOfficialApplicationReview(
                  context: context,
                  request: request,
                ),
                icon: const Icon(Icons.badge_outlined),
                label: const Text('View all details & photo'),
              ),
            ),
            if (pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              final ok = await _confirm(
                                context,
                                title: 'Reject application?',
                                message:
                                    '${request.name} will not get official access.',
                              );
                              if (ok == true) {
                                await _run(
                                  () => AuthServices().rejectOfficialRequest(
                                    request,
                                  ),
                                  'Application rejected.',
                                );
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
                              final ok = await _confirm(
                                context,
                                title: 'Approve official?',
                                message:
                                    'Approve ${request.name}, then send their email and password from this card.',
                              );
                              if (ok == true) {
                                await _run(
                                  () => AuthServices().approveOfficialRequest(
                                    request,
                                  ),
                                  'Official approved. Send login details next.',
                                );
                                if (context.mounted) {
                                  await _showOfficialCredentials(
                                    context,
                                    request,
                                  );
                                }
                              }
                            },
                      child: Text(_busy ? 'Working...' : 'Approve'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _showOfficialCredentials(context, request),
                icon: const Icon(Icons.mark_email_read_outlined),
                label: const Text('Send email & password'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOfficialCredentials(
    BuildContext context,
    AccessRequest request,
  ) {
    return showStaffLoginInvite(
      context: context,
      name: request.name,
      email: request.email,
      roleLabel: 'official',
      temporaryPassword: request.temporaryPassword,
      extraLine: request.employeeId.isEmpty
          ? null
          : 'Employee ID (optional): ${request.employeeId}',
    );
  }
}

class _AdminReports extends StatefulWidget {
  const _AdminReports({required this.profile});

  final UserProfile profile;

  @override
  State<_AdminReports> createState() => _AdminReportsState();
}

class _AdminReportsState extends State<_AdminReports> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReportIssue>>(
      stream: ReportService().watchAllReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: HamroFixTheme.mediumGreen),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text(AuthMessages.from(snapshot.error!)));
        }
        var reports = [...(snapshot.data ?? [])];
        reports.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
        if (_query.trim().isNotEmpty) {
          final q = _query.trim().toLowerCase();
          reports = reports
              .where(
                (item) =>
                    item.title.toLowerCase().contains(q) ||
                    item.category.toLowerCase().contains(q) ||
                    item.status.toLowerCase().contains(q) ||
                    (item.municipality ?? '').toLowerCase().contains(q),
              )
              .toList();
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search title, category, area, or status',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: reports.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: _EmptyHint(
                        icon: Icons.assignment_outlined,
                        text: 'No reports match that search.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: reports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _ReportTile(
                          report: reports[index],
                          profile: widget.profile,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report, required this.profile});

  final ReportIssue report;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  ReportDetailsPage(report: report, profile: profile),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: report.imageUrl == null
                      ? Container(
                          color: const Color(0xFFE8F5E9),
                          child: const Icon(
                            Icons.photo_outlined,
                            color: HamroFixTheme.mediumGreen,
                          ),
                        )
                      : Image(
                          image: StoredImage.provider(report.imageUrl)!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        report.category,
                        if ((report.municipality ?? '').isNotEmpty)
                          report.municipality!,
                      ].join(' · '),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusChip(status: report.status),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminBudgets extends StatelessWidget {
  const _AdminBudgets();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BudgetRequest>>(
      stream: BudgetService().watchBudgetRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: HamroFixTheme.mediumGreen),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: _EmptyHint(
              icon: Icons.payments_outlined,
              text: 'No budget requests yet.',
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _BudgetCard(item: items[index]),
        );
      },
    );
  }
}

class _BudgetCard extends StatefulWidget {
  const _BudgetCard({required this.item});

  final BudgetRequest item;

  @override
  State<_BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<_BudgetCard> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    final ok = await _confirm(
      context,
      title: approve ? 'Approve budget?' : 'Reject budget?',
      message:
          'NPR ${widget.item.estimatedTotal.toStringAsFixed(0)} for report ${widget.item.reportId}.',
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await BudgetService().adminDecide(
        request: widget.item,
        approve: approve,
        remarks: approve ? 'Approved by admin' : 'Rejected by admin',
        report: null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Budget approved.' : 'Budget rejected.'),
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
    final actionable = _isBudgetActionable(item);
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
            if (actionable) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            BudgetDetailsPage(request: item, allowDecide: true),
                      ),
                    );
                  },
                  child: const Text('View details'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _decide(false),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : () => _decide(true),
                      child: Text(_busy ? 'Working...' : 'Approve'),
                    ),
                  ),
                ],
              ),
            ] else ...[
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
            ],
          ],
        ),
      ),
    );
  }
}

class _MoreTab extends StatelessWidget {
  const _MoreTab({required this.profile, required this.unreadCount});

  final UserProfile profile;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _MoreTile(
          icon: Icons.payments_rounded,
          color: const Color(0xFF6A1B9A),
          title: 'Budgets',
          subtitle: 'Approve or reject civic budget requests',
          onTap: () => openAdminBudgets(context),
        ),
        const SizedBox(height: 10),
        _MoreTile(
          icon: Icons.notifications_rounded,
          color: const Color(0xFFE65100),
          title: 'Alerts',
          subtitle: unreadCount == 0
              ? 'No unread alerts'
              : '$unreadCount unread alert${unreadCount == 1 ? '' : 's'}',
          badge: unreadCount,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  backgroundColor: HamroFixTheme.canvas,
                  appBar: AppBar(title: const Text('Alerts')),
                  body: NotificationsTab(uid: profile.uid),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _MoreTile(
          icon: Icons.person_rounded,
          color: HamroFixTheme.mediumGreen,
          title: 'Profile',
          subtitle: 'Name, username, and password',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  backgroundColor: HamroFixTheme.canvas,
                  appBar: AppBar(title: const Text('Profile')),
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
    final value = status.replaceAll('_', ' ');
    final color = switch (status) {
      'pending' ||
      'admin_review' ||
      'forwarded_to_admin' ||
      'submitted_to_official' => const Color(0xFFE65100),
      'approved' ||
      'active' ||
      'completed' ||
      'final_approved' => HamroFixTheme.mediumGreen,
      'rejected' || 'verified_fake' || 'blacklisted' => const Color(0xFFB71C1C),
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: HamroFixTheme.mediumGreen),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

String _prettyRole(String role) {
  return switch (role) {
    UserRole.public => 'Public',
    UserRole.worker => 'Worker',
    UserRole.official => 'Official',
    UserRole.admin => 'Admin',
    _ => role,
  };
}

bool _isBudgetActionable(BudgetRequest item) {
  return item.status == BudgetStatus.forwardedToAdmin ||
      item.status == BudgetStatus.adminReview ||
      item.status == BudgetStatus.submittedToOfficial;
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}
