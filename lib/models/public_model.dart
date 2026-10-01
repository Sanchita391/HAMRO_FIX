import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hamro_fix/core/constants/app_constants.dart';

// Dart classes that match Firestore documents (users, reports, feed, budgets).

// The four app roles stored on users/{uid}.role
class UserRole {
  static const String public = 'public';
  static const String official = 'official';
  static const String worker = 'worker';
  static const String admin = 'admin';

  static const List<String> all = [public, official, worker, admin];

  static String? normalize(String? raw) {
    if (raw == null) return null;
    switch (raw.trim().toLowerCase()) {
      case 'public':
      case 'citizen':
        return public;
      case 'official':
        return official;
      case 'worker':
        return worker;
      case 'admin':
        return admin;
      default:
        return raw.trim().isEmpty ? null : raw.trim().toLowerCase();
    }
  }

  static bool isKnown(String? role) => all.contains(normalize(role));
}

// One row from the Firestore "users" collection.
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? role;
  final String? employeeId;
  final String? approvalStatus;
  final String? accountStatus;
  final String? profileImageUrl;
  final String? specialization;
  final List<String> specializations;
  final String? district;
  final String? municipality;
  final String? department;
  final String? citizenshipNumber;
  final String? gender;
  final String? username;
  final bool mustChangePassword;
  final List<String> roles;
  final DateTime? createdAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.role,
    this.employeeId,
    this.approvalStatus,
    this.accountStatus,
    this.profileImageUrl,
    this.specialization,
    this.specializations = const [],
    this.district,
    this.municipality,
    this.department,
    this.citizenshipNumber,
    this.gender,
    this.username,
    this.mustChangePassword = false,
    this.roles = const [],
    this.createdAt,
  });

  String? get normalizedRole => UserRole.normalize(role);

  // Combine role and roles[] so old documents still work.
  List<String> get assignedRoles {
    final fromList = roles
        .map(UserRole.normalize)
        .whereType<String>()
        .where(UserRole.isKnown)
        .toSet();
    final current = normalizedRole;
    if (current != null && UserRole.isKnown(current)) {
      fromList.add(current);
    }
    return fromList.toList();
  }

  bool hasRole(String value) {
    return assignedRoles.contains(UserRole.normalize(value));
  }

  bool get canComposeAlerts =>
      hasRole(UserRole.worker) ||
      hasRole(UserRole.official) ||
      hasRole(UserRole.admin);

  String get staffRole {
    if (hasRole(UserRole.admin)) return UserRole.admin;
    if (hasRole(UserRole.official)) return UserRole.official;
    if (hasRole(UserRole.worker)) return UserRole.worker;
    return normalizedRole ?? '';
  }

  String get status {
    final value = accountStatus ?? approvalStatus;
    if (value == null || value.isEmpty) return 'approved';
    return value;
  }

  bool get isApproved => status == 'approved' || status == 'active';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isBlacklisted => status == 'blacklisted';
  // Cannot use the app until admin/official lifts this.
  bool get isRestricted =>
      isBlacklisted ||
      status == 'suspended' ||
      status == 'disabled' ||
      status == 'removed';

  bool get hideContactEmail =>
      hasRole(UserRole.public) || hasRole(UserRole.worker);

  String get displayName {
    final value = name.trim();
    if (value.isNotEmpty) return value;
    if (hasRole(UserRole.worker)) return 'Worker';
    if (hasRole(UserRole.public)) return 'Public user';
    if (hasRole(UserRole.official)) return 'Official';
    if (hasRole(UserRole.admin)) return 'Admin';
    return 'User';
  }

  String get specialtyLabel {
    if (specializations.isNotEmpty) return specializations.join(', ');
    return (specialization ?? '').trim();
  }

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserProfile.fromMap(doc.id, data);
  }

  // Build a profile from a map of Firestore fields.
  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    final specs = WorkerSpecialties.fromFirestore(
      data['specializations'],
      data['specialization'] as String?,
    );
    return UserProfile(
      uid: (data['uid'] as String?) ?? uid,
      name: (data['name'] as String?) ?? (data['fullName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      role: data['role'] as String?,
      employeeId: data['employeeId'] as String?,
      approvalStatus: data['approvalStatus'] as String?,
      accountStatus: data['accountStatus'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      specialization: specs.isNotEmpty
          ? specs.join(', ')
          : data['specialization'] as String?,
      specializations: specs,
      district: data['district'] as String?,
      municipality: data['municipality'] as String?,
      department: data['department'] as String?,
      citizenshipNumber: data['citizenshipNumber'] as String?,
      gender: data['gender'] as String?,
      username: data['username'] as String?,
      mustChangePassword: data['mustChangePassword'] == true,
      roles: ((data['roles'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

// One civic issue in the "reports" collection.
class ReportIssue {
  final String id;
  final String uid;
  final String title;
  final String description;
  final String category;
  final String status;
  final String? assignedWorkerId;
  final String? assignedWorkerName;
  final List<String> assignedWorkerIds;
  final List<String> assignedWorkerNames;
  final String? imageUrl;
  final String? videoUrl;
  final String? proofImageUrl;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? municipality;
  final String? district;
  final String? citizenVisibility;
  final bool isAnonymous;
  final bool publishedToFeed;
  final bool budgetSharedWithPublic;
  final bool publishedBudgetToFeed;
  final bool completionSharedWithPublic;
  final bool workerCompletionSubmitted;
  final bool hasCompletionPhotos;
  final bool publishedAfterToFeed;
  final String? feedPostId;
  final String? workerVerification;
  final String? workerVerificationReason;
  final List<String> workerEvidenceImages;
  final List<String> workerEvidenceVideos;
  final List<Map<String, dynamic>> inspectionItems;
  final List<String> inspectedByIds;
  final List<String> completionImages;
  final double itemsSubtotal;
  final double workerExpectedPayment;
  final int expectedWorkDays;
  final String? budgetStatus;
  final double? approvedBudgetAmount;
  final String? trackingCode;
  final String? citizenName;
  final DateTime? createdAt;
  final DateTime? locationTimestamp;

  const ReportIssue({
    required this.id,
    required this.uid,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.assignedWorkerId,
    this.assignedWorkerName,
    this.assignedWorkerIds = const [],
    this.assignedWorkerNames = const [],
    this.imageUrl,
    this.videoUrl,
    this.proofImageUrl,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.latitude,
    this.longitude,
    this.address,
    this.municipality,
    this.district,
    this.citizenVisibility,
    this.isAnonymous = false,
    this.publishedToFeed = false,
    this.budgetSharedWithPublic = false,
    this.publishedBudgetToFeed = false,
    this.completionSharedWithPublic = false,
    this.workerCompletionSubmitted = false,
    this.hasCompletionPhotos = false,
    this.publishedAfterToFeed = false,
    this.feedPostId,
    this.workerVerification,
    this.workerVerificationReason,
    this.workerEvidenceImages = const [],
    this.workerEvidenceVideos = const [],
    this.inspectionItems = const [],
    this.inspectedByIds = const [],
    this.completionImages = const [],
    this.itemsSubtotal = 0,
    this.workerExpectedPayment = 0,
    this.expectedWorkDays = 0,
    this.budgetStatus,
    this.approvedBudgetAmount,
    this.trackingCode,
    this.citizenName,
    this.createdAt,
    this.locationTimestamp,
  });

  bool get hasLocation => latitude != null && longitude != null;

  String? get playableVideoUrl {
    final primary = (videoUrl ?? '').trim();
    if (primary.isNotEmpty) return primary;
    for (final item in videoUrls) {
      if (item.trim().isNotEmpty) return item.trim();
    }
    return null;
  }

  bool get hasPlayableVideo => playableVideoUrl != null;

  // Money used for worker salary (15% of this) after admin approval.
  double get taskBudget {
    if (approvedBudgetAmount != null && approvedBudgetAmount! > 0) {
      return approvedBudgetAmount!;
    }
    if (itemsSubtotal > 0) return itemsSubtotal;
    var total = 0.0;
    for (final item in inspectionItems) {
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
      final unit = (item['unitCost'] as num?)?.toDouble() ?? 0;
      total += qty * unit;
    }
    return total;
  }

  // Worker uids on this report (list field, or the older single id).
  List<String> get crewIds {
    if (assignedWorkerIds.isNotEmpty) return assignedWorkerIds;
    final id = assignedWorkerId;
    if (id == null || id.isEmpty) return const [];
    return [id];
  }

  List<String> get crewNames {
    if (assignedWorkerNames.isNotEmpty) return assignedWorkerNames;
    final name = assignedWorkerName;
    if (name == null || name.isEmpty) return const [];
    return [name];
  }

  String get crewLabel => crewNames.join(', ');

  bool isAssignedTo(String uid) => crewIds.contains(uid);

  List<String> get inspectorIds {
    if (inspectedByIds.isNotEmpty) return inspectedByIds;
    return crewIds;
  }

  // Worker finished photos, but official has not sent them to the public yet.
  bool get awaitingOfficialCompletion {
    if (completionSharedWithPublic) return false;
    if (status == ReportStatus.completed ||
        status == ReportStatus.publicFeed) {
      return false;
    }
    if (status == ReportStatus.workCompleted ||
        status == ReportStatus.officialFinalReview) {
      return true;
    }
    if (workerCompletionSubmitted) return true;
    if (hasCompletionPhotos) return true;
    if (completionImages.isNotEmpty) return true;
    final proof = proofImageUrl;
    return proof != null && proof.isNotEmpty;
  }

  // Official already sent the funded budget to the worker and public.
  bool get isFundedBudgetSent {
    if (budgetSharedWithPublic) return true;
    return status == ReportStatus.taskAssigned ||
        status == ReportStatus.workInProgress ||
        status == ReportStatus.workCompleted ||
        status == ReportStatus.officialFinalReview ||
        status == ReportStatus.completed ||
        status == ReportStatus.publicFeed;
  }

  bool get canPublicPostBudget =>
      budgetSharedWithPublic ||
      status == ReportStatus.taskAssigned ||
      status == ReportStatus.workInProgress ||
      status == ReportStatus.workCompleted ||
      status == ReportStatus.completed ||
      status == ReportStatus.publicFeed;

  bool get isPublicCompleted =>
      status == ReportStatus.completed || status == ReportStatus.publicFeed;

  bool get isPublicClosed =>
      status == ReportStatus.officialDeclined ||
      status == ReportStatus.verifiedFake ||
      status == ReportStatus.duplicate ||
      status == ReportStatus.budgetRejected;

  String get publicWorkState {
    if (isPublicCompleted) return 'Completed';
    if (isPublicClosed) return 'Closed';
    return 'In progress';
  }

  bool get canPublicPostAfter =>
      completionSharedWithPublic ||
      status == ReportStatus.completed ||
      status == ReportStatus.publicFeed;

  bool get hasPostedBudget => publishedToFeed || publishedBudgetToFeed;

  bool get hasPostedAfter => publishedAfterToFeed;

  bool get isFeedActionPosted {
    if (canPublicPostAfter) return hasPostedAfter;
    if (canPublicPostBudget) return hasPostedBudget;
    return true;
  }

  String get feedActionLabel {
    if (isFeedActionPosted) return 'Posted';
    if (canPublicPostAfter) return 'Post before & after';
    return 'Post to my feed';
  }

  // Hide the reporter name from officials when the report is anonymous.
  bool hidesReporterFrom(UserProfile viewer) {
    if (!isAnonymous) return false;
    if (viewer.hasRole(UserRole.admin)) return false;
    if (viewer.uid == uid) return false;
    return true;
  }

  // Named reports first, then anonymous, then newest.
  static int compareOfficialPriority(ReportIssue a, ReportIssue b) {
    final byAnonymous = (a.isAnonymous ? 1 : 0).compareTo(
      b.isAnonymous ? 1 : 0,
    );
    if (byAnonymous != 0) return byAnonymous;
    return (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
  }

  // Tracking code shown to the public, e.g. HF-XXXXXX.
  String get publicId {
    if (trackingCode != null && trackingCode!.trim().isNotEmpty) {
      return trackingCode!;
    }
    final raw = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final code = raw.length >= 6
        ? raw.substring(0, 6).toUpperCase()
        : raw.toUpperCase();
    return 'HF-$code';
  }

  static String normalizeStatus(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'work_complete':
      case 'worker_completed':
      case 'task_completed':
      case 'completion_submitted':
        return ReportStatus.workCompleted;
      default:
        return raw;
    }
  }

  // Map a Firestore report document into this class.
  factory ReportIssue.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return ReportIssue(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      category: (data['category'] as String?) ?? 'General',
      status: ReportIssue.normalizeStatus(
        (data['status'] as String?) ?? 'submitted',
      ),
      assignedWorkerId: data['assignedWorkerId'] as String?,
      assignedWorkerName: data['assignedWorkerName'] as String?,
      assignedWorkerIds: ((data['assignedWorkerIds'] as List?) ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
      assignedWorkerNames: ((data['assignedWorkerNames'] as List?) ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
      imageUrl: data['imageUrl'] as String?,
      videoUrl: data['videoUrl'] as String?,
      proofImageUrl: data['proofImageUrl'] as String?,
      imageUrls: ((data['imageUrls'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      videoUrls: ((data['videoUrls'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      address: data['address'] as String?,
      municipality: data['municipality'] as String?,
      district: data['district'] as String?,
      citizenVisibility: data['citizenVisibility'] as String?,
      isAnonymous: data['isAnonymous'] == true,
      publishedToFeed: data['publishedToFeed'] == true,
      budgetSharedWithPublic: data['budgetSharedWithPublic'] == true,
      publishedBudgetToFeed: data['publishedBudgetToFeed'] == true,
      completionSharedWithPublic: data['completionSharedWithPublic'] == true,
      workerCompletionSubmitted: data['workerCompletionSubmitted'] == true,
      hasCompletionPhotos: data['hasCompletionPhotos'] == true ||
          ((data['completionImages'] as List?) ?? const []).isNotEmpty,
      publishedAfterToFeed: data['publishedAfterToFeed'] == true,
      feedPostId: data['feedPostId'] as String?,
      workerVerification: data['workerVerification'] as String?,
      workerVerificationReason: data['workerVerificationReason'] as String?,
      workerEvidenceImages:
          ((data['workerEvidenceImages'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
      workerEvidenceVideos:
          ((data['workerEvidenceVideos'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
      inspectionItems: ((data['inspectionItems'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      inspectedByIds: ((data['inspectedByIds'] as List?) ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
      completionImages: ((data['completionImages'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      itemsSubtotal: (data['itemsSubtotal'] as num?)?.toDouble() ?? 0,
      workerExpectedPayment:
          (data['workerExpectedPayment'] as num?)?.toDouble() ?? 0,
      expectedWorkDays: (data['expectedWorkDays'] as num?)?.toInt() ?? 0,
      budgetStatus: data['budgetStatus'] as String?,
      approvedBudgetAmount: (data['approvedBudgetAmount'] as num?)?.toDouble(),
      trackingCode: data['trackingCode'] as String?,
      citizenName: data['citizenName'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      locationTimestamp: data['locationTimestamp'] is Timestamp
          ? (data['locationTimestamp'] as Timestamp).toDate()
          : null,
    );
  }
}

// Private identity for anonymous reports. Only admin should read this.
class ReporterIdentity {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? citizenshipNumber;

  const ReporterIdentity({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.citizenshipNumber,
  });

  factory ReporterIdentity.fromMap(Map<String, dynamic> data) {
    return ReporterIdentity(
      uid: (data['uid'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      citizenshipNumber: data['citizenshipNumber'] as String?,
    );
  }
}

// Official job application waiting for admin approval.
class AccessRequest {
  final String id;
  final String uid;
  final String name;
  final String email;
  final String employeeId;
  final String status;
  final String? phone;
  final String? profileImageUrl;
  final String? department;
  final String? municipality;
  final String? temporaryPassword;
  final DateTime? createdAt;

  const AccessRequest({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.employeeId,
    required this.status,
    this.phone,
    this.profileImageUrl,
    this.department,
    this.municipality,
    this.temporaryPassword,
    this.createdAt,
  });

  factory AccessRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return AccessRequest(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      employeeId: (data['employeeId'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'pending',
      phone: data['phone'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      department: data['department'] as String?,
      municipality: data['municipality'] as String?,
      temporaryPassword: data['temporaryPassword'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

// Worker job application waiting for official approval.
class WorkerApplication {
  final String id;
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String status;
  final String? specialization;
  final List<String> specializations;
  final String? district;
  final String? municipality;
  final String? experienceYears;
  final String? citizenshipNumber;
  final String? gender;
  final String? dateOfBirth;
  final String? profileImageUrl;
  final String? citizenshipFrontUrl;
  final String? citizenshipBackUrl;
  final String? temporaryPassword;
  final DateTime? createdAt;

  const WorkerApplication({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    this.specialization,
    this.specializations = const [],
    this.district,
    this.municipality,
    this.experienceYears,
    this.citizenshipNumber,
    this.gender,
    this.dateOfBirth,
    this.profileImageUrl,
    this.citizenshipFrontUrl,
    this.citizenshipBackUrl,
    this.temporaryPassword,
    this.createdAt,
  });

  String get displayName {
    final value = name.trim();
    return value.isEmpty ? 'Worker' : value;
  }

  String get specialtyLabel {
    if (specializations.isNotEmpty) return specializations.join(', ');
    return (specialization ?? '').trim();
  }

  factory WorkerApplication.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    final specs = WorkerSpecialties.fromFirestore(
      data['specializations'],
      data['specialization'] as String?,
    );
    return WorkerApplication(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'pending',
      specialization: specs.isNotEmpty
          ? specs.join(', ')
          : data['specialization'] as String?,
      specializations: specs,
      district: data['district'] as String?,
      municipality: data['municipality'] as String?,
      experienceYears: data['experienceYears']?.toString(),
      citizenshipNumber: data['citizenshipNumber'] as String?,
      gender: data['gender'] as String?,
      dateOfBirth: data['dateOfBirth'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      citizenshipFrontUrl: data['citizenshipFrontUrl'] as String?,
      citizenshipBackUrl: data['citizenshipBackUrl'] as String?,
      temporaryPassword: data['temporaryPassword'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

// One document in the "notifications" collection.
class AppNotification {
  final String id;
  final String recipientUid;
  final String title;
  final String body;
  final String type;
  final String? relatedId;
  final String? senderUid;
  final String? senderName;
  final String? senderRole;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.recipientUid,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.senderUid,
    this.senderName,
    this.senderRole,
    this.read = false,
    this.createdAt,
  });

  // Public and worker inboxes only show certain alert types.
  bool visibleFor(UserProfile? profile) {
    if (profile == null) return true;
    if (profile.hasRole(UserRole.public)) {
      return AlertType.publicVisible.contains(type);
    }
    if (profile.hasRole(UserRole.worker) &&
        !profile.hasRole(UserRole.official) &&
        !profile.hasRole(UserRole.admin)) {
      return AlertType.workerVisible.contains(type) ||
          type == AlertType.message;
    }
    return true;
  }

  static int unreadCount(
    Iterable<AppNotification> items, {
    Set<String>? types,
    Set<String>? excludeTypes,
    UserProfile? profile,
  }) {
    final seenBudget = <String>{};
    var count = 0;
    for (final item in items) {
      if (item.read) continue;
      if (profile != null && !item.visibleFor(profile)) continue;
      if (types != null && !types.contains(item.type)) continue;
      if (excludeTypes != null && excludeTypes.contains(item.type)) continue;
      if (item.type == AlertType.budget &&
          item.relatedId != null &&
          item.relatedId!.isNotEmpty) {
        if (seenBudget.contains(item.relatedId)) continue;
        seenBudget.add(item.relatedId!);
      }
      count++;
    }
    return count;
  }

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return AppNotification(
      id: doc.id,
      recipientUid: (data['recipientUid'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'general',
      relatedId: data['relatedId'] as String?,
      senderUid: data['senderUid'] as String?,
      senderName: data['senderName'] as String?,
      senderRole: data['senderRole'] as String?,
      read: data['read'] == true,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

// One post on the public community feed.
class FeedPost {
  final String id;
  final String uid;
  final String authorName;
  final String text;
  final String? imageUrl;
  final String? afterImageUrl;
  final String? videoUrl;
  final String? reportId;
  final String? trackingCode;
  final double? approvedBudgetAmount;
  final List<String> likedBy;
  final int commentCount;
  final DateTime? createdAt;

  const FeedPost({
    required this.id,
    required this.uid,
    required this.authorName,
    required this.text,
    this.imageUrl,
    this.afterImageUrl,
    this.videoUrl,
    this.reportId,
    this.trackingCode,
    this.approvedBudgetAmount,
    this.likedBy = const [],
    this.commentCount = 0,
    this.createdAt,
  });

  int get likeCount => likedBy.length;

  bool likedByUser(String uid) => likedBy.contains(uid);

  factory FeedPost.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    final storedText = (data['text'] as String?)?.trim() ?? '';
    final caption = (data['caption'] as String?) ?? '';
    var postText = storedText;
    if (postText.isEmpty) {
      postText = caption;
    }
    return FeedPost(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? '',
      text: postText,
      imageUrl:
          data['imageUrl'] as String? ?? data['beforeImageUrl'] as String?,
      afterImageUrl: data['afterImageUrl'] as String?,
      videoUrl: data['videoUrl'] as String?,
      reportId: data['reportId'] as String?,
      trackingCode: data['trackingCode'] as String?,
      approvedBudgetAmount: (data['approvedBudgetAmount'] as num?)?.toDouble(),
      likedBy: ((data['likedBy'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

// A comment on a feed post.
class FeedComment {
  final String id;
  final String uid;
  final String authorName;
  final String text;
  final DateTime? createdAt;

  const FeedComment({
    required this.id,
    required this.uid,
    required this.authorName,
    required this.text,
    this.createdAt,
  });

  factory FeedComment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return FeedComment(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? 'Public',
      text: (data['text'] as String?) ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

// Budget request for a report (materials + worker pay).
class BudgetRequest {
  final String id;
  final String reportId;
  final String workerId;
  final String? officialId;
  final String status;
  final double estimatedTotal;
  final double itemsSubtotal;
  final double workerExpectedPayment;
  final int expectedWorkDays;
  final String remarks;
  final List<Map<String, dynamic>> items;
  final DateTime? createdAt;

  const BudgetRequest({
    required this.id,
    required this.reportId,
    required this.workerId,
    required this.status,
    required this.estimatedTotal,
    required this.remarks,
    this.itemsSubtotal = 0,
    this.workerExpectedPayment = 0,
    this.expectedWorkDays = 0,
    this.officialId,
    this.items = const [],
    this.createdAt,
  });

  factory BudgetRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return BudgetRequest(
      id: doc.id,
      reportId: (data['reportId'] as String?) ?? '',
      workerId: (data['workerId'] as String?) ?? '',
      officialId: data['officialId'] as String?,
      status: (data['status'] as String?) ?? 'draft',
      estimatedTotal: (data['estimatedTotal'] as num?)?.toDouble() ?? 0,
      itemsSubtotal: (data['itemsSubtotal'] as num?)?.toDouble() ?? 0,
      workerExpectedPayment:
          (data['workerExpectedPayment'] as num?)?.toDouble() ?? 0,
      expectedWorkDays: (data['expectedWorkDays'] as num?)?.toInt() ?? 0,
      remarks: (data['remarks'] as String?) ?? '',
      items: ((data['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

// One material line on a budget (legacy helper).
class BudgetItem {
  final String id;
  final String title;
  final String category;
  final double amount;
  final String notes;
  final String createdBy;
  final String? reportId;
  final String? status;
  final DateTime? createdAt;

  const BudgetItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.notes,
    required this.createdBy,
    this.reportId,
    this.status,
    this.createdAt,
  });

  factory BudgetItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return BudgetItem(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      category: (data['category'] as String?) ?? 'General',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      notes: (data['notes'] as String?) ?? '',
      createdBy: (data['createdBy'] as String?) ?? '',
      reportId: data['reportId'] as String?,
      status: data['status'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}
