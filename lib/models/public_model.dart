import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hamro_fix/core/constants/app_constants.dart';

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
    return UserRole.normalize(value) == normalizedRole;
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

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserProfile.fromMap(doc.id, data);
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
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
      specialization: data['specialization'] as String?,
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
  final bool publishedAfterToFeed;
  final String? feedPostId;
  final String? workerVerification;
  final String? workerVerificationReason;
  final List<String> workerEvidenceImages;
  final List<Map<String, dynamic>> inspectionItems;
  final List<String> inspectedByIds;
  final List<String> completionImages;
  final double itemsSubtotal;
  final double workerExpectedPayment;
  final int expectedWorkDays;
  final double? approvedBudgetAmount;
  final String? trackingCode;
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
    this.publishedAfterToFeed = false,
    this.feedPostId,
    this.workerVerification,
    this.workerVerificationReason,
    this.workerEvidenceImages = const [],
    this.inspectionItems = const [],
    this.inspectedByIds = const [],
    this.completionImages = const [],
    this.itemsSubtotal = 0,
    this.workerExpectedPayment = 0,
    this.expectedWorkDays = 0,
    this.approvedBudgetAmount,
    this.trackingCode,
    this.createdAt,
    this.locationTimestamp,
  });

  bool get hasLocation => latitude != null && longitude != null;

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

  bool get canPublicPostBudget =>
      budgetSharedWithPublic ||
      status == ReportStatus.taskAssigned ||
      status == ReportStatus.workInProgress ||
      status == ReportStatus.workCompleted ||
      status == ReportStatus.completed ||
      status == ReportStatus.publicFeed;

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
      status: (data['status'] as String?) ?? 'submitted',
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
      publishedAfterToFeed: data['publishedAfterToFeed'] == true,
      feedPostId: data['feedPostId'] as String?,
      workerVerification: data['workerVerification'] as String?,
      workerVerificationReason: data['workerVerificationReason'] as String?,
      workerEvidenceImages:
          ((data['workerEvidenceImages'] as List?) ?? const [])
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
      approvedBudgetAmount: (data['approvedBudgetAmount'] as num?)?.toDouble(),
      trackingCode: data['trackingCode'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      locationTimestamp: data['locationTimestamp'] is Timestamp
          ? (data['locationTimestamp'] as Timestamp).toDate()
          : null,
    );
  }
}

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

class WorkerApplication {
  final String id;
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String status;
  final String? specialization;
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

  factory WorkerApplication.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return WorkerApplication(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'pending',
      specialization: data['specialization'] as String?,
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

class AppNotification {
  final String id;
  final String recipientUid;
  final String title;
  final String body;
  final String type;
  final String? relatedId;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.recipientUid,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.read = false,
    this.createdAt,
  });

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
      read: data['read'] == true,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

class FeedPost {
  final String id;
  final String uid;
  final String authorName;
  final String text;
  final String? imageUrl;
  final String? afterImageUrl;
  final String? reportId;
  final String? trackingCode;
  final double? approvedBudgetAmount;
  final List<String> likedBy;
  final DateTime? createdAt;

  const FeedPost({
    required this.id,
    required this.uid,
    required this.authorName,
    required this.text,
    this.imageUrl,
    this.afterImageUrl,
    this.reportId,
    this.trackingCode,
    this.approvedBudgetAmount,
    this.likedBy = const [],
    this.createdAt,
  });

  int get likeCount => likedBy.length;

  bool likedByUser(String uid) => likedBy.contains(uid);

  factory FeedPost.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return FeedPost(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      imageUrl:
          data['imageUrl'] as String? ?? data['beforeImageUrl'] as String?,
      afterImageUrl: data['afterImageUrl'] as String?,
      reportId: data['reportId'] as String?,
      trackingCode: data['trackingCode'] as String?,
      approvedBudgetAmount: (data['approvedBudgetAmount'] as num?)?.toDouble(),
      likedBy: ((data['likedBy'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

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
