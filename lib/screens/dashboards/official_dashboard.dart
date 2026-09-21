import 'package:flutter/material.dart';

import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/screens/dashboards/dashboard_widgets.dart';
import 'package:hamro_fix/services/auth_services.dart';
import 'package:hamro_fix/services/report_service.dart';

class OfficialDashboard extends StatelessWidget {
  const OfficialDashboard({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final reports = ReportService();
    return FutureBuilder<List<UserProfile>>(
      future: AuthServices().listUsers(),
      builder: (context, snapshot) {
        final workers = (snapshot.data ?? [])
            .where((user) => user.normalizedRole == UserRole.worker)
            .toList();
        return DashboardShell(
          title: 'Official Dashboard',
          profile: profile,
          tabs: [
            DashboardTab(
              label: 'Reports',
              child: ReportList(
                stream: reports.watchAllReports(),
                onAccept: (report) => reports.updateStatus(report.id, 'accepted'),
                onReject: (report) => reports.updateStatus(report.id, 'rejected'),
                onDuplicate: (report) =>
                    reports.updateStatus(report.id, 'duplicate'),
                onAssign: (report, worker) => reports.assignWorker(
                  reportId: report.id,
                  workerId: worker.uid,
                  workerName: worker.name,
                ),
                workers: workers,
              ),
            ),
            DashboardTab(
              label: 'Workers',
              child: _WorkerApprovalList(),
            ),
            DashboardTab(label: 'Profile', child: ProfileTab(profile: profile)),
          ],
        );
      },
    );
  }
}

class _WorkerApprovalList extends StatelessWidget {
  const _WorkerApprovalList();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserProfile>>(
      future: AuthServices().listUsers(),
      builder: (context, snapshot) {
        final workers = (snapshot.data ?? [])
            .where((user) => user.normalizedRole == UserRole.worker)
            .toList();
        if (workers.isEmpty) {
          return const Center(child: Text('No worker accounts yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: workers.length,
          itemBuilder: (context, index) {
            final worker = workers[index];
            return Card(
              child: ListTile(
                title: Text(worker.name),
                subtitle: Text(
                  '${worker.email}\nStatus: ${worker.approvalStatus ?? 'unknown'}',
                ),
                isThreeLine: true,
                trailing: worker.isApproved
                    ? const Text('Approved')
                    : TextButton(
                        onPressed: () async {
                          await AuthServices().setWorkerApproval(
                            uid: worker.uid,
                            approvalStatus: 'approved',
                          );
                        },
                        child: const Text('Approve'),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
