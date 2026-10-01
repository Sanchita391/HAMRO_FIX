import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:hamro_fix/core/constants/app_constants.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/services/audit_service.dart';
import 'package:hamro_fix/services/notification_service.dart';
import 'package:hamro_fix/widgets/worker_payment.dart';

class BudgetService {
  BudgetService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    NotificationService? notifications,
    AuditService? audit,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _notifications = notifications ?? NotificationService(),
       _audit = audit ?? AuditService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationService _notifications;
  final AuditService _audit;

  CollectionReference<Map<String, dynamic>> get _budgets =>
      _firestore.collection('budgets');
  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('budgetRequests');

  Stream<List<BudgetItem>> watchBudgets() {
    return _budgets.snapshots().map((snapshot) {
      final items = snapshot.docs.map(BudgetItem.fromFirestore).toList();
      items.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
      return items;
    });
  }

  Stream<List<BudgetRequest>> watchWorkerBudgetRequests(String workerId) {
    return _requests.where('workerId', isEqualTo: workerId).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(BudgetRequest.fromFirestore).toList();
      items.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
      return items;
    });
  }

  Stream<List<BudgetRequest>> watchBudgetRequests() {
    return _requests.snapshots().map((snapshot) {
      final items = snapshot.docs.map(BudgetRequest.fromFirestore).toList();
      items.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
      return items;
    });
  }

  Future<void> createBudget({
    required String title,
    required String category,
    required double amount,
    required String notes,
    String? reportId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await _budgets.add({
      'title': title.trim(),
      'category': category,
      'amount': amount,
      'notes': notes.trim(),
      'createdBy': user.uid,
      'reportId': reportId,
      'status': BudgetStatus.finalApproved,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitBudgetRequest({
    required ReportIssue report,
    required List<Map<String, dynamic>> items,
    required String remarks,
    int expectedDays = 0,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final itemsTotal = WorkerPay.itemsTotal(items);
    final salary = WorkerPay.salaryOf(itemsTotal);
    await _requests.add({
      'reportId': report.id,
      'workerId': user.uid,
      'officialId': null,
      'status': BudgetStatus.submittedToOfficial,
      'items': items,
      'itemsSubtotal': itemsTotal,
      'workerExpectedPayment': salary,
      'expectedWorkDays': expectedDays,
      'estimatedTotal': itemsTotal,
      'remarks': remarks,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('reports').doc(report.id).update({
      'budgetStatus': BudgetStatus.submittedToOfficial,
      'itemsSubtotal': itemsTotal,
      'workerExpectedPayment': salary,
      'expectedWorkDays': expectedDays,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _audit.log(
      action: 'budget_submitted',
      targetType: 'budgetRequest',
      targetId: report.id,
      actorRole: UserRole.worker,
    );
  }

  Future<void> forwardToAdmin(BudgetRequest request) async {
    final itemsTotal = request.itemsSubtotal > 0
        ? request.itemsSubtotal
        : WorkerPay.itemsTotal(request.items);
    final salary = WorkerPay.salaryOf(itemsTotal);
    await _requests.doc(request.id).update({
      'status': BudgetStatus.forwardedToAdmin,
      'officialId': _auth.currentUser?.uid,
      'itemsSubtotal': itemsTotal,
      'workerExpectedPayment': salary,
      'estimatedTotal': itemsTotal,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('reports').doc(request.reportId).update({
      'status': ReportStatus.sentToAdmin,
      'budgetStatus': BudgetStatus.forwardedToAdmin,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    try {
      final admins = await _firestore.collection('users').get();
      for (final doc in admins.docs) {
        final data = doc.data();
        final role = data['role'] as String?;
        final roles = ((data['roles'] as List?) ?? const [])
            .map((item) => item.toString())
            .toList();
        if (role != UserRole.admin && !roles.contains(UserRole.admin)) {
          continue;
        }
        await _notifications.send(
          recipientUid: doc.id,
          title: 'Budget to finalize',
          body: 'Official forwarded budget for report ${request.reportId}.',
          type: AlertType.budget,
          relatedId: request.reportId,
        );
      }
    } catch (_) {}
  }

  Future<void> adminDecide({
    required BudgetRequest request,
    required bool approve,
    required String remarks,
    required ReportIssue? report,
  }) async {
    final itemsTotal = request.itemsSubtotal > 0
        ? request.itemsSubtotal
        : WorkerPay.itemsTotal(request.items);
    final salary = WorkerPay.salaryOf(itemsTotal);
    final status = approve ? BudgetStatus.finalApproved : BudgetStatus.rejected;
    await _requests.doc(request.id).update({
      'status': status,
      'adminRemarks': remarks,
      'itemsSubtotal': itemsTotal,
      'workerExpectedPayment': salary,
      'estimatedTotal': itemsTotal,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    if (approve) {
      await _budgets.add({
        'title': report?.category ?? 'Civic project',
        'category': report?.category ?? 'General',
        'amount': itemsTotal,
        'notes': remarks,
        'createdBy': _auth.currentUser?.uid,
        'reportId': request.reportId,
        'status': BudgetStatus.finalApproved,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('reports').doc(request.reportId).update({
        'status': ReportStatus.budgetApproved,
        'budgetStatus': BudgetStatus.finalApproved,
        'approvedBudgetAmount': itemsTotal,
        'itemsSubtotal': itemsTotal,
        'workerExpectedPayment': salary,
        'expectedWorkDays': request.expectedWorkDays,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('reports').doc(request.reportId).update({
        'status': ReportStatus.budgetRejected,
        'budgetStatus': BudgetStatus.rejected,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    ReportIssue? resolved = report;
    if (resolved == null && request.reportId.isNotEmpty) {
      final doc = await _firestore
          .collection('reports')
          .doc(request.reportId)
          .get();
      if (doc.exists) {
        resolved = ReportIssue.fromFirestore(doc);
      }
    }
    try {
      final users = await _firestore.collection('users').get();
      for (final doc in users.docs) {
        final data = doc.data();
        final role = data['role'] as String?;
        final roles = ((data['roles'] as List?) ?? const [])
            .map((item) => item.toString())
            .toList();
        final isOfficial =
            role == UserRole.official || roles.contains(UserRole.official);
        if (!isOfficial) continue;
        if (resolved != null && doc.id == resolved.uid) continue;
        await _notifications.send(
          recipientUid: doc.id,
          title: approve
              ? 'Budget returned — assign funded work'
              : 'Budget rejected',
          body: approve
              ? 'Task budget NPR ${itemsTotal.toStringAsFixed(0)} for ${resolved?.publicId ?? request.reportId}. Worker salary NPR ${salary.toStringAsFixed(0)} (15%). Send funded work to the worker and the public reporter.'
              : remarks,
          type: AlertType.budget,
          relatedId: request.reportId,
        );
      }
    } catch (_) {}
  }
}
