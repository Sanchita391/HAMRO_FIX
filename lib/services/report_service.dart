import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hamro_fix/core/constants/app_constants.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/services/audit_service.dart';
import 'package:hamro_fix/services/notification_service.dart';
import 'package:hamro_fix/services/storage_service.dart';
import 'package:hamro_fix/widgets/worker_payment.dart';

class ReportService {
  ReportService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    StorageService? storage,
    NotificationService? notifications,
    AuditService? audit,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? StorageService(),
       _notifications = notifications ?? NotificationService(),
       _audit = audit ?? AuditService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StorageService _storage;
  final NotificationService _notifications;
  final AuditService _audit;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  User get _requireUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    return user;
  }

  Future<void> createReport({
    required String title,
    required String description,
    required String category,
    XFile? image,
    XFile? video,
    List<XFile>? images,
    List<XFile>? videos,
    double? latitude,
    double? longitude,
    DateTime? locationTimestamp,
    String? address,
    String? municipality,
    String? district,
    bool isAnonymous = false,
  }) async {
    final user = _requireUser;
    final profile = await _firestore.collection('users').doc(user.uid).get();
    final data = profile.data() ?? {};
    final status = data['accountStatus'] as String?;
    if (status == 'blacklisted' || status == 'suspended') {
      throw const AuthReportFailure('This account cannot submit new reports.');
    }
    final roles = ((data['roles'] as List?) ?? const [])
        .map((item) => item.toString())
        .toList();
    final role = (data['role'] as String?) ?? '';
    final trustedStaff =
        role == UserRole.official ||
        role == UserRole.worker ||
        role == UserRole.admin ||
        roles.contains(UserRole.official) ||
        roles.contains(UserRole.worker) ||
        roles.contains(UserRole.admin);
    if (!user.emailVerified && !trustedStaff) {
      throw const AuthReportFailure(
        'Please verify your email before submitting a report.',
      );
    }

    final doc = _reports.doc();
    final trackingCode =
        'HF-${doc.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').substring(0, 6).toUpperCase()}';
    final imageUrls = <String>[];
    final allImages = [...?images, if (image != null) image];
    for (final file in allImages) {
      final encoded = await _storage.encodeImage(file);
      if (encoded != null) imageUrls.add(encoded);
    }

    await doc.set({
      'uid': user.uid,
      'citizenId': user.uid,
      'citizenName': user.displayName ?? '',
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'status': ReportStatus.submitted,
      'trackingCode': trackingCode,
      'assignedWorkerId': null,
      'assignedWorkerName': null,
      'assignedWorkerIds': <String>[],
      'assignedWorkerNames': <String>[],
      'inspectionItems': <Map<String, dynamic>>[],
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : null,
      'videoUrl': null,
      'imageUrls': imageUrls,
      'videoUrls': <String>[],
      'latitude': latitude,
      'longitude': longitude,
      'locationTimestamp': locationTimestamp,
      'address': address,
      'municipality': municipality,
      'district': district,
      'isAnonymous': isAnonymous,
      'publishedToFeed': false,
      'citizenVisibility': 'private',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addTimeline(
      reportId: doc.id,
      action: 'submitted',
      message: 'Public submitted report',
    );
    await _audit.log(
      action: 'report_created',
      targetType: 'report',
      targetId: doc.id,
      actorRole: UserRole.public,
    );
    await _notifyOfficials(
      title: 'New civic report',
      body: '$category report submitted in ${municipality ?? 'your area'}.',
      relatedId: doc.id,
    );
  }

  Stream<List<ReportIssue>> watchMyReports(String uid) {
    return _reports.where('uid', isEqualTo: uid).snapshots().map(_mapReports);
  }

  Stream<List<ReportIssue>> watchAllReports() {
    return _reports.snapshots().map(_mapReports);
  }

  Stream<List<ReportIssue>> watchAssignedReports(String workerId) {
    final controller = StreamController<List<ReportIssue>>();
    var fromCrew = <ReportIssue>[];
    var fromLegacy = <ReportIssue>[];

    void emit() {
      final merged = <String, ReportIssue>{};
      for (final item in [...fromCrew, ...fromLegacy]) {
        merged[item.id] = item;
      }
      final items = merged.values.toList()
        ..sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
      if (!controller.isClosed) controller.add(items);
    }

    final crewSub = _reports
        .where('assignedWorkerIds', arrayContains: workerId)
        .snapshots()
        .listen(
          (snapshot) {
            fromCrew = _mapReports(snapshot);
            emit();
          },
          onError: (_) {
            fromCrew = [];
            emit();
          },
        );
    final legacySub = _reports
        .where('assignedWorkerId', isEqualTo: workerId)
        .snapshots()
        .listen(
          (snapshot) {
            fromLegacy = _mapReports(snapshot);
            emit();
          },
          onError: controller.addError,
        );
    controller.onCancel = () async {
      await crewSub.cancel();
      await legacySub.cancel();
    };
    return controller.stream;
  }

  Stream<List<ReportIssue>> watchPublicFeed() {
    return _reports
        .where('publishedToFeed', isEqualTo: true)
        .snapshots()
        .map(_mapReports);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchReport(String id) {
    return _reports.doc(id).snapshots();
  }

  Future<ReportIssue?> fetchReport(String id) async {
    final doc = await _reports.doc(id).get();
    if (!doc.exists) return null;
    return ReportIssue.fromFirestore(doc);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchTimeline(String reportId) {
    return _reports
        .doc(reportId)
        .collection('timeline')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  List<ReportIssue> _mapReports(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final items = snapshot.docs.map(ReportIssue.fromFirestore).toList();
    items.sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );
    return items;
  }

  Future<void> updateStatus(
    String reportId,
    String status, {
    String? message,
  }) async {
    await _reports.doc(reportId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addTimeline(
      reportId: reportId,
      action: status,
      message: message ?? 'Status updated to $status',
    );
  }

  Future<void> officialDecision({
    required ReportIssue report,
    required String status,
    String? reason,
  }) async {
    await updateStatus(report.id, status, message: reason);
    await _notifications.send(
      recipientUid: report.uid,
      title: status == ReportStatus.officialDeclined
          ? 'Report declined'
          : 'Report accepted',
      body: reason ?? 'An official reviewed your report.',
      type: 'report_status',
      relatedId: report.id,
    );
    await _audit.log(
      action: 'official_report_decision',
      targetType: 'report',
      targetId: report.id,
      actorRole: UserRole.official,
      metadata: {'status': status},
    );
  }

  Future<void> markDuplicate({
    required ReportIssue report,
    required String duplicateOfId,
    required String explanation,
  }) async {
    await _reports.doc(report.id).update({
      'status': ReportStatus.duplicate,
      'duplicateOfId': duplicateOfId,
      'duplicateExplanation': explanation,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addTimeline(
      reportId: report.id,
      action: 'duplicate',
      message: explanation,
    );
    await _notifications.send(
      recipientUid: report.uid,
      title: 'Report marked as duplicate',
      body: explanation,
      type: 'report_status',
      relatedId: report.id,
    );
  }

  Future<void> assignWorker({
    required String reportId,
    required String workerId,
    required String workerName,
  }) {
    return assignWorkers(
      reportId: reportId,
      workerIds: [workerId],
      workerNames: [workerName],
    );
  }

  Future<void> assignWorkers({
    required String reportId,
    required List<String> workerIds,
    required List<String> workerNames,
  }) async {
    final ids = <String>[];
    final names = <String>[];
    for (var i = 0; i < workerIds.length; i++) {
      final id = workerIds[i].trim();
      if (id.isEmpty || ids.contains(id)) continue;
      ids.add(id);
      names.add(
        i < workerNames.length && workerNames[i].trim().isNotEmpty
            ? workerNames[i].trim()
            : 'Worker',
      );
    }
    if (ids.isEmpty) {
      throw const AuthReportFailure('Assign at least one worker.');
    }
    await _reports.doc(reportId).update({
      'assignedWorkerId': ids.first,
      'workerId': ids.first,
      'assignedWorkerName': names.first,
      'assignedWorkerIds': ids,
      'assignedWorkerNames': names,
      'status': ReportStatus.workerAssigned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addTimeline(
      reportId: reportId,
      action: 'worker_assigned',
      message: 'Assigned to ${names.join(', ')}',
    );
    for (final id in ids) {
      await _notifications.send(
        recipientUid: id,
        title: 'Inspection assigned',
        body:
            'Crew of ${ids.length}: go to the reported spot, inspect, and submit evidence.',
        type: 'assignment',
        relatedId: reportId,
      );
    }
  }

  Future<void> submitInspection({
    required ReportIssue report,
    required String decision,
    required String reason,
    required double latitude,
    required double longitude,
    List<XFile> evidenceImages = const [],
    List<XFile> evidenceVideos = const [],
    List<Map<String, dynamic>> budgetItems = const [],
  }) async {
    if (_auth.currentUser == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final imageUrls = <String>[];
    for (final file in evidenceImages) {
      final encoded = await _storage.encodeImage(file, maxWidth: 360);
      if (encoded != null) imageUrls.add(encoded);
    }
    final status = switch (decision) {
      'fake' => ReportStatus.verifiedFake,
      'needs_info' => ReportStatus.needsMoreInfo,
      _ => ReportStatus.verifiedValid,
    };
    final inspector = _auth.currentUser?.uid;
    await _reports.doc(report.id).update({
      'status': status,
      'workerVerification': decision,
      'workerVerificationReason': reason,
      'workerEvidenceImages': imageUrls,
      'workerEvidenceVideos': <String>[],
      'inspectionLatitude': latitude,
      'inspectionLongitude': longitude,
      'inspectionItems': budgetItems,
      if (inspector != null) 'inspectedById': inspector,
      if (inspector != null) 'inspectedByIds': FieldValue.arrayUnion([inspector]),
      if (decision == 'valid')
        'itemsSubtotal': WorkerPay.itemsTotal(budgetItems),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addTimeline(
      reportId: report.id,
      action: 'inspection',
      message: '$decision: $reason',
    );
    if (status == ReportStatus.verifiedFake) {
      await _notifications.send(
        recipientUid: report.uid,
        title: 'Report flagged',
        body:
            'A worker marked ${report.publicId} as suspected fake. An official will review it.',
        type: 'report_status',
        relatedId: report.id,
      );
    }
    await _notifyOfficials(
      title: 'Worker inspection submitted',
      body: '${report.publicId} marked $decision.',
      relatedId: report.id,
    );
  }

  Future<void> updateInspectionMaterials({
    required ReportIssue report,
    required List<Map<String, dynamic>> items,
  }) async {
    await _reports.doc(report.id).update({
      'inspectionItems': items,
      'itemsSubtotal': WorkerPay.itemsTotal(items),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addTimeline(
      reportId: report.id,
      action: 'materials_updated',
      message: 'Worker updated material items',
    );
  }

  Future<void> confirmFakeAndBlacklist({
    required ReportIssue report,
    required String reason,
  }) async {
    final official = _requireUser;
    await _reports.doc(report.id).update({
      'status': ReportStatus.verifiedFake,
      'fakeConfirmed': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('users').doc(report.uid).set({
      'accountStatus': 'blacklisted',
      'approvalStatus': 'blacklisted',
    }, SetOptions(merge: true));
    await _firestore.collection('blacklistedUsers').doc(report.uid).set({
      'citizenId': report.uid,
      'reason': reason,
      'reportId': report.id,
      'blacklistedBy': official.uid,
      'blacklistedAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });
    await _notifications.send(
      recipientUid: report.uid,
      title: 'Account restricted',
      body: 'A report was confirmed fake. You cannot submit new reports.',
      type: 'blacklist',
      relatedId: report.id,
    );
    await _audit.log(
      action: 'blacklist_confirmed',
      targetType: 'user',
      targetId: report.uid,
      actorRole: UserRole.official,
    );
  }

  Future<void> completeReport({
    required String reportId,
    XFile? proofImage,
    List<XFile> proofImages = const [],
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    if (_auth.currentUser == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final files = [...proofImages, if (proofImage != null) proofImage];
    final urls = <String>[];
    for (final file in files) {
      final encoded = await _storage.encodeImage(file, maxWidth: 480);
      if (encoded != null) urls.add(encoded);
    }
    await _reports.doc(reportId).update({
      'status': ReportStatus.workCompleted,
      'proofImageUrl': urls.isEmpty ? null : urls.first,
      'completionImages': urls,
      'completionDescription': description,
      'completionLatitude': latitude,
      'completionLongitude': longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addTimeline(
      reportId: reportId,
      action: 'work_completed',
      message: description ?? 'Worker submitted completion evidence',
    );
    await _notifyOfficials(
      title: 'Completed photos to review',
      body: 'A worker sent finished-work photos for $reportId. Send them to the public when you approve.',
      relatedId: reportId,
    );
  }

  Future<void> approveCompletion(ReportIssue report) {
    return shareCompletionWithPublic(report);
  }

  Future<void> shareCompletionWithPublic(ReportIssue report) async {
    final hasPhotos =
        report.completionImages.isNotEmpty ||
        (report.proofImageUrl != null && report.proofImageUrl!.isNotEmpty);
    if (!hasPhotos) {
      throw const AuthReportFailure(
        'The worker has not sent completed-work photos yet.',
      );
    }
    await _reports.doc(report.id).update({
      'status': ReportStatus.completed,
      'completionSharedWithPublic': true,
      'citizenVisibility': 'public',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addTimeline(
      reportId: report.id,
      action: 'completion_shared',
      message: 'Official sent completed photos to the public reporter',
    );
    await _notifications.send(
      recipientUid: report.uid,
      title: 'Before & after ready',
      body:
          'Completed photos for ${report.publicId} are ready. Post them on the same feed item to compare before and after.',
      type: 'completed',
      relatedId: report.id,
    );
  }

  Future<void> publishToFeed({
    required ReportIssue report,
    required bool anonymous,
    String caption = '',
  }) async {
    final user = _requireUser;
    if (user.uid != report.uid) {
      throw const AuthReportFailure(
        'You can only post your own reports to the feed.',
      );
    }
    final workDone = report.canPublicPostAfter;
    if (!report.canPublicPostBudget && !workDone) {
      throw const AuthReportFailure(
        'Wait until the official sends the approved budget to you.',
      );
    }
    final captionText = caption.trim();
    final budgetLine = report.approvedBudgetAmount == null
        ? ''
        : '\nFinal budget: NPR ${report.approvedBudgetAmount!.toStringAsFixed(0)}';
    final body = captionText.isEmpty
        ? '${report.category} · ${report.publicId}\n${report.description}$budgetLine'
        : '$captionText$budgetLine';
    final authorName = anonymous
        ? 'Anonymous public'
        : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : (report.title.isEmpty ? 'Public' : report.title));
    final fields = <String, dynamic>{
      'text': body,
      'caption': captionText,
      'isAnonymous': anonymous,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    var postId = report.feedPostId;
    if (postId == null || postId.isEmpty) {
      try {
        final existing = await _firestore
            .collection('feedPosts')
            .where('reportId', isEqualTo: report.id)
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) postId = existing.docs.first.id;
      } catch (_) {}
    }
    var wrotePost = false;
    if (postId != null && postId.isNotEmpty) {
      try {
        await _firestore.collection('feedPosts').doc(postId).update(fields);
        wrotePost = true;
      } catch (_) {
        postId = null;
      }
    }
    if (!wrotePost) {
      final created = await _firestore.collection('feedPosts').add({
        'uid': user.uid,
        'reportId': report.id,
        'trackingCode': report.publicId,
        'authorName': authorName,
        'text': body,
        'caption': captionText,
        'isAnonymous': anonymous,
        'approvedBudgetAmount': report.approvedBudgetAmount,
        'likedBy': <String>[],
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      postId = created.id;
    }
    try {
      final update = <String, dynamic>{
        'publishedToFeed': true,
        'publishedBudgetToFeed': true,
        'citizenVisibility': 'public',
        'isAnonymous': anonymous,
        'feedPostId': postId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (workDone) {
        update['status'] = ReportStatus.publicFeed;
        update['publishedAfterToFeed'] = true;
        update['completionSharedWithPublic'] = true;
      }
      await _reports.doc(report.id).update(update);
    } catch (_) {}
  }

  Future<void> addComment({
    required String reportId,
    required String text,
  }) async {
    final user = _requireUser;
    await _reports.doc(reportId).collection('comments').add({
      'uid': user.uid,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _addTimeline({
    required String reportId,
    required String action,
    required String message,
  }) async {
    final user = _auth.currentUser;
    await _reports.doc(reportId).collection('timeline').add({
      'timestamp': FieldValue.serverTimestamp(),
      'actorId': user?.uid,
      'action': action,
      'message': message,
    });
  }

  Future<void> _notifyOfficials({
    required String title,
    required String body,
    required String relatedId,
  }) async {
    try {
      final officials = await _firestore.collection('users').get();
      for (final doc in officials.docs) {
        final data = doc.data();
        final role = data['role'] as String?;
        final roles = ((data['roles'] as List?) ?? const [])
            .map((item) => item.toString())
            .toList();
        final isOfficial =
            role == UserRole.official || roles.contains(UserRole.official);
        if (!isOfficial) continue;
        final status = (doc.data()['accountStatus'] as String?) ?? 'approved';
        if (status != 'approved' && status != 'active') continue;
        await _notifications.send(
          recipientUid: doc.id,
          title: title,
          body: body,
          type: 'report',
          relatedId: relatedId,
        );
      }
    } catch (_) {}
  }
}

class AuthReportFailure implements Exception {
  const AuthReportFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
