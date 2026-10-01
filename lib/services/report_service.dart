import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hamro_fix/core/constants/app_constants.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/services/audit_service.dart';
import 'package:hamro_fix/services/notification_service.dart';
import 'package:hamro_fix/services/storage_service.dart';
import 'package:hamro_fix/services/video_storage_service.dart';
import 'package:hamro_fix/widgets/worker_payment.dart';

// Civic reports live in the Firestore "reports" collection.
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

  // Must be signed in before writing a report.
  User get _requireUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    return user;
  }

  // Public user creates a report with photo, GPS, and optional anonymous flag.
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
      if (VideoStorageService.isVideoFile(file)) continue;
      final encoded = await _storage.encodeImage(file);
      if (encoded != null) imageUrls.add(encoded);
    }
    final videoUrls = <String>[];
    final allVideos = [
      ...?videos,
      if (video != null) video,
      ...allImages.where(VideoStorageService.isVideoFile),
    ];
    final videoStore = VideoStorageService();
    for (final file in allVideos) {
      final url = await videoStore.upload(
        folder: '${user.uid}/reports/${doc.id}',
        file: file,
      );
      videoUrls.add(url);
    }

    final reporterName =
        (data['name'] as String?) ??
        (data['fullName'] as String?) ??
        user.displayName ??
        '';
    final reporterEmail = (data['email'] as String?) ?? user.email ?? '';
    final reporterPhone = (data['phone'] as String?) ?? '';
    final citizenship = data['citizenshipNumber'] as String?;

    await doc.set({
      'uid': user.uid,
      'citizenId': user.uid,
      'citizenName': isAnonymous ? '' : reporterName,
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
      'videoUrl': videoUrls.isNotEmpty ? videoUrls.first : null,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
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
    if (isAnonymous) {
      await doc.collection('private').doc('identity').set({
        'uid': user.uid,
        'name': reporterName,
        'email': reporterEmail,
        'phone': reporterPhone,
        'citizenshipNumber': citizenship,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
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
      title: isAnonymous ? 'New anonymous civic report' : 'New civic report',
      body: isAnonymous
          ? 'An anonymous $category report was submitted in ${municipality ?? 'your area'}.'
          : '$category report submitted in ${municipality ?? 'your area'}.',
      relatedId: doc.id,
    );
  }

  // Admin-only: real name of an anonymous reporter (private identity doc).
  Future<ReporterIdentity?> fetchReporterIdentity(ReportIssue report) async {
    if (!report.isAnonymous) {
      return ReporterIdentity(
        uid: report.uid,
        name: report.citizenName ?? '',
        email: '',
        phone: '',
      );
    }
    try {
      final doc = await _reports
          .doc(report.id)
          .collection('private')
          .doc('identity')
          .get();
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return ReporterIdentity.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  // Reports this public user submitted.
  Stream<List<ReportIssue>> watchMyReports(String uid) {
    return _reports.where('uid', isEqualTo: uid).snapshots().map(_mapReports);
  }

  // All reports (official and admin dashboards).
  Stream<List<ReportIssue>> watchAllReports() {
    return _reports.snapshots().map(_mapReports);
  }

  // Jobs assigned to this worker (new crew list or old single worker field).
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

  // Reports the public chose to show on the community feed.
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

  // Change the report status string in Firestore and add a timeline row.
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

  // Official accepts or declines. Accepted reports notify the public user.
  Future<void> officialDecision({
    required ReportIssue report,
    required String status,
    String? reason,
  }) async {
    await updateStatus(report.id, status, message: reason);
    if (status == ReportStatus.officialAccepted) {
      await _notifications.send(
        recipientUid: report.uid,
        title: 'Report accepted',
        body:
            reason?.trim().isNotEmpty == true
                ? reason!.trim()
                : 'An official accepted ${report.publicId}. Work can now move forward.',
        type: AlertType.reportAccepted,
        relatedId: report.id,
      );
    }
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

  // Official assigns one or more workers. Their uids go on the report document.
  Future<void> assignWorkers({
    required String reportId,
    required List<String> workerIds,
    required List<String> workerNames,
    ReportIssue? report,
  }) async {
    final ids = <String>[];
    final names = <String>[];
    void addCrew(String id, String name) {
      final uid = id.trim();
      if (uid.isEmpty || ids.contains(uid)) return;
      ids.add(uid);
      names.add(name.trim().isEmpty ? 'Worker' : name.trim());
    }

    if (report != null) {
      for (var i = 0; i < report.crewIds.length; i++) {
        addCrew(
          report.crewIds[i],
          i < report.crewNames.length ? report.crewNames[i] : 'Worker',
        );
      }
    }
    final alreadyAssigned = {...ids};
    for (var i = 0; i < workerIds.length; i++) {
      addCrew(
        workerIds[i],
        i < workerNames.length ? workerNames[i] : 'Worker',
      );
    }
    if (ids.isEmpty) {
      throw const AuthReportFailure('Assign at least one worker.');
    }
    final addedNames = <String>[];
    for (var i = 0; i < ids.length; i++) {
      if (!alreadyAssigned.contains(ids[i])) addedNames.add(names[i]);
    }
    final addingMore = alreadyAssigned.isNotEmpty;
    if (addingMore && addedNames.isEmpty) {
      throw const AuthReportFailure(
        'Select at least one extra worker to add to this task.',
      );
    }
    await _reports.doc(reportId).update({
      'assignedWorkerId': ids.first,
      'workerId': ids.first,
      'assignedWorkerName': names.first,
      'assignedWorkerIds': ids,
      'assignedWorkerNames': names,
      if (!addingMore) 'status': ReportStatus.workerAssigned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addTimeline(
      reportId: reportId,
      action: addingMore ? 'worker_added' : 'worker_assigned',
      message: addingMore
          ? 'Added ${addedNames.join(', ')} to the crew'
          : 'Assigned to ${names.join(', ')}',
    );
  }

  // Worker records valid/fake, photos, and material prices on the report.
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
    final videoUrls = <String>[];
    final videoStore = VideoStorageService();
    for (final file in evidenceImages) {
      if (VideoStorageService.isVideoFile(file)) {
        videoUrls.add(
          await videoStore.upload(
            folder: '${_auth.currentUser!.uid}/inspections/${report.id}',
            file: file,
          ),
        );
      } else {
        final encoded = await _storage.encodeImage(file, maxWidth: 360);
        if (encoded != null) imageUrls.add(encoded);
      }
    }
    for (final file in evidenceVideos) {
      videoUrls.add(
        await videoStore.upload(
          folder: '${_auth.currentUser!.uid}/inspections/${report.id}',
          file: file,
        ),
      );
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
      'workerEvidenceVideos': videoUrls,
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

  // Official confirms a fake report and blacklists that public user.
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
    await _audit.log(
      action: 'blacklist_confirmed',
      targetType: 'user',
      targetId: report.uid,
      actorRole: UserRole.official,
    );
  }

    // Photos are stored in reports/{id}/completionPhotos so the parent stays under 1MB.
    CollectionReference<Map<String, dynamic>> _completionPhotos(String reportId) {
      return _reports.doc(reportId).collection('completionPhotos');
    }

    // Read completion photo URLs once.
    Future<List<String>> fetchCompletionPhotos(String reportId) async {
      try {
        final snapshot = await _completionPhotos(reportId).get();
        final urls = snapshot.docs
            .map((doc) => (doc.data()['imageUrl'] as String?) ?? '')
            .where((url) => url.isNotEmpty)
            .toList();
        return urls;
      } catch (_) {
        return const [];
      }
    }

    // Live list of completion photos for the official details screen.
    Stream<List<String>> watchCompletionPhotos(String reportId) {
      return Stream<List<String>>.multi((controller) {
        final sub = _completionPhotos(reportId).snapshots().listen(
          (snapshot) {
            if (controller.isClosed) return;
            controller.add(
              snapshot.docs
                  .map((doc) => (doc.data()['imageUrl'] as String?) ?? '')
                  .where((url) => url.isNotEmpty)
                  .toList(),
            );
          },
          onError: (Object _) {
            if (!controller.isClosed) controller.add(const <String>[]);
          },
        );
        controller.onCancel = sub.cancel;
      });
    }

  // Worker marks work done and saves small completion photos in a subcollection.
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
    if (files.isEmpty) {
      throw const AuthReportFailure('Add at least one finished-work photo.');
    }
    final urls = <String>[];
    for (final file in files.take(2)) {
      final encoded = await _storage.encodeImage(
        file,
        maxWidth: 220,
        maxBytes: 45000,
      );
      if (encoded != null) urls.add(encoded);
    }
    if (urls.isEmpty) {
      throw const AuthReportFailure(
        'Those photos could not be saved. Try a smaller photo.',
      );
    }
    for (final url in urls) {
      await _completionPhotos(reportId).add({
        'imageUrl': url,
        'workerId': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await _reports.doc(reportId).update({
      'status': ReportStatus.workCompleted,
      'completionDescription': description,
      'completionLatitude': latitude,
      'completionLongitude': longitude,
      'workerCompletionSubmitted': true,
      'hasCompletionPhotos': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addTimeline(
      reportId: reportId,
      action: 'work_completed',
      message: description ?? 'Worker submitted completion evidence',
    );
    try {
      final tasks = await _firestore
          .collection('tasks')
          .where('reportId', isEqualTo: reportId)
          .get();
      for (final doc in tasks.docs) {
        await doc.reference.update({
          'status': TaskStatus.completed,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
    await _notifyOfficials(
      title: 'Completed work to review',
      body:
          'A worker sent finished-work photos. Open Completed on Reports and send them to the public when you approve.',
      relatedId: reportId,
    );
  }

  Future<void> approveCompletion(ReportIssue report) {
    return shareCompletionWithPublic(report);
  }

  // Official shares finished photos with the public reporter.
  Future<void> shareCompletionWithPublic(ReportIssue report) async {
    var photos = [
      ...report.completionImages,
      if (report.proofImageUrl != null && report.proofImageUrl!.isNotEmpty)
        report.proofImageUrl!,
    ];
    if (photos.isEmpty) {
      photos = await fetchCompletionPhotos(report.id);
    }
    if (photos.isEmpty && !report.hasCompletionPhotos) {
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
  }

  // Public user posts this report on the feed with a caption.
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
      'imageUrl': report.imageUrl,
      'videoUrl': report.videoUrl,
      'videoUrls': report.videoUrls,
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
        'imageUrl': report.imageUrl,
        'videoUrl': report.videoUrl,
        'videoUrls': report.videoUrls,
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

  // Add a comment on a report (legacy comments collection on the report).
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

  // History of status changes under reports/{id}/timeline.
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

  // Send the same alert to every user whose role is official.
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
          type: AlertType.report,
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
