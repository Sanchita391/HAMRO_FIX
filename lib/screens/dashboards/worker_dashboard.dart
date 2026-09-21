import 'package:flutter/material.dart';

import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/screens/dashboards/dashboard_widgets.dart';
import 'package:hamro_fix/services/report_service.dart';

class WorkerDashboard extends StatelessWidget {
  const WorkerDashboard({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final reports = ReportService();
    return DashboardShell(
      title: 'Worker Dashboard',
      profile: profile,
      tabs: [
        DashboardTab(
          label: 'Assigned Work',
          child: ReportList(
            stream: reports.watchAssignedReports(profile.uid),
            onComplete: (report) =>
                reports.updateStatus(report.id, 'completed'),
          ),
        ),
        DashboardTab(
          label: 'Notifications',
          child: const Center(
            child: Text('Assigned work updates will appear here.'),
          ),
        ),
        DashboardTab(label: 'Profile', child: ProfileTab(profile: profile)),
      ],
    );
  }
}
