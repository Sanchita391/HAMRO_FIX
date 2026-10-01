import 'package:flutter/material.dart';

import 'package:hamro_fix/core/theme/app_theme.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/screens/reports/report_details_page.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/budget_service.dart';
import 'package:hamro_fix/services/report_service.dart';
import 'package:hamro_fix/widgets/worker_payment.dart';

class WorkerPaymentsTab extends StatelessWidget {
  const WorkerPaymentsTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReportIssue>>(
      stream: ReportService().watchAssignedReports(profile.uid),
      builder: (context, reportSnap) {
        return StreamBuilder<List<BudgetRequest>>(
          stream: BudgetService().watchWorkerBudgetRequests(profile.uid),
          builder: (context, paySnap) {
            if (reportSnap.hasError) {
              return Center(child: Text(AuthMessages.from(reportSnap.error!)));
            }
            if (paySnap.hasError) {
              return Center(child: Text(AuthMessages.from(paySnap.error!)));
            }
            if (!reportSnap.hasData || !paySnap.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: HamroFixTheme.mediumGreen,
                ),
              );
            }
            final requests = paySnap.data ?? [];
            final byReport = <String, BudgetRequest>{};
            for (final item in requests) {
              if (!byReport.containsKey(item.reportId)) {
                byReport[item.reportId] = item;
              }
            }
            final reports = (reportSnap.data ?? [])
                .where(
                  (item) =>
                      item.taskBudget > 0 ||
                      item.inspectionItems.isNotEmpty ||
                      byReport.containsKey(item.id),
                )
                .toList();
            if (reports.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'After a task has a budget, your salary (15% of that budget) is listed here.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            var salaryTotal = 0.0;
            for (final report in reports) {
              salaryTotal += WorkerPay.salaryOf(report.taskBudget);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: reports.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Card(
                    elevation: 0,
                    color: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total salary',
                            style: TextStyle(
                              color: Color(0xFFC8E6C9),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'NPR ${salaryTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Salary is 15% of each task budget. Materials budget is shown on the card but is not added to this total.',
                            style: TextStyle(
                              color: Color(0xFFE8F5E9),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final report = reports[index - 1];
                return _WorkerPayCard(
                  profile: profile,
                  report: report,
                  request: byReport[report.id],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _WorkerPayCard extends StatelessWidget {
  const _WorkerPayCard({
    required this.profile,
    required this.report,
    this.request,
  });

  final UserProfile profile;
  final ReportIssue report;
  final BudgetRequest? request;

  String _statusLabel() {
    if (report.approvedBudgetAmount != null &&
        report.approvedBudgetAmount! > 0) {
      return 'Admin budget set';
    }
    final status = request?.status ?? report.budgetStatus ?? '';
    if (status.isEmpty) return 'Waiting for budget';
    return status.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final budget = report.taskBudget;
    final salary = WorkerPay.salaryOf(budget);
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
                Expanded(
                  child: Text(
                    report.publicId,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(_statusLabel()),
                ),
              ],
            ),
            Text(
              report.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            WorkerPaymentSummary(
              itemsTotal: budget,
              expectedPayment: salary,
              expectedDays: report.expectedWorkDays,
              salaryAsGrandTotal: true,
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReportDetailsPage(
                      report: report,
                      profile: profile,
                    ),
                  ),
                );
              },
              child: const Text('Open task'),
            ),
          ],
        ),
      ),
    );
  }
}
