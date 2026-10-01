import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:hamro_fix/core/constants/app_constants.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/services/notification_service.dart';
import 'package:hamro_fix/services/report_service.dart';

class TaskService {
  TaskService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    NotificationService? notifications,
    ReportService? reports,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _notifications = notifications ?? NotificationService(),
       _reports = reports ?? ReportService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationService _notifications;
  final ReportService _reports;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection('tasks');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchForWorker(String workerId) {
    return _tasks.where('workerId', isEqualTo: workerId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAll() {
    return _tasks.snapshots();
  }

  Future<void> assignFundedTask({
    required ReportIssue report,
    required String workerId,
    required String instructions,
    DateTime? deadline,
    List<String>? workerIds,
  }) async {
    if (report.status != ReportStatus.budgetApproved) {
      throw const AuthReportFailure(
        'A task can only be assigned after the admin approves the budget.',
      );
    }
    final crew = () {
      if (workerIds != null && workerIds.isNotEmpty) {
        return workerIds.where((id) => id.isNotEmpty).toList();
      }
      if (report.inspectorIds.isNotEmpty) return report.inspectorIds;
      if (report.crewIds.isNotEmpty) return report.crewIds;
      return workerId.isEmpty ? <String>[] : [workerId];
    }();
    if (crew.isEmpty) {
      throw const AuthReportFailure(
        'No worker is linked to this report yet.',
      );
    }
    final official = _auth.currentUser;
    final amount =
        report.approvedBudgetAmount?.toStringAsFixed(0) ?? '0';
    for (final id in crew) {
      await _tasks.add({
        'reportId': report.id,
        'workerId': id,
        'workerIds': crew,
        'officialId': official?.uid,
        'instructions': instructions,
        'approvedBudgetAmount': report.approvedBudgetAmount,
        'deadline': deadline,
        'status': TaskStatus.assigned,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _notifications.send(
        recipientUid: id,
        title: 'Funded work assigned',
        body:
            '${report.publicId}: complete the repair. Approved budget NPR $amount.',
        type: AlertType.task,
        relatedId: report.id,
      );
    }
    await _reports.updateStatus(
      report.id,
      ReportStatus.taskAssigned,
      message: 'Official sent funded work to the worker and the public',
    );
    await _firestore.collection('reports').doc(report.id).update({
      'budgetSharedWithPublic': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    try {
      final budgets = await _firestore
          .collection('budgetRequests')
          .where('reportId', isEqualTo: report.id)
          .get();
      for (final doc in budgets.docs) {
        await doc.reference.update({
          'status': BudgetStatus.sentToWorker,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
    await _notifications.sendOrReplace(
      recipientUid: report.uid,
      title: 'Budget finalized',
      body:
          'Final budget NPR $amount for ${report.publicId}. You can post this budget on the feed now.',
      type: AlertType.budget,
      relatedId: report.id,
    );
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _tasks.doc(taskId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
