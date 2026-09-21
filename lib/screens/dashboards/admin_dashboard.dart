import 'package:flutter/material.dart';

import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/screens/dashboards/dashboard_widgets.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/auth_services.dart';
import 'package:hamro_fix/services/report_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Admin Dashboard',
      profile: profile,
      tabs: [
        const DashboardTab(label: 'Users', child: _UsersManager()),
        const DashboardTab(label: 'Officials', child: _AccessRequestsTab()),
        DashboardTab(
          label: 'Reports',
          child: ReportList(stream: ReportService().watchAllReports()),
        ),
        DashboardTab(label: 'Profile', child: ProfileTab(profile: profile)),
      ],
    );
  }
}

class _UsersManager extends StatelessWidget {
  const _UsersManager();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserProfile>>(
      future: AuthServices().listUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(AuthMessages.from(snapshot.error!)));
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text('No users found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              child: ListTile(
                title: Text(user.name.isEmpty ? user.email : user.name),
                subtitle: Text(
                  '${user.email}\nRole: ${user.normalizedRole ?? 'none'}',
                ),
                isThreeLine: true,
                trailing: DropdownButton<String>(
                  value: UserRole.isKnown(user.role)
                      ? user.normalizedRole
                      : null,
                  hint: const Text('Role'),
                  items: [
                    for (final role in UserRole.all)
                      DropdownMenuItem(value: role, child: Text(role)),
                  ],
                  onChanged: (role) async {
                    if (role == null) return;
                    await AuthServices().setUserRole(uid: user.uid, role: role);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AccessRequestsTab extends StatelessWidget {
  const _AccessRequestsTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AccessRequest>>(
      future: AuthServices().listAccessRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(AuthMessages.from(snapshot.error!)));
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(child: Text('No official access requests.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
              child: ListTile(
                title: Text(request.name),
                subtitle: Text(
                  '${request.email}\nID: ${request.employeeId}\n${request.status}',
                ),
                isThreeLine: true,
                trailing: request.status == 'pending'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () async {
                              try {
                                await AuthServices()
                                    .approveOfficialRequest(request);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(AuthMessages.from(e))),
                                  );
                                }
                              }
                            },
                            child: const Text('Approve'),
                          ),
                          TextButton(
                            onPressed: () => AuthServices()
                                .rejectOfficialRequest(request),
                            child: const Text('Reject'),
                          ),
                        ],
                      )
                    : Text(request.status),
              ),
            );
          },
        );
      },
    );
  }
}
