import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/services/notification_service.dart';
import 'package:hamro_fix/services/storage_service.dart';

class ReportService {
  ReportService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    StorageService? storage,
    NotificationService? notifications,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? StorageService(),
       _notifications = notifications ?? NotificationService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StorageService _storage;
  final NotificationService _notifications;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  Future<void> createReport({
    required String title,
    required String description,
    required String category,
    XFile? image,
    XFile? video,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final doc = _reports.doc();
    String? imageUrl;
    String? videoUrl;
    if (image != null) {
      imageUrl = await _storage.uploadXFile(
        path: 'reports/${doc.id}/${image.name}',
        file: image,
      );
    }
    if (video != null) {
      videoUrl = await _storage.uploadXFile(
        path: 'reports/${doc.id}/${video.name}',
        file: video,
      );
    }
    await doc.set({
      'uid': user.uid,
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'status': 'submitted',
      'assignedWorkerId': null,
      'assignedWorkerName': null,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ReportIssue>> watchMyReports(String uid) {
    return _reports.where('uid', isEqualTo: uid).snapshots().map(_mapReports);
  }

  Stream<List<ReportIssue>> watchAllReports() {
    return _reports.snapshots().map(_mapReports);
  }

  Stream<List<ReportIssue>> watchAssignedReports(String workerId) {
    return _reports
        .where('assignedWorkerId', isEqualTo: workerId)
        .snapshots()
        .map(_mapReports);
  }

  List<ReportIssue> _mapReports(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final items = snapshot.docs.map(ReportIssue.fromFirestore).toList();
    items.sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );
    return items;
  }

  Future<void> updateStatus(String reportId, String status) async {
    await _reports.doc(reportId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> assignWorker({
    required String reportId,
    required String workerId,
    required String workerName,
  }) async {
    await _reports.doc(reportId).update({
      'assignedWorkerId': workerId,
      'assignedWorkerName': workerName,
      'status': 'assigned',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _notifications.send(
      recipientUid: workerId,
      title: 'New assigned work',
      body: 'You were assigned report: $reportId',
      type: 'assignment',
      relatedId: reportId,
    );
  }

  Future<void> completeReport({
    required String reportId,
    XFile? proofImage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    String? proofUrl;
    if (proofImage != null) {
      proofUrl = await _storage.uploadXFile(
        path: 'proof/$reportId/${user.uid}/${proofImage.name}',
        file: proofImage,
      );
    }
    await _reports.doc(reportId).update({
      'status': 'completed',
      'proofImageUrl': proofUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addComment({
    required String reportId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await _reports.doc(reportId).collection('comments').add({
      'uid': user.uid,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
